import { GoogleGenAI } from "@google/genai";

export class GeminiImageProvider {
  constructor({ apiKey, model, imageSize }) {
    this.client = apiKey ? new GoogleGenAI({ apiKey }) : null;
    this.model = model;
    this.imageSize = imageSize;
  }

  async generateBackground(prompt) {
    if (!this.client) throw new Error("Gemini is not configured");
    const interaction = await this.client.interactions.create({
      model: this.model,
      input: `${prompt}\n\nCreate background/subject imagery only. Do not render words, labels, logos, captions, watermarks, or UI text. Leave clean negative space for a headline overlay.`,
      response_format: {
        type: "image",
        mime_type: "image/png",
        aspect_ratio: "4:5",
        image_size: this.imageSize,
      },
    });
    if (!interaction.output_image?.data) {
      throw new Error("Gemini returned no image");
    }
    return {
      buffer: Buffer.from(interaction.output_image.data, "base64"),
      mimeType: interaction.output_image.mime_type ?? "image/png",
      raw: {
        interactionId: interaction.id ?? null,
        outputText: interaction.output_text ?? "",
      },
    };
  }
}

