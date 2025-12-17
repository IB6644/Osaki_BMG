-- Add shape type and author metadata to ideas
alter table ideas
  add column if not exists shape_type text default 'sticky' check (shape_type in ('sticky', 'bubble')),
  add column if not exists author_color text default '#22d3ee',
  add column if not exists author_display_name text;

-- Backfill existing rows with placeholder display names when missing
update ideas
  set author_display_name = coalesce(author_display_name, 'Guest')
where author_display_name is null;
