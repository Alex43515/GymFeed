import assert from "node:assert/strict";
import test from "node:test";
import { createDeleteAccountHandler } from "./handler.mjs";

const videoId = "12345678-1234-1234-1234-123456789abc";

function fixture({ failure, video = false, bunnyStatus = 200, key = "test-key", authenticated = true } = {}) {
  const calls = [];
  const tables = {
    media_assets: video ? [{ id: "asset", owner_id: "owner-a", bunny_video_guid: videoId }] : [],
    chats: [{ id: "chat", last_message_sent_by: "owner-a", last_message: "private text" }],
    push_queue: [
      { id: "own", sender_id: "owner-a", recipient_ids: ["owner-b"] },
      { id: "other", sender_id: "owner-b", recipient_ids: ["owner-a", "owner-b"] },
    ],
    marketing_events: [{ id: "event", user_id: "owner-a" }],
    reports: [{ id: "report", reporter_id: "owner-a" }],
  };
  const objects = new Set(["images/owner-a/one.jpg", "images/owner-a/nested/two.jpg", "images/owner-b/keep.jpg"]);
  const admin = {
    from(table) {
      let operation, patch, start = 0, end = Infinity;
      const filters = [];
      const query = {
        select() { operation = "select"; return query; },
        update(value) { operation = "update"; patch = value; return query; },
        delete() { operation = "delete"; return query; },
        eq(key, value) { filters.push((row) => row[key] === value); return query; },
        contains(key, value) { filters.push((row) => value.every((v) => row[key].includes(v))); return query; },
        order() { return query; },
        range(a, b) { start = a; end = b; return query; },
        then(resolve, reject) {
          const task = async () => {
            calls.push(`${operation}:${table}`);
            if (failure === `${operation}:${table}`) return { error: { message: "forced failure" } };
            const matches = tables[table].filter((row) => filters.every((filter) => filter(row))).slice(start, end + 1);
            if (operation === "update") matches.forEach((row) => Object.assign(row, patch));
            if (operation === "delete") tables[table] = tables[table].filter((row) => !matches.includes(row));
            return { data: matches, error: null };
          };
          return task().then(resolve, reject);
        },
      };
      return query;
    },
    storage: {
      listBuckets: async () => ({ data: [{ id: "images" }] }),
      from(bucket) {
        return {
          async list(directory, { offset, limit }) {
            if (failure === "storage-list") return { error: { message: "offline" } };
            const prefix = `${bucket}/${directory}/`;
            const entries = new Map();
            for (const name of objects) {
              if (!name.startsWith(prefix)) continue;
              const relative = name.slice(prefix.length), first = relative.split("/")[0];
              entries.set(first, { name: first, id: relative.includes("/") ? null : first });
            }
            return { data: [...entries.values()].slice(offset, offset + limit) };
          },
          async remove(names) {
            calls.push("storage-remove");
            if (failure === "storage-remove") return { error: { message: "offline" } };
            names.forEach((name) => objects.delete(`${bucket}/${name}`));
            return { data: [] };
          },
        };
      },
    },
    auth: { admin: {
      signOut: async (_token, scope) => { calls.push(`revoke:${scope}`); return { error: null }; },
      deleteUser: async (id, soft) => {
        calls.push(`delete-user:${id}:${soft}`);
        return failure === "auth-delete" ? { error: { message: "cascade failed" } } : { data: { user: { id } } };
      },
    } },
  };
  const handler = createDeleteAccountHandler({
    userClient: () => ({ auth: { getUser: async () => ({ data: { user: authenticated ? { id: "owner-a" } : null }, error: null }) } }),
    adminClient: () => { calls.push("admin"); return admin; },
    bunnyApiKey: key, bunnyLibraryId: "123",
    fetchImpl: async (url) => { calls.push(`bunny:${url}`); return new Response(null, { status: bunnyStatus }); },
    logError: () => {},
  });
  return { handler, calls, tables, objects };
}

const request = (body = {}) => new Request("https://example.com/delete-account", {
  method: "POST", headers: { authorization: "Bearer user-token", "content-type": "application/json" }, body: JSON.stringify(body),
});

test("rejects unauthenticated calls and invalid sessions before privileged access", async () => {
  const f = fixture({ authenticated: false });
  assert.equal((await f.handler(new Request("https://example.com", { method: "POST" }))).status, 401);
  assert.equal((await f.handler(request())).status, 401);
  assert.deepEqual(f.calls, []);
});

test("only the validated caller is deleted; another user's files and push recipients remain", async () => {
  const f = fixture();
  const response = await f.handler(request({ userId: "owner-b" }));
  assert.deepEqual(await response.json(), { deleted: true });
  assert.equal(response.status, 200);
  assert.deepEqual([...f.objects], ["images/owner-b/keep.jpg"]);
  assert.deepEqual(f.tables.push_queue, [{ id: "other", sender_id: "owner-b", recipient_ids: ["owner-b"] }]);
  assert.equal(f.tables.chats[0].last_message, "");
  assert.equal(f.tables.chats[0].last_message_sent_by, null);
  assert.deepEqual(f.calls.slice(-2), ["revoke:global", "delete-user:owner-a:false"]);
});

for (const failure of ["storage-list", "storage-remove", "update:chats", "delete:marketing_events"]) {
  test(`a ${failure} failure never deletes the auth user or reports success`, async () => {
    const f = fixture({ failure });
    const response = await f.handler(request());
    assert.equal(response.status, 500);
    assert.equal((await response.json()).deleted, undefined);
    assert.equal(f.calls.some((call) => call.startsWith("delete-user:")), false);
  });
}

test("missing Bunny credentials fail before removing any media or database data", async () => {
  const f = fixture({ video: true, key: "" });
  assert.equal((await f.handler(request())).status, 503);
  assert.equal(f.objects.size, 3);
  assert.equal(f.calls.some((call) => call.startsWith("delete-user:")), false);
});

test("a Bunny provider failure retains the account for a safe retry", async () => {
  const f = fixture({ video: true, bunnyStatus: 503 });
  assert.equal((await f.handler(request())).status, 500);
  assert.equal(f.objects.size, 3);
  assert.equal(f.calls.some((call) => call.startsWith("delete-user:")), false);
});

test("an already-deleted Bunny video is safe to retry", async () => {
  const f = fixture({ video: true, bunnyStatus: 404 });
  assert.equal((await f.handler(request())).status, 200);
  assert.ok(f.calls.some((call) => call.includes(`/videos/${videoId}`)));
});

test("a failed auth delete cannot produce a successful response", async () => {
  const f = fixture({ failure: "auth-delete" });
  assert.equal((await f.handler(request())).status, 500);
});

test("preflight and read-only calls never perform deletion", async () => {
  const f = fixture();
  assert.equal((await f.handler(new Request("https://example.com", { method: "OPTIONS" }))).status, 204);
  assert.equal((await f.handler(new Request("https://example.com"))).status, 405);
  assert.deepEqual(f.calls, []);
});
