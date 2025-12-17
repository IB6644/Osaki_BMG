-- Idea threads for deep-dive chat

create table if not exists idea_threads (
  idea_id uuid primary key references ideas(id) on delete cascade,
  messages jsonb not null default '[]'::jsonb,
  open_questions jsonb not null default '[]'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table idea_threads enable row level security;

create policy if not exists "Workspace members can read idea threads" on idea_threads
  for select using (
    exists (
      select 1 from ideas i
      join teams t on t.id = i.team_id
      where i.id = idea_threads.idea_id and is_workspace_member(t.workspace_id)
    )
  );

create policy if not exists "Editors can upsert idea threads" on idea_threads
  for insert with check (
    exists (
      select 1 from ideas i
      where i.id = idea_threads.idea_id and has_team_role(i.team_id, array['owner', 'editor'])
    )
  );

create policy if not exists "Editors can update idea threads" on idea_threads
  for update using (
    exists (
      select 1 from ideas i
      where i.id = idea_threads.idea_id and has_team_role(i.team_id, array['owner', 'editor'])
    )
  ) with check (
    exists (
      select 1 from ideas i
      where i.id = idea_threads.idea_id and has_team_role(i.team_id, array['owner', 'editor'])
    )
  );

create trigger idea_threads_updated_at before update on idea_threads
for each row execute procedure set_updated_at();
