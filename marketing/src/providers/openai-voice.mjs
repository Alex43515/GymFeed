import OpenAI, { toFile } from "openai";

export class OpenAIVoiceProvider {
  constructor({ apiKey, model, voice, transcribeModel = "gpt-4o-mini-transcribe", client } = {}) {
    this.apiKey = apiKey;
    this.model = model;
    this.voice = voice;
    this.transcribeModel = transcribeModel;
    this.client = client ?? (apiKey ? new OpenAI({ apiKey }) : null);
  }

  async generate({ text, voice = this.voice, instructions = "Confident, warm fitness-product narrator. Conversational pace, crisp diction, energetic without sounding like an advertisement." }) {
    if (!this.client) throw new Error("OpenAI voice generation is not configured");
    if (!text?.trim()) throw new Error("Voiceover script is empty");
    const response = await this.client.audio.speech.create({
      model: this.model,
      voice,
      input: text.trim(),
      instructions,
      response_format: "mp3",
      speed: 1,
    });
    return {
      buffer: Buffer.from(await response.arrayBuffer()),
      requestId: response._request_id ?? null,
    };
  }

  async transcribe({ buffer, filename = "creator-dialogue.mp3", timestamps = false }) {
    if (!this.client) throw new Error("OpenAI transcription is not configured");
    if (!buffer?.length) throw new Error("Audio transcription input is empty");
    const response = await this.client.audio.transcriptions.create({
      model: timestamps ? "whisper-1" : this.transcribeModel,
      file: await toFile(buffer, filename, { type: "audio/mpeg" }),
      response_format: timestamps ? "verbose_json" : "json",
      ...(timestamps ? { timestamp_granularities: ["word", "segment"], language: "en" } : {}),
    });
    return {
      text: String(response.text ?? "").trim(),
      ...(response.words ? { words: response.words } : {}),
      ...(response.segments ? { segments: response.segments } : {}),
      requestId: response._request_id ?? null,
    };
  }
}
