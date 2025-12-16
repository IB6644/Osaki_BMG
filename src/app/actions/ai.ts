"use server";

import { openai } from "@/lib/openai";

type Role = "assistant" | "user" | "system";

export interface Message {
  role: Role;
  content: string;
}

interface RefinedIdea {
  text?: string;
  color?: string;
}

interface ChatResult {
  reply: string;
  refined_idea?: RefinedIdea;
}

const schema = {
  type: "object",
  properties: {
    reply: { type: "string" },
    refined_idea: {
      type: "object",
      properties: {
        text: { type: "string" },
        color: { type: "string" },
      },
      required: [],
      additionalProperties: false,
    },
  },
  required: ["reply"],
  additionalProperties: false,
};

export async function chatWithAI(messages: Message[]): Promise<ChatResult> {
  if (!process.env.OPENAI_API_KEY) {
    return {
      reply: "OpenAIの鍵が設定されていません。環境変数 OPENAI_API_KEY を確認してください。",
    };
  }

  const completion = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    response_format: { type: "json_object" },
    messages: [
      {
        role: "system",
        content:
          "あなたはブレインストーミングのファシリテーターです。ユーザーのアイデアを短く要約し、必要に応じて付箋用のテキストと色コードを返してください。",
      },
      ...messages,
    ],
    functions: [
      {
        name: "workspace_assistant_reply",
        parameters: schema,
      },
    ],
    function_call: { name: "workspace_assistant_reply" },
  });

  const rawText = completion.choices[0]?.message?.content;

  if (!rawText) {
    return {
      reply: "AIからの応答を取得できませんでした。",
    };
  }

  try {
    const parsed = JSON.parse(rawText) as ChatResult;
    return {
      reply: parsed.reply,
      refined_idea: parsed.refined_idea,
    };
  } catch (error) {
    console.error("Failed to parse AI response", error);
    return {
      reply: rawText,
    };
  }
}
