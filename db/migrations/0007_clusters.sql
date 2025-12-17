-- Cluster suggestions and approvals

create table if not exists clusters (
  id uuid primary key default gen_random_uuid(),
  team_id uuid references teams(id) on delete cascade,
  title text not null,
  idea_ids jsonb not null default '[]'::jsonb,
  bounds jsonb,
  rationale text,
  created_by text default 'ai' check (created_by in ('ai', 'manual')),
  status text not null default 'suggested' check (status in ('suggested', 'approved', 'inactive')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists clusters_team_id_idx on clusters(team_id);

alter table clusters enable row level security;

create policy if not exists "Workspace members can read clusters" on clusters
  for select using (
    exists (
      select 1 from teams t where t.id = clusters.team_id and is_workspace_member(t.workspace_id)
    )
  );

create policy if not exists "Editors can manage clusters" on clusters
  for insert with check (
    exists (
      select 1 from teams t where t.id = clusters.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
  );

create policy if not exists "Editors can update clusters" on clusters
  for update using (
    exists (
      select 1 from teams t where t.id = clusters.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
  ) with check (
    exists (
      select 1 from teams t where t.id = clusters.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
  );

create policy if not exists "Editors can delete clusters" on clusters
  for delete using (
    exists (
      select 1 from teams t where t.id = clusters.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
  );

create trigger clusters_updated_at before update on clusters
for each row execute procedure set_updated_at();
