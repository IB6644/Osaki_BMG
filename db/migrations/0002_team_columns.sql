-- Team columns generation and workspace-wide membership visibility

-- constrain team_count to 1..3
alter table workspaces alter column team_count set default 1;

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints where constraint_name = 'workspaces_team_count_range'
  ) then
    alter table workspaces add constraint workspaces_team_count_range check (team_count between 1 and 3);
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'teams_workspace_column_unique'
  ) then
    alter table teams add constraint teams_workspace_column_unique unique (workspace_id, column_index);
  end if;
end;
$$;

create or replace function ensure_workspace_teams()
returns trigger as $$
declare
  existing_count int;
  idx int;
  target_count int;
begin
  target_count := greatest(1, least(3, new.team_count));
  select count(*) into existing_count from teams where workspace_id = new.id;

  if tg_op = 'INSERT' then
    for idx in 0..target_count - 1 loop
      insert into teams (workspace_id, name, column_index)
      values (new.id, format('Team %s', chr(65 + idx)), idx)
      on conflict (workspace_id, column_index) do nothing;
    end loop;
  elsif tg_op = 'UPDATE' then
    if target_count > existing_count then
      for idx in existing_count..target_count - 1 loop
        insert into teams (workspace_id, name, column_index)
        values (new.id, format('Team %s', chr(65 + idx)), idx)
        on conflict (workspace_id, column_index) do nothing;
      end loop;
    end if;
  end if;

  return new;
end;
$$ language plpgsql;

drop trigger if exists ensure_workspace_teams_insert on workspaces;
drop trigger if exists ensure_workspace_teams_update on workspaces;
create trigger ensure_workspace_teams_insert after insert on workspaces for each row execute procedure ensure_workspace_teams();
create trigger ensure_workspace_teams_update after update of team_count on workspaces for each row execute procedure ensure_workspace_teams();

-- backfill to enforce team_count bounds and ensure teams exist
update workspaces set team_count = team_count;

-- broaden visibility to workspace-wide membership
DROP POLICY IF EXISTS "Teams visible to members" ON teams;
drop policy if exists "Teams visible to workspace members" on teams;
create policy "Teams visible to workspace members" on teams
  for select using (
    exists (
      select 1
      from team_memberships tm
      join teams t2 on t2.id = tm.team_id
      where t2.workspace_id = teams.workspace_id and tm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Members can view their memberships" ON team_memberships;
DROP POLICY IF EXISTS "Members can upsert themselves into demo team" ON team_memberships;

drop policy if exists "Members can view their memberships" on team_memberships;
create policy "Members can view their memberships" on team_memberships
  for select using (auth.uid() = user_id);

drop policy if exists "Members can manage memberships in workspace" on team_memberships;
create policy "Members can manage memberships in workspace" on team_memberships
  for insert with check (
    auth.uid() = user_id
    and exists (select 1 from teams t where t.id = team_id)
  );

drop policy if exists "Members can update memberships in workspace" on team_memberships;
create policy "Members can update memberships in workspace" on team_memberships
  for update using (
    auth.uid() = user_id
    and exists (select 1 from teams t where t.id = team_memberships.team_id)
  ) with check (
    auth.uid() = user_id
    and exists (select 1 from teams t where t.id = team_memberships.team_id)
  );

drop policy if exists "Members can delete their memberships" on team_memberships;
create policy "Members can delete their memberships" on team_memberships
  for delete using (auth.uid() = user_id);
