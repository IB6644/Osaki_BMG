import AppCanvas from "@/components/canvas/AppCanvas";
import TeamOverlay from "@/components/canvas/TeamOverlay";

interface WorkspacePageProps {
  params: { id: string };
}

export default function WorkspacePage({ params }: WorkspacePageProps) {
  return (
    <main className="flex h-screen flex-col bg-neutral-950 text-white">
      <header className="flex items-center justify-between border-b border-white/10 px-6 py-4">
        <div>
          <p className="text-xs uppercase tracking-[0.2em] text-white/60">Workspace</p>
          <h1 className="text-xl font-semibold">{params.id}</h1>
        </div>
        <TeamOverlay />
      </header>

      <section className="relative flex-1">
        <AppCanvas />
      </section>
    </main>
  );
}
