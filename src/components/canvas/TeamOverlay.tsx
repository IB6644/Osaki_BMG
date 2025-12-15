"use client";

import { useMemo } from "react";

interface TeamMember {
  id: string;
  name: string;
  color: string;
}

export default function TeamOverlay() {
  const members = useMemo<TeamMember[]>(
    () => [
      { id: "1", name: "You", color: "#22d3ee" },
      { id: "2", name: "Teammate", color: "#a855f7" },
    ],
    [],
  );

  return (
    <div className="flex items-center gap-3 rounded-full bg-white/5 px-3 py-2 shadow-lg shadow-black/30 backdrop-blur">
      {members.map((member) => (
        <div key={member.id} className="flex items-center gap-2">
          <span
            aria-hidden
            className="block h-2.5 w-2.5 rounded-full"
            style={{ backgroundColor: member.color }}
          />
          <span className="text-sm text-white/80">{member.name}</span>
        </div>
      ))}
    </div>
  );
}
