-- Base schema: workspaces, teams, profiles, memberships, ideas

-- Enable extensions
create extension if not exists "pgcrypto";

-- Timestamp helper
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Workspaces
create table if not exists workspaces (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  owner_user_id uuid,
  team_count int not null default 1,
  frameworks_enabled jsonb default '[]'::jsonb,
  created_at timestamptz default now()
);

-- Teams
create table if not exists teams (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references workspaces(id) on delete cascade,
  name text not null default 'Team A',
  column_index int not null default 0,
  created_at timestamptz default now()
);

-- Profiles
create table if not exists profiles (
  user_id uuid primary key references auth.users on delete cascade,
  display_name text,
  color text,
  created_at timestamptz default now()
);

-- Memberships
create table if not exists team_memberships (
  team_id uuid references teams(id) on delete cascade,
  user_id uuid references auth.users on delete cascade,
  role text not null default 'viewer' check (role in ('owner', 'editor', 'viewer')),
  can_rename_team boolean default false,
  can_switch_team boolean default true,
  created_at timestamptz default now(),
  primary key (team_id, user_id)
);

-- Ideas
create table if not exists ideas (
  id uuid primary key default gen_random_uuid(),
  team_id uuid references teams(id) on delete cascade,
  author_user_id uuid references auth.users on delete set null,
  text text not null,
  refined_text text,
  state text default 'RAW',
  x int default 0,
  y int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create trigger ideas_updated_at before update on ideas
for each row execute procedure set_updated_at();

-- Demo seed
insert into workspaces (id, title, team_count)
values ('00000000-0000-0000-0000-000000000001', 'Demo Workspace', 1)
on conflict (id) do nothing;

insert into teams (id, workspace_id, name, column_index)
values ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Team A', 0)
on conflict (id) do nothing;

-- RLS enablement
alter table workspaces enable row level security;
alter table teams enable row level security;
alter table profiles enable row level security;
alter table team_memberships enable row level security;
alter table ideas enable row level security;

drop policy if exists "Profiles are self managed" on profiles;
create policy "Profiles are self managed" on profiles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Workspace visible to members" on workspaces;
create policy "Workspace visible to members" on workspaces
  for select using (
    exists (
      select 1 from teams t
      join team_memberships tm on tm.team_id = t.id
      where t.workspace_id = workspaces.id and tm.user_id = auth.uid()
    )
    or workspaces.id = '00000000-0000-0000-0000-000000000001'
  );

drop policy if exists "Teams visible to members" on teams;
create policy "Teams visible to members" on teams
  for select using (
    exists (
      select 1 from team_memberships tm where tm.team_id = teams.id and tm.user_id = auth.uid()
    )
  );

drop policy if exists "Members can view their memberships" on team_memberships;
create policy "Members can view their memberships" on team_memberships
  for select using (auth.uid() = user_id);

drop policy if exists "Members can upsert themselves into demo team" on team_memberships;
create policy "Members can upsert themselves into demo team" on team_memberships
  for insert with check (
    auth.uid() = user_id and team_id = '00000000-0000-0000-0000-000000000002'
  );

drop policy if exists "Members can read team ideas" on ideas;
create policy "Members can read team ideas" on ideas
  for select using (
    exists (
      select 1 from team_memberships tm where tm.team_id = ideas.team_id and tm.user_id = auth.uid()
    )
  );

drop policy if exists "Editors can add ideas" on ideas;
create policy "Editors can add ideas" on ideas
  for insert with check (
    exists (
      select 1 from team_memberships tm
      where tm.team_id = ideas.team_id and tm.user_id = auth.uid() and tm.role in ('owner', 'editor')
    )
  );
