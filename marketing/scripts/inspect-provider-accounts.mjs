import { BufferPublisher } from "../src/providers/buffer.mjs";

const falKey = process.env.FAL_KEY;
const bufferKey = process.env.BUFFER_API_KEY;
if (!falKey || !bufferKey) throw new Error("FAL_KEY and BUFFER_API_KEY are required");

const publisher = new BufferPublisher({
  apiKey: bufferKey,
  baseUrl: process.env.BUFFER_BASE_URL ?? "https://api.buffer.com",
  shareMode: process.env.BUFFER_SHARE_MODE ?? "addToQueue",
  youtubePrivacy: process.env.BUFFER_YOUTUBE_PRIVACY ?? "private",
});
const channels = await publisher.listChannels();
console.log(JSON.stringify({
  fal: {
    configured: Boolean(falKey),
    note: "Model access is verified by the generation test, not the admin-scoped billing endpoint.",
  },
  buffer: {
    authenticated: true,
    channels: channels.map(({ id, name, displayName, service, isDisconnected, isLocked, isQueuePaused }) => ({
      id,
      name,
      displayName,
      service,
      isDisconnected,
      isLocked,
      isQueuePaused,
    })),
  },
}, null, 2));
