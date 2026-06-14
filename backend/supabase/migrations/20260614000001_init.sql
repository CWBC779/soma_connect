-- SOMA Connect research backend — initial schema.
--
-- Design principles:
--  * Pseudonymised: research tables key on auth user_id (a random UUID). The
--    only PII (email) lives in Supabase's managed `auth.users`, kept separate.
--  * Row Level Security on every table: a participant can only ever touch their
--    OWN rows. Researchers read everything via the service role / SQL editor.
--  * Strava tokens live server-side (service-role only) — never on the device.
--  * Consent-gated: a participant has no profile data until they consent.

-- ── profiles ────────────────────────────────────────────────────────────────
create table if not exists public.profiles (
  user_id        uuid primary key references auth.users(id) on delete cascade,
  created_at     timestamptz not null default now(),
  age_range      text,
  training_level text,
  cycle_length   int  not null default 28,
  consent_version text,
  consented_at   timestamptz,
  withdrawn_at   timestamptz
);

-- ── cycles (period-start records over time) ─────────────────────────────────
create table if not exists public.cycles (
  id               bigint generated always as identity primary key,
  user_id          uuid not null references auth.users(id) on delete cascade,
  last_period_start date not null,
  cycle_length     int  not null default 28,
  recorded_at      timestamptz not null default now()
);
create index if not exists cycles_user_idx on public.cycles(user_id);

-- ── runs (the ML training table) ────────────────────────────────────────────
create table if not exists public.runs (
  id                 bigint generated always as identity primary key,
  user_id            uuid not null references auth.users(id) on delete cascade,
  source             text not null default 'strava',
  external_id        text,                 -- strava activity id (dedup)
  start_date         timestamptz not null,
  distance_m         double precision not null,
  moving_time_s      int not null,
  avg_pace_s_per_km  double precision,
  avg_heartrate      double precision,
  estimated_phase    text,                 -- menstrual|follicular|ovulation|luteal|null
  estimated_cycle_day int,
  raw                jsonb,
  synced_at          timestamptz not null default now(),
  unique (user_id, source, external_id)
);
create index if not exists runs_user_idx on public.runs(user_id);
create index if not exists runs_start_idx on public.runs(start_date);

-- ── strava_tokens (server-side token vault) ─────────────────────────────────
create table if not exists public.strava_tokens (
  user_id       uuid primary key references auth.users(id) on delete cascade,
  athlete_id    bigint,                 -- strava athlete id (webhook lookup)
  access_token  text not null,
  refresh_token text not null,
  expires_at    bigint not null,        -- epoch seconds
  updated_at    timestamptz not null default now()
);
create index if not exists strava_tokens_athlete_idx on public.strava_tokens(athlete_id);

-- ── Row Level Security ──────────────────────────────────────────────────────
alter table public.profiles      enable row level security;
alter table public.cycles        enable row level security;
alter table public.runs          enable row level security;
alter table public.strava_tokens enable row level security;

-- Participants may read/write only their own profile & cycles.
drop policy if exists "own profile" on public.profiles;
create policy "own profile" on public.profiles
  for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own cycles" on public.cycles;
create policy "own cycles" on public.cycles
  for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Participants may READ their own runs; inserts happen only via the Edge
-- Functions (service role bypasses RLS), never directly from the client.
drop policy if exists "read own runs" on public.runs;
create policy "read own runs" on public.runs
  for select to authenticated
  using (auth.uid() = user_id);

-- strava_tokens: RLS enabled with NO policies => denied to anon/authenticated.
-- Only the service role (Edge Functions) can read/write tokens.

-- ── Auto-create a profile row when a user signs up ──────────────────────────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
