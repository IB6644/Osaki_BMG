"use client";

import { useRouter } from "next/navigation";
import { useCallback } from "react";

export default function Home() {
  const router = useRouter();

  const handleStart = useCallback(() => {
    const id = crypto.randomUUID();
    router.push(`/workspace/${id}`);
  }, [router]);

  return (
    <main className="flex min-h-screen items-center justify-center bg-gradient-to-br from-zinc-950 via-zinc-900 to-black px-6">
      <div className="flex w-full max-w-3xl flex-col items-center gap-8 rounded-3xl bg-white/5 p-10 text-center shadow-2xl shadow-black/40 backdrop-blur">
        <p className="text-sm uppercase tracking-[0.25em] text-white/60">Osaki BMG</p>
        <h1 className="text-3xl font-semibold text-white sm:text-4xl">
          ひらめきを形にする共同キャンバス
        </h1>
        <p className="max-w-2xl text-base text-white/70 sm:text-lg">
          ワークショップを立ち上げて、AIと一緒にアイデアを磨きましょう。生成された
          ワークスペースでは、キャンバスとチャットがすぐに使えます。
        </p>
        <button
          onClick={handleStart}
          className="group relative mt-4 inline-flex items-center gap-3 rounded-full bg-white px-6 py-3 text-base font-semibold text-black shadow-lg shadow-black/30 transition hover:translate-y-[-1px] hover:shadow-xl"
        >
          <span>新規ワークショップを開始</span>
          <span className="inline-block h-2 w-2 rounded-full bg-emerald-500 group-hover:bg-emerald-400" />
        </button>
      </div>
    </main>
  );
}
