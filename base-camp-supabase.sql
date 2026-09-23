-- Base Camp on Supabase
-- Paste this whole file into the Supabase SQL Editor and hit Run.
-- Safe to run more than once.

create table if not exists bc_clients (
  id         text primary key,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists bc_prospects (
  id         text primary key,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists bc_agenda (
  id         text primary key,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists bc_meta (
  id         text primary key,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- Keep updated_at honest.
create or replace function bc_touch() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

do $$
declare t text;
begin
  foreach t in array array['bc_clients','bc_prospects','bc_agenda','bc_meta'] loop
    execute format('drop trigger if exists %I on %I', t || '_touch', t);
    execute format('create trigger %I before update on %I
                    for each row execute function bc_touch()', t || '_touch', t);
  end loop;
end $$;

-- Row level security.
-- These policies let the public anon key read and write these four tables.
-- That is the same protection level as a password-gated static page: the
-- password keeps casual visitors out, it does not stop someone who reads
-- the page source. Do not put anything here you would not put on the DRR site.
alter table bc_clients   enable row level security;
alter table bc_prospects enable row level security;
alter table bc_agenda    enable row level security;
alter table bc_meta      enable row level security;

do $$
declare t text;
begin
  foreach t in array array['bc_clients','bc_prospects','bc_agenda','bc_meta'] loop
    execute format('drop policy if exists %I on %I', t || '_anon_all', t);
    execute format('create policy %I on %I for all
                    to anon using (true) with check (true)', t || '_anon_all', t);
  end loop;
end $$;

-- Turn on realtime so both of you see each other's changes without refreshing.
do $$
declare t text;
begin
  foreach t in array array['bc_clients','bc_prospects','bc_agenda','bc_meta'] loop
    begin
      execute format('alter publication supabase_realtime add table %I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;
