-- Allow participants to insert their OWN runs (for the manual-upload feature).
-- Strava-sourced runs still come in via the Edge Functions (service role); this
-- adds a path for user-uploaded activity files, kept within RLS.
drop policy if exists "insert own runs" on public.runs;
create policy "insert own runs" on public.runs
  for insert to authenticated
  with check (auth.uid() = user_id);
