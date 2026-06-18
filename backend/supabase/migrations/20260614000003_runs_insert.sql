-- Allow participants to insert their OWN runs (for the manual CSV-upload
-- feature). Reads are already restricted to own rows; this adds insert, still
-- within Row-Level Security.
drop policy if exists "insert own runs" on public.runs;
create policy "insert own runs" on public.runs
  for insert to authenticated
  with check (auth.uid() = user_id);
