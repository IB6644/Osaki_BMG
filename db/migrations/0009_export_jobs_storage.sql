-- Export jobs storage configuration and indexes

-- Ensure columns exist even on older schemas
alter table public.export_jobs
  add column if not exists team_id uuid references public.teams(id) on delete set null;

alter table public.export_jobs
  add column if not exists storage_bucket text not null default 'exports';

-- Indexes (safe after columns exist)
create index if not exists export_jobs_workspace_idx on public.export_jobs (workspace_id);
create index if not exists export_jobs_team_idx on public.export_jobs (team_id);
