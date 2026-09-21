import OpenAI, { toFile } from "openai";

export class OpenAIVoiceProvider {
  constructor({ apiKey, model, voice, transcribeModel = "gpt-4o-mini-transcribe", client } = {}) {
    this.apiKey = apiKey;
    this.model = model;
    this.voice = voice;
    this.transcribeModel = transcribeModel;
    this.client = client ?? (apiKey ? new OpenAI({ apiKey }) : null);
  }

  async generate({ text }) {
    if (!this.client) throw new Error("OpenAI voice generation is not configured");
    if (!text?.trim()) throw new Error("Voiceover script is empty");
    const response = await this.client.audio.speech.create({
      model: this.model,
      voice: this.voice,
      input: text.trim(),
      instructions: "Confident, warm fitness-product narrator. Conversational pace, crisp diction, energetic without sounding like an advertisement.",
      response_format: "mp3",
      speed: 1.05,
    });
    return {
      buffer: Buffer.from(await response.arrayBuffer()),
      requestId: response._request_id ?? null,
    };
  }

  async transcribe({ buffer, filename = "creator-dialogue.mp3" }) {
    if (!this.client) throw new Error("OpenAI transcription is not configured");
    if (!buffer?.length) throw new Error("Audio transcription input is empty");
    const response = await this.client.audio.transcriptions.create({
      model: this.transcribeModel,
      file: await toFile(buffer, filename, { type: "audio/mpeg" }),
      response_format: "json",
    });
    return {
      text: String(response.text ?? "").trim(),
      requestId: response._request_id ?? null,
    };
  }
}
