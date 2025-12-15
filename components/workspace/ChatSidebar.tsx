"use client";

import { useEffect, useMemo, useRef, useState, useTransition } from "react";
import { chatWithAI, type Message } from "@/app/actions/ai";

interface ChatSidebarProps {
  onAddSticky: (text: string, color?: string) => void;
}

type ChatRole = Message["role"];

const initialMessages: Message[] = [
  {
    role: "assistant",
    content: "アイデアの方向性を教えてください。キャンバスに付箋としてまとめます。",
  },
];

export default function ChatSidebar({ onAddSticky }: ChatSidebarProps) {
  const [messages, setMessages] = useState<Message[]>(initialMessages);
  const [input, setInput] = useState("");
  const [isPending, startTransition] = useTransition();
  const listRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = listRef.current;
    if (el) {
      el.scrollTop = el.scrollHeight;
    }
  }, [messages]);

  const renderRoleLabel = useMemo(() => {
    const labels: Record<ChatRole, string> = {
      assistant: "AI",
      user: "You",
      system: "System",
    };
    return labels;
  }, []);

  const handleSubmit = () => {
    if (!input.trim() || isPending) return;

    const nextMessages: Message[] = [...messages, { role: "user", content: input.trim() }];
    setMessages(nextMessages);
    setInput("");

    startTransition(async () => {
      try {
        const result = await chatWithAI(nextMessages);
        setMessages((prev) => [...prev, { role: "assistant", content: result.reply }]);

        if (result.refined_idea?.text) {
          onAddSticky(result.refined_idea.text, result.refined_idea.color);
        }
      } catch (error) {
        console.error("AI chat failed", error);
        setMessages((prev) => [
          ...prev,
          {
            role: "assistant",
            content: "AIとの通信でエラーが発生しました。しばらくしてからもう一度お試しください。",
          },
        ]);
      }
    });
  };

  return (
    <aside className="flex w-full max-w-md flex-col border-l border-white/10 bg-neutral-900/80 backdrop-blur">
      <div className="flex items-center justify-between border-b border-white/10 px-4 py-3">
        <div>
          <p className="text-xs uppercase tracking-[0.2em] text-white/60">AI Chat</p>
          <p className="text-sm text-white/70">キャンバス右で付箋を自動追加</p>
        </div>
        {isPending && <span className="h-2 w-2 animate-pulse rounded-full bg-emerald-400" />}
      </div>

      <div ref={listRef} className="flex-1 space-y-3 overflow-y-auto px-4 py-4">
        {messages.map((message, index) => (
          <div key={`${message.role}-${index}`} className="flex flex-col gap-1 rounded-2xl bg-white/5 p-3">
            <span className="text-xs uppercase tracking-[0.2em] text-white/50">
              {renderRoleLabel[message.role]}
            </span>
            <p className="whitespace-pre-line text-sm leading-relaxed text-white/80">{message.content}</p>
          </div>
        ))}
      </div>

      <div className="border-t border-white/10 p-4">
        <div className="flex items-center gap-3">
          <textarea
            value={input}
            onChange={(event) => setInput(event.target.value)}
            placeholder="アイデアや質問を入力..."
            className="h-24 w-full rounded-2xl border border-white/10 bg-white/5 p-3 text-sm text-white placeholder:text-white/50 focus:border-emerald-400 focus:outline-none"
          />
          <button
            type="button"
            onClick={handleSubmit}
            disabled={isPending || !input.trim()}
            className="h-24 rounded-2xl bg-emerald-500 px-4 text-sm font-semibold text-black shadow-lg shadow-emerald-500/30 transition hover:bg-emerald-400 disabled:cursor-not-allowed disabled:bg-emerald-700/50"
          >
            送信
          </button>
        </div>
      </div>
    </aside>
  );
}
