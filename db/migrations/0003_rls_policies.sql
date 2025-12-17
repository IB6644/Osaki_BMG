-- RLS helper predicates and hardened policies for core tables

-- Helper predicates for workspace membership and team roles
create or replace function is_workspace_owner(target_workspace uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1 from workspaces w where w.id = target_workspace and w.owner_user_id = auth.uid()
  );
$$;

create or replace function is_workspace_member(target_workspace uuid)
returns boolean
language sql
stable
as $$
  select is_workspace_owner(target_workspace)
    or exists (
      select 1
      from team_memberships tm
      join teams t on t.id = tm.team_id
      where t.workspace_id = target_workspace and tm.user_id = auth.uid()
    );
$$;

create or replace function has_team_role(target_team uuid, allowed_roles text[])
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from team_memberships tm
    where tm.team_id = target_team and tm.user_id = auth.uid() and tm.role = any (allowed_roles)
  )
  or exists (
    select 1
    from teams t
    join workspaces w on w.id = t.workspace_id
    where t.id = target_team and w.owner_user_id = auth.uid()
  );
$$;

-- Workspaces policies
DROP POLICY IF EXISTS "Workspace visible to members" ON workspaces;
drop policy if exists "Workspace members can read workspace" on workspaces;
create policy "Workspace members can read workspace" on workspaces
  for select using (
    is_workspace_member(id)
    or id = '00000000-0000-0000-0000-000000000001'
  );

-- Teams policies
DROP POLICY IF EXISTS "Teams visible to workspace members" ON teams;
drop policy if exists "Workspace members can read teams" on teams;
create policy "Workspace members can read teams" on teams
  for select using (
    exists (
      select 1 from teams t2
      where t2.id = teams.id and (is_workspace_member(t2.workspace_id) or t2.workspace_id = '00000000-0000-0000-0000-000000000001')
    )
  );

-- Membership policies
DROP POLICY IF EXISTS "Members can view their memberships" ON team_memberships;
DROP POLICY IF EXISTS "Members can manage memberships in workspace" ON team_memberships;
DROP POLICY IF EXISTS "Members can update memberships in workspace" ON team_memberships;
DROP POLICY IF EXISTS "Members can delete their memberships" ON team_memberships;

drop policy if exists "Workspace members can read memberships" on team_memberships;
create policy "Workspace members can read memberships" on team_memberships
  for select using (
    exists (
      select 1 from teams t where t.id = team_memberships.team_id and is_workspace_member(t.workspace_id)
    )
  );

drop policy if exists "Members can insert their memberships" on team_memberships;
create policy "Members can insert their memberships" on team_memberships
  for insert with check (
    auth.uid() = user_id
    and exists (
      select 1 from teams t where t.id = team_id and is_workspace_member(t.workspace_id)
    )
  );

drop policy if exists "Allow onboarding into demo workspace" on team_memberships;
create policy "Allow onboarding into demo workspace" on team_memberships
  for insert with check (
    auth.uid() = user_id
    and exists (
      select 1 from teams t where t.id = team_id and t.workspace_id = '00000000-0000-0000-0000-000000000001'
    )
  );

drop policy if exists "Members can update their memberships" on team_memberships;
create policy "Members can update their memberships" on team_memberships
  for update using (
    auth.uid() = user_id
    and exists (
      select 1 from teams t where t.id = team_memberships.team_id and is_workspace_member(t.workspace_id)
    )
  ) with check (
    auth.uid() = user_id
    and exists (
      select 1 from teams t where t.id = team_memberships.team_id and is_workspace_member(t.workspace_id)
    )
  );

drop policy if exists "Members can delete their memberships" on team_memberships;
create policy "Members can delete their memberships" on team_memberships
  for delete using (
    auth.uid() = user_id
    and exists (
      select 1 from teams t where t.id = team_memberships.team_id and is_workspace_member(t.workspace_id)
    )
  );

-- Ideas policies
DROP POLICY IF EXISTS "Members can read team ideas" ON ideas;
DROP POLICY IF EXISTS "Editors can add ideas" ON ideas;

drop policy if exists "Workspace members can read team ideas" on ideas;
create policy "Workspace members can read team ideas" on ideas
  for select using (
    exists (
      select 1 from teams t where t.id = ideas.team_id and is_workspace_member(t.workspace_id)
    )
  );

drop policy if exists "Editors can manage ideas" on ideas;
create policy "Editors can manage ideas" on ideas
  for insert with check (
    exists (
      select 1 from teams t where t.id = ideas.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
  );

drop policy if exists "Editors can update ideas" on ideas;
create policy "Editors can update ideas" on ideas
  for update using (
    exists (
      select 1 from teams t where t.id = ideas.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
  ) with check (
    exists (
      select 1 from teams t where t.id = ideas.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
  );

drop policy if exists "Editors can delete ideas" on ideas;
create policy "Editors can delete ideas" on ideas
  for delete using (
    exists (
      select 1 from teams t where t.id = ideas.team_id and has_team_role(t.id, array['owner', 'editor'])
    )
  );
