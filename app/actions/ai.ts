"use server";

import { openai } from "@/lib/openai";

export interface Message {
  role: "system" | "user" | "assistant";
  content: string;
}

export interface ChatResult {
  reply: string;
  refined_idea?: {
    text: string;
    color?: string;
  };
}

const schema = {
  name: "refinedIdeaResponse",
  schema: {
    type: "object",
    properties: {
      reply: { type: "string" },
      refined_idea: {
        type: "object",
        properties: {
          text: { type: "string" },
          color: { type: "string" },
        },
        required: ["text", "color"],
        additionalProperties: false,
      },
    },
    required: ["reply"],
    additionalProperties: false,
  },
};

export async function chatWithAI(messages: Message[]): Promise<ChatResult> {
  const completion = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [
      {
        role: "system",
        content:
          "Return helpful, concise suggestions for workshop ideation. When a concrete idea is ready, propose a refined sticky note to pin on the canvas.",
      },
      ...messages,
    ],
    response_format: { type: "json_schema", json_schema: schema },
  });

  const raw = completion.choices[0]?.message?.content?.trim() ?? "{}";

  let parsed: ChatResult = { reply: "" };
  try {
    parsed = JSON.parse(raw);
  } catch {
    parsed.reply = raw;
  }

  if (!parsed.reply) {
    parsed.reply = "アイデアをまとめました。次の一歩を相談してください。";
  }

  return parsed;
}
