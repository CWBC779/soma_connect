# SOMA Connect research backend (Supabase)

Robust, secure backend for a 6-month longitudinal study: per-participant
accounts (email magic link), Row-Level Security, server-side Strava tokens,
webhook + nightly capture, and a pseudonymised dataset you can export for ML.

> **Plan note:** for a live study use the **Supabase Pro plan (~$25/mo)** — the
> free tier pauses after 7 days of inactivity and has no daily backups.

## Architecture

```
Participant (app, logged in via email magic link)
      │  Supabase JWT
      ▼
strava-auth  ── stores Strava tokens server-side, backfills runs
Strava ── webhook ──▶ strava-webhook ── stores each new run
pg_cron (nightly) ──▶ strava-sync ── catches anything missed
      ▼
Postgres: profiles · cycles · runs · strava_tokens   (RLS on all)
```

Tables (see `migrations/`):
- **profiles** — pseudonymous `user_id`, consent record, demographics, cycle length.
- **cycles** — period-start dates over time.
- **runs** — the ML training table (date, distance, pace, HR, estimated phase/day).
- **strava_tokens** — server-side token vault (service-role only; never on device).

The only PII (email) lives in Supabase's managed `auth.users`, separate from the
research tables. Researchers query/export everything via the service role.

## One-time setup

### 1. Apply the schema
From the `backend` folder (project linked):
```powershell
supabase db push
```
Or paste `migrations/20260614000001_init.sql` into the Supabase **SQL Editor**.

### 2. Enable email auth
Dashboard → **Authentication → Providers → Email** → enable. Then
**Authentication → URL Configuration** → add your site URL
`https://cwbc779.github.io/soma_connect/` to the redirect allow-list.

### 3. Set secrets
```powershell
supabase secrets set STRAVA_CLIENT_ID=257907 STRAVA_CLIENT_SECRET=<secret>
supabase secrets set STRAVA_WEBHOOK_VERIFY_TOKEN=<any-random-string>
supabase secrets set CRON_SECRET=<another-random-string>
```
(`SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY` / `SUPABASE_ANON_KEY` are injected
automatically — don't set them.)

### 4. Deploy the functions
```powershell
supabase functions deploy strava-auth
supabase functions deploy strava-webhook
supabase functions deploy strava-sync
```

### 5. Register the Strava webhook (one time)
```powershell
curl -X POST https://www.strava.com/api/v3/push_subscriptions `
  -F client_id=257907 `
  -F client_secret=<secret> `
  -F callback_url=https://<project-ref>.functions.supabase.co/strava-webhook `
  -F verify_token=<STRAVA_WEBHOOK_VERIFY_TOKEN>
```
Strava immediately GETs the callback to verify it (the function echoes the
challenge). A `{ "id": ... }` response means it's subscribed.

### 6. Schedule the nightly catch-up
In the SQL Editor (fill in your ref + CRON_SECRET):
```sql
create extension if not exists pg_cron;
create extension if not exists pg_net;

select cron.schedule('soma-nightly-strava-sync', '0 2 * * *', $$
  select net.http_post(
    url := 'https://<project-ref>.functions.supabase.co/strava-sync',
    headers := jsonb_build_object(
      'Content-Type','application/json',
      'x-cron-secret','<CRON_SECRET>'
    )
  );
$$);
```

## Viewing / exporting the dataset

- **Browse:** Dashboard → **Table Editor → runs** (filter, sort).
- **Export CSV:** Table Editor → `runs` → **Export**.
- **Query/analyse:** **SQL Editor**, e.g.:
  ```sql
  select estimated_phase, count(*), avg(avg_pace_s_per_km)
  from runs group by estimated_phase;
  ```
- **Python/ML:** connect with the connection string in
  Dashboard → Settings → Database (use a read-only role for analysis).

## Security notes / hardening
- RLS is on every table; participants can only touch their own rows.
- Strava tokens never reach the device.
- For extra protection of tokens at rest, consider Supabase **Vault**/pgsodium
  column encryption.
- Before real participants: ethics/IRB approval, a DPIA, and the consent wording
  wired into the in-app consent gate.
