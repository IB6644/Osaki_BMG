-- Export jobs storage configuration and indexes
alter table export_jobs
  add column if not exists storage_bucket text default 'exports';

create index if not exists export_jobs_workspace_idx on export_jobs (workspace_id);
create index if not exists export_jobs_team_idx on export_jobs (team_id);
