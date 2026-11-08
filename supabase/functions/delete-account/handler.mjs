const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json", "Cache-Control": "no-store" },
  });
}

function checked(result, operation) {
  if (result.error) throw new Error(operation);
  return result.data;
}

async function allRows(admin, table, columns, key, value, filter = "eq") {
  const rows = [];
  for (let offset = 0; ; offset += 500) {
    const page = checked(await admin.from(table).select(columns)[filter](key, value)
      .order("id").range(offset, offset + 499), `read ${table}`) ?? [];
    rows.push(...page);
    if (page.length < 500) return rows;
  }
}

async function storageFiles(storage, bucket, userId) {
  const files = [];
  const directories = [userId];
  while (directories.length) {
    const directory = directories.pop();
    for (let offset = 0; ; offset += 500) {
      const page = checked(await storage.from(bucket).list(directory, {
        limit: 500, offset, sortBy: { column: "name", order: "asc" },
      }), "list user storage") ?? [];
      for (const item of page) {
        if (!item.name || item.name.includes("/") || [".", ".."].includes(item.name)) {
          throw new Error("invalid storage name");
        }
        const name = `${directory}/${item.name}`;
        if (item.id == null) directories.push(name);
        else files.push(name);
      }
      if (page.length < 500) break;
    }
  }
  return files;
}

export function createDeleteAccountHandler({
  userClient, adminClient, bunnyApiKey, bunnyLibraryId,
  fetchImpl = fetch, logError = (stage) => console.error("Account deletion failed", { stage }),
}) {
  return async (request) => {
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
    if (request.method !== "POST") return json(405, { error: "Use POST to request account deletion." });
    const authorization = request.headers.get("authorization") ?? "";
    if (!/^Bearer\s+\S+$/i.test(authorization)) return json(401, { error: "Sign in to delete your account." });

    let stage = "authentication";
    try {
      const authenticated = await userClient(authorization).auth.getUser();
      if (authenticated.error || !authenticated.data?.user) {
        return json(401, { error: "Your session is invalid. Sign in again." });
      }
      // The deletion target comes only from the validated session, never the body.
      const userId = authenticated.data.user.id;
      const admin = adminClient();
      stage = "inventory";
      const assets = await allRows(admin, "media_assets", "id,bunny_video_guid", "owner_id", userId);
      const videos = [...new Set(assets.map((asset) => asset.bunny_video_guid).filter(Boolean))];
      if (videos.length && (!bunnyApiKey || !/^\d+$/.test(String(bunnyLibraryId)))) {
        return json(503, { error: "Media deletion is temporarily unavailable. Please retry or contact official@gymfeed.io." });
      }
      if (videos.some((id) => !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id))) {
        throw new Error("invalid video identifier");
      }
      const buckets = checked(await admin.storage.listBuckets(), "list buckets") ?? [];
      const inventory = [];
      for (const bucket of buckets) {
        inventory.push({ bucket: bucket.id, files: await storageFiles(admin.storage, bucket.id, userId) });
      }

      // Keep the auth user and database manifest until external cleanup succeeds,
      // so a failed request can safely retry already-removed media.
      stage = "video_cleanup";
      for (const video of videos) {
        const response = await fetchImpl(`https://video.bunnycdn.com/library/${bunnyLibraryId}/videos/${video}`, {
          method: "DELETE", headers: { AccessKey: bunnyApiKey }, signal: AbortSignal.timeout(15000),
        });
        if (!response.ok && response.status !== 404) throw new Error("video provider deletion failed");
      }
      stage = "storage_cleanup";
      for (const { bucket, files } of inventory) {
        for (let index = 0; index < files.length; index += 100) {
          checked(await admin.storage.from(bucket).remove(files.slice(index, index + 100)), "remove user storage");
        }
      }

      stage = "associated_data";
      checked(await admin.from("chats").update({ last_message: "", last_message_at: null, last_message_sent_by: null })
        .eq("last_message_sent_by", userId), "clear conversation previews");
      checked(await admin.from("push_queue").delete().eq("sender_id", userId), "delete authored push records");
      const queued = await allRows(admin, "push_queue", "id,recipient_ids", "recipient_ids", [userId], "contains");
      for (const item of queued) {
        const recipients = item.recipient_ids.filter((id) => id !== userId);
        checked(await (recipients.length
          ? admin.from("push_queue").update({ recipient_ids: recipients }).eq("id", item.id)
          : admin.from("push_queue").delete().eq("id", item.id)), "remove push recipient");
      }
      checked(await admin.from("marketing_events").delete().eq("user_id", userId), "delete attributed activity");
      checked(await admin.from("reports").delete().eq("reporter_id", userId), "delete authored reports");

      stage = "session_revocation";
      const revoked = await admin.auth.admin.signOut(authorization.replace(/^Bearer\s+/i, ""), "global");
      if (revoked.error && ![401, 403, 404].includes(revoked.error.status)) throw new Error("session revocation failed");
      stage = "account_deletion";
      checked(await admin.auth.admin.deleteUser(userId, false), "delete auth user and cascading data");
      return json(200, { deleted: true });
    } catch (_) {
      logError(stage);
      return json(500, { error: "Account deletion could not be completed. Please retry or contact official@gymfeed.io.", stage });
    }
  };
}
