-- Study codes for participant login (replaces Sign in with Strava).
-- The researcher seeds codes; each participant enters one to join. A code maps
-- deterministically to a pseudonymous account.
create table if not exists public.study_codes (
  code        text primary key,
  user_id     uuid references auth.users(id) on delete set null,
  claimed_at  timestamptz,
  created_at  timestamptz not null default now()
);

alter table public.study_codes enable row level security;
-- No policies: only the service role (the code-login Edge Function) can read or
-- write study codes. Participants never query this table directly.

-- Seed example (run once, adjust the count). Then view the codes to distribute:
--   insert into public.study_codes (code)
--   select 'SOMA-' || upper(substr(md5(random()::text), 1, 6))
--   from generate_series(1, 50)
--   on conflict (code) do nothing;
--   select code from public.study_codes order by created_at;
