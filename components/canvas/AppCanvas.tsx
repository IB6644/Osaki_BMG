"use client";

import { Editor, Tldraw } from "tldraw";
import "tldraw/tldraw.css";

interface AppCanvasProps {
  onEditorReady?: (editor: Editor) => void;
}

export default function AppCanvas({ onEditorReady }: AppCanvasProps) {
  return (
    <div className="absolute inset-0 h-full w-full overflow-hidden bg-neutral-900">
      <Tldraw persistenceKey="osaki-bmg-workspace" onMount={onEditorReady} />
    </div>
  );
}
