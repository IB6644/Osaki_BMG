"use client";

import AppCanvas from "@/components/canvas/AppCanvas";
import TeamOverlay from "@/components/canvas/TeamOverlay";
import ChatSidebar from "@/components/workspace/ChatSidebar";
import { useCallback, useMemo, useState } from "react";
import { Editor, createShapeId } from "tldraw";
import { TLDefaultColorStyle, toRichText } from "@tldraw/tlschema";

interface WorkspacePageProps {
  params: { id: string };
}

const COLOR_STYLE_MAP: Record<TLDefaultColorStyle, string> = {
  black: "#0a0a0a",
  blue: "#3b82f6",
  green: "#22c55e",
  grey: "#6b7280",
  "light-blue": "#bfdbfe",
  "light-green": "#bbf7d0",
  "light-red": "#fecdd3",
  "light-violet": "#e9d5ff",
  orange: "#fb923c",
  red: "#ef4444",
  violet: "#8b5cf6",
  white: "#f8fafc",
  yellow: "#facc15",
};

export default function WorkspacePage({ params }: WorkspacePageProps) {
  const [editor, setEditor] = useState<Editor | null>(null);

  const colorEntries = useMemo(() => Object.entries(COLOR_STYLE_MAP), []);

  const normalizeColor = useCallback(
    (color?: string): TLDefaultColorStyle => {
      if (!color) return "yellow";
      const hex = color.startsWith("#") ? color : `#${color}`;
      const cleanHex = /^#?[0-9a-fA-F]{6}$/.test(color) ? hex : null;
      if (!cleanHex) return "yellow";

      const [r, g, b] = [
        parseInt(cleanHex.slice(1, 3), 16),
        parseInt(cleanHex.slice(3, 5), 16),
        parseInt(cleanHex.slice(5, 7), 16),
      ];

      let closest: { name: TLDefaultColorStyle; distance: number } = {
        name: "yellow",
        distance: Number.POSITIVE_INFINITY,
      };

      for (const [name, hexValue] of colorEntries) {
        const [cr, cg, cb] = [
          parseInt(hexValue.slice(1, 3), 16),
          parseInt(hexValue.slice(3, 5), 16),
          parseInt(hexValue.slice(5, 7), 16),
        ];
        const distance = Math.sqrt((r - cr) ** 2 + (g - cg) ** 2 + (b - cb) ** 2);
        if (distance < closest.distance) {
          closest = { name: name as TLDefaultColorStyle, distance };
        }
      }

      return closest.name;
    },
    [colorEntries],
  );

  const handleAddSticky = useCallback(
    (text: string, color?: string) => {
      if (!editor || !text.trim()) return;

      const bounds = editor.getViewportPageBounds();
      const center = bounds?.center ?? { x: 0, y: 0 };
      const shapeId = createShapeId();
      const colorStyle = normalizeColor(color);

      editor.createShape({
        id: shapeId,
        type: "note",
        x: center.x,
        y: center.y,
      });

      editor.updateShapes([
        {
          id: shapeId,
          type: "note",
          props: {
            color: colorStyle,
            richText: toRichText(text),
          },
        },
      ]);

      editor.select(shapeId);
    },
    [editor, normalizeColor],
  );

  const handleEditorReady = useCallback((instance: Editor) => {
    setEditor(instance);
  }, []);

  return (
    <main className="flex h-screen flex-col bg-neutral-950 text-white">
      <header className="flex items-center justify-between border-b border-white/10 px-6 py-4">
        <div>
          <p className="text-xs uppercase tracking-[0.2em] text-white/60">Workspace</p>
          <h1 className="text-xl font-semibold">{params.id}</h1>
        </div>
        <TeamOverlay />
      </header>

      <section className="flex flex-1 overflow-hidden">
        <div className="relative flex-1">
          <AppCanvas onEditorReady={handleEditorReady} />
        </div>
        <ChatSidebar onAddSticky={handleAddSticky} />
      </section>
    </main>
  );
}
