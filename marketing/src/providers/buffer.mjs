function mutationError(payload) {
  if (payload?.__typename && payload.__typename !== "PostActionSuccess") {
    return payload.message ?? `Buffer returned ${payload.__typename}`;
  }
  return null;
}

function metricsObject(metrics = []) {
  return Object.fromEntries(metrics.map((metric) => [metric.type, metric.value]));
}

function postPerformance(post) {
  const metrics = metricsObject(post.metrics);
  const views = metrics.views ?? metrics.reach ?? 0;
  const meaningfulActions = (metrics.shares ?? 0) + (metrics.saves ?? 0) + (metrics.comments ?? 0);
  const actionRate = views > 0 ? meaningfulActions / views : 0;
  const reactionRate = views > 0 ? (metrics.reactions ?? metrics.likes ?? 0) / views : 0;
  const durationSeconds = (post.assets ?? []).find((asset) => asset.video?.durationMs)?.video?.durationMs / 1000 || 0;
  const watchRatio = durationSeconds > 0 && Number.isFinite(metrics.averageTimeWatched)
    ? metrics.averageTimeWatched / durationSeconds
    : 0;
  const performanceScore = Math.round((
    Math.log10(views + 1) * 20
    + Math.min(actionRate, 0.25) * 240
    + Math.min(reactionRate, 0.5) * 80
    + Math.min(watchRatio, 1.5) * 30
  ) * 100) / 100;
  const asset = post.assets?.[0] ?? null;
  return {
    id: post.id,
    platform: post.channelService,
    sent_at: post.sentAt,
    caption: post.text?.slice(0, 1200) ?? "",
    external_url: post.externalLink ?? null,
    thumbnail_url: asset?.thumbnail || null,
    asset_source_url: asset?.source || null,
    duration_seconds: durationSeconds || null,
    metrics,
    metric_units: Object.fromEntries((post.metrics ?? []).map((metric) => [metric.type, metric.unit])),
    metrics_updated_at: post.metricsUpdatedAt ?? null,
    meaningful_action_rate: Number(actionRate.toFixed(6)),
    watch_ratio: Number(watchRatio.toFixed(6)),
    performance_score: performanceScore,
  };
}

function platformSummary(posts) {
  if (!posts.length) return { posts_analyzed: 0, totals: {}, top_posts: [] };
  const normalized = posts.map(postPerformance);
  const totals = {};
  for (const post of normalized) {
    for (const [name, value] of Object.entries(post.metrics)) totals[name] = (totals[name] ?? 0) + value;
  }
  const byPerformance = [...normalized].sort((left, right) => right.performance_score - left.performance_score);
  const byViews = [...normalized].sort((left, right) => (right.metrics.views ?? 0) - (left.metrics.views ?? 0));
  const selected = new Map();
  for (const post of [...byPerformance.slice(0, 5), ...byViews.slice(0, 5)]) selected.set(post.id, post);
  return {
    posts_analyzed: normalized.length,
    totals,
    top_posts: [...selected.values()]
      .sort((left, right) => right.performance_score - left.performance_score)
      .slice(0, 8),
  };
}

export class BufferPublisher {
  constructor({ apiKey, baseUrl, shareMode, youtubePrivacy, fetchFn = fetch }) {
    this.apiKey = apiKey;
    this.baseUrl = baseUrl.replace(/\/$/, "");
    this.shareMode = shareMode;
    this.youtubePrivacy = youtubePrivacy;
    this.fetchFn = fetchFn;
  }

  async graphql(query, variables = {}) {
    if (!this.apiKey) throw new Error("Buffer is not configured");
    const response = await this.fetchFn(this.baseUrl, {
      method: "POST",
      headers: {
        authorization: `Bearer ${this.apiKey}`,
        "content-type": "application/json",
        accept: "application/json",
      },
      body: JSON.stringify({ query, variables }),
    });
    const text = await response.text();
    let body;
    try {
      body = text ? JSON.parse(text) : {};
    } catch (_) {
      body = { raw: text };
    }
    if (!response.ok) throw new Error(`Buffer request failed (${response.status}): ${body?.message ?? text}`);
    if (body.errors?.length) throw new Error(`Buffer GraphQL error: ${body.errors.map((error) => error.message).join("; ")}`);
    return body.data;
  }

  async listChannels() {
    const organizations = await this.graphql(`
      query GetOrganizations {
        account { organizations { id name } }
      }
    `);
    const result = [];
    for (const organization of organizations.account?.organizations ?? []) {
      const data = await this.graphql(`
        query GetChannels($organizationId: OrganizationId!) {
          channels(input: { organizationId: $organizationId }) {
            id
            name
            displayName
            service
            isDisconnected
            isLocked
            isQueuePaused
          }
        }
      `, { organizationId: organization.id });
      for (const channel of data.channels ?? []) result.push({ ...channel, organizationId: organization.id });
    }
    return result;
  }

  async performanceSummary({ limit = 100 } = {}) {
    const channels = await this.listChannels();
    if (!channels.length) return { status: "ok", posts_analyzed: 0, platforms: {} };
    const organizationId = channels[0].organizationId;
    const data = await this.graphql(`
      query RecentSentPosts($input: PostsInput!, $first: Int!) {
        posts(input: $input, first: $first) {
          edges {
            node {
              id
              channelService
              status
              sentAt
              createdAt
              text
              externalLink
              metrics { type name value unit }
              metricsUpdatedAt
              assets {
                type
                source
                thumbnail
                ... on VideoAsset { video { durationMs width height } }
                ... on ImageAsset { image { width height } }
              }
            }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    `, {
      first: Math.max(1, Math.min(100, limit)),
      input: {
        organizationId,
        filter: {
          channelIds: channels.map((channel) => channel.id),
          status: ["sent"],
        },
        sort: [{ field: "createdAt", direction: "desc" }],
      },
    });
    const posts = (data.posts?.edges ?? []).map((edge) => edge.node);
    const platforms = {};
    for (const service of ["instagram", "tiktok", "youtube"]) {
      platforms[service] = platformSummary(posts.filter((post) => post.channelService === service));
    }
    return {
      status: "ok",
      source: "buffer_first_party",
      collected_at: new Date().toISOString(),
      posts_analyzed: posts.length,
      truncated: Boolean(data.posts?.pageInfo?.hasNextPage),
      platforms,
    };
  }

  metadata(platform, { isVideo, mediaCount, title }) {
    if (platform === "instagram") {
      return {
        instagram: {
          // Buffer represents multi-image feed carousels as a normal `post`;
          // the image asset count determines that Instagram publishes a carousel.
          type: isVideo ? "reel" : "post",
          shouldShareToFeed: true,
          isAiGenerated: true,
        },
      };
    }
    if (platform === "tiktok") return { tiktok: { isAiGenerated: true } };
    if (platform === "youtube") {
      return {
        youtube: {
          title: title?.slice(0, 100) || "GymFeed Short",
          categoryId: "17",
          privacy: this.youtubePrivacy,
          madeForKids: false,
          notifySubscribers: false,
          embeddable: true,
          isAiGenerated: true,
        },
      };
    }
    throw new Error(`Unsupported Buffer platform: ${platform}`);
  }

  async publish({ platform, accountId, text, mediaUrls, scheduledTime, title, isVideo = false }) {
    if (!mediaUrls?.length) throw new Error("Buffer publishing requires at least one media URL");
    const mode = scheduledTime ? "customScheduled" : this.shareMode;
    const input = {
      channelId: accountId,
      text,
      assets: mediaUrls.map((url) => isVideo
        ? { video: { url, metadata: { thumbnailOffset: 1000, title: title || undefined } } }
        : { image: { url } }),
      metadata: this.metadata(platform, { isVideo, mediaCount: mediaUrls.length, title }),
      mode,
      schedulingType: "automatic",
      needsApproval: false,
      saveToDraft: false,
      aiAssisted: true,
      source: "gymfeed-marketing",
    };
    if (scheduledTime) input.dueAt = scheduledTime;

    const data = await this.graphql(`
      mutation CreatePost($input: CreatePostInput!) {
        createPost(input: $input) {
          __typename
          ... on PostActionSuccess {
            post { id status dueAt externalLink sentAt error { message } }
          }
          ... on MutationError { message }
        }
      }
    `, { input });
    const error = mutationError(data.createPost);
    if (error) throw new Error(`Buffer publish failed: ${error}`);
    if (!data.createPost?.post?.id) throw new Error("Buffer returned no post ID");
    return data.createPost.post;
  }

  async getPost(postId) {
    const data = await this.graphql(`
      query GetPost($postId: PostId!) {
        post(input: { id: $postId }) {
          id
          status
          dueAt
          externalLink
          sentAt
          error { message }
          metrics { type name value unit }
          metricsUpdatedAt
        }
      }
    `, { postId });
    if (!data.post) throw new Error("Buffer returned no post");
    return data.post;
  }

  async deletePost(postId) {
    const data = await this.graphql(`
      mutation DeletePost($input: DeletePostInput!) {
        deletePost(input: $input) {
          __typename
          ... on DeletePostSuccess { id }
          ... on VoidMutationError { message }
        }
      }
    `, { input: { id: postId } });
    if (data.deletePost?.__typename !== "DeletePostSuccess") {
      throw new Error(`Buffer delete failed: ${data.deletePost?.message ?? "unknown error"}`);
    }
    return { id: data.deletePost.id, deleted: true };
  }
}
