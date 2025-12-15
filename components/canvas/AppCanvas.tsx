"use client";

import { Tldraw } from "tldraw";
import "tldraw/tldraw.css";

export default function AppCanvas() {
  return (
    <div className="absolute inset-0 h-full w-full overflow-hidden bg-neutral-900">
      <Tldraw persistenceKey="osaki-bmg-workspace" />
    </div>
  );
}
