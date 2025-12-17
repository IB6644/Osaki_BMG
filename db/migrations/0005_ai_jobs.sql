-- AI jobs, framework storage, and export job scaffolding

create table if not exists framework_definitions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sections jsonb not null default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists framework_instances (
  id uuid primary key default gen_random_uuid(),
  team_id uuid references teams(id) on delete cascade,
  definition_id uuid references framework_definitions(id),
  version int not null default 1,
  sections jsonb not null default '{}'::jsonb,
  links jsonb not null default '{}'::jsonb,
  open_questions jsonb not null default '[]'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists ai_jobs (
  id uuid primary key default gen_random_uuid(),
  team_id uuid references teams(id) on delete cascade,
  workspace_id uuid references workspaces(id) on delete cascade,
  type text not null,
  status text not null default 'queued' check (status in ('queued', 'running', 'done', 'failed')),
  inputs_json jsonb not null default '{}'::jsonb,
  outputs_json jsonb,
  error text,
  tokens int,
  cost_estimate numeric,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists export_jobs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references workspaces(id) on delete cascade,
  team_id uuid references teams(id) on delete set null,
  requested_by uuid references auth.users not null,
  format text not null default 'pptx' check (format in ('pptx')),
  status text not null default 'queued' check (status in ('queued', 'running', 'done', 'failed')),
  file_path text,
  error text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table export_jobs
  add column if not exists workspace_id uuid references workspaces(id) on delete cascade,
  add column if not exists team_id uuid references teams(id) on delete set null,
  add column if not exists requested_by uuid references auth.users;

alter table framework_definitions enable row level security;
alter table framework_instances enable row level security;
alter table ai_jobs enable row level security;
alter table export_jobs enable row level security;

drop policy if exists "Authenticated can read framework definitions" on framework_definitions;
create policy "Authenticated can read framework definitions" on framework_definitions
  for select using (auth.role() = 'authenticated' or auth.role() = 'service_role');

drop policy if exists "Service role can manage framework definitions" on framework_definitions;
create policy "Service role can manage framework definitions" on framework_definitions
  for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

drop policy if exists "Workspace members can read framework instances" on framework_instances;
create policy "Workspace members can read framework instances" on framework_instances
  for select using (
    exists (
      select 1 from teams t where t.id = framework_instances.team_id and is_workspace_member(t.workspace_id)
    )
  );

drop policy if exists "Editors can manage framework instances" on framework_instances;
create policy "Editors can manage framework instances" on framework_instances
  for insert with check (
    exists (
      select 1 from teams t where t.id = framework_instances.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
  );

drop policy if exists "Editors can update framework instances" on framework_instances;
create policy "Editors can update framework instances" on framework_instances
  for update using (
    exists (
      select 1 from teams t where t.id = framework_instances.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
  ) with check (
    exists (
      select 1 from teams t where t.id = framework_instances.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
  );

drop policy if exists "Editors can delete framework instances" on framework_instances;
create policy "Editors can delete framework instances" on framework_instances
  for delete using (
    exists (
      select 1 from teams t where t.id = framework_instances.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
  );

drop policy if exists "Workspace members can read AI jobs" on ai_jobs;
create policy "Workspace members can read AI jobs" on ai_jobs
  for select using (
    exists (
      select 1 from teams t where t.id = ai_jobs.team_id and is_workspace_member(t.workspace_id)
    )
  );

drop policy if exists "Editors can create AI jobs" on ai_jobs;
create policy "Editors can create AI jobs" on ai_jobs
  for insert with check (
    exists (
      select 1 from teams t where t.id = ai_jobs.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
  );

drop policy if exists "Editors can update AI jobs" on ai_jobs;
create policy "Editors can update AI jobs" on ai_jobs
  for update using (
    exists (
      select 1 from teams t where t.id = ai_jobs.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
  ) with check (
    exists (
      select 1 from teams t where t.id = ai_jobs.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
  );

drop policy if exists "Workspace members can read export jobs" on export_jobs;
create policy "Workspace members can read export jobs" on export_jobs
  for select using (
    exists (
      select 1 from workspaces w where w.id = export_jobs.workspace_id and is_workspace_member(w.id)
    )
  );

drop policy if exists "Editors can manage export jobs" on export_jobs;
create policy "Editors can manage export jobs" on export_jobs
  for insert with check (
    exists (
      select 1 from teams t where t.id = export_jobs.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
    or exists (
      select 1 from workspaces w where w.id = export_jobs.workspace_id and is_workspace_owner(w.id)
    )
  );

drop policy if exists "Editors can update export jobs" on export_jobs;
create policy "Editors can update export jobs" on export_jobs
  for update using (
    exists (
      select 1 from teams t where t.id = export_jobs.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
    or exists (
      select 1 from workspaces w where w.id = export_jobs.workspace_id and is_workspace_owner(w.id)
    )
  ) with check (
    exists (
      select 1 from teams t where t.id = export_jobs.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
    or exists (
      select 1 from workspaces w where w.id = export_jobs.workspace_id and is_workspace_owner(w.id)
    )
  );

drop trigger if exists ai_jobs_updated_at on ai_jobs;
create trigger ai_jobs_updated_at before update on ai_jobs
for each row execute procedure set_updated_at();

drop trigger if exists export_jobs_updated_at on export_jobs;
create trigger export_jobs_updated_at before update on export_jobs
for each row execute procedure set_updated_at();

drop trigger if exists framework_definitions_updated_at on framework_definitions;
create trigger framework_definitions_updated_at before update on framework_definitions
for each row execute procedure set_updated_at();

drop trigger if exists framework_instances_updated_at on framework_instances;
create trigger framework_instances_updated_at before update on framework_instances
for each row execute procedure set_updated_at();
