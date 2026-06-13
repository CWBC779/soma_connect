# Strava OAuth backend (Supabase Edge Function)

This function keeps your Strava **client secret** off users' devices. The app
never sees the secret — it only calls this function to exchange the OAuth
`code`, refresh tokens, and fetch activities.

## 1. Register a Strava API application

1. Go to https://www.strava.com/settings/api and create an app.
2. Note the **Client ID** and **Client Secret**.
3. Set **Authorization Callback Domain** to your hosting domain (domain only,
   no `https://`, no path):
   ```
   cwbc779.github.io
   ```
   (Strava only allows one callback domain. For local web testing use
   `localhost`.)

## 2. Deploy the function

Install the Supabase CLI, then from the repo root:

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase functions deploy strava-auth --no-verify-jwt
supabase secrets set STRAVA_CLIENT_ID=xxxxx STRAVA_CLIENT_SECRET=xxxxx
```

`--no-verify-jwt` makes the function publicly callable (no Supabase auth needed).
If you prefer to require the anon key, drop that flag and set
`supabaseAnonKey` in `lib/config/strava_config.dart`.

Your function URL will be:
```
https://YOUR_PROJECT_REF.functions.supabase.co/strava-auth
```

## 3. Point the app at it

In `lib/config/strava_config.dart` set:
- `clientId`  → your Strava Client ID
- `redirectUri` → the exact URL your app is served from (must live under the
  callback domain above)
- `backendUrl` → the function URL from step 2

## API (JSON body)

| action | body | returns |
|--------|------|---------|
| `exchange` | `{ action, code }` | `{ access_token, refresh_token, expires_at, athlete }` |
| `refresh` | `{ action, refresh_token }` | `{ access_token, refresh_token, expires_at }` |
| `activities` | `{ action, access_token, per_page?, after? }` | `{ activities: [...] }` |

## Hardening for production (later)

This scaffold returns tokens to the client and stores them in
`SharedPreferences`. For a research deployment handling health data, consider:

- Storing tokens **server-side** (a Supabase table keyed to a pseudonymous user
  id) and returning only a session handle to the client, so access tokens never
  live on the device.
- Adding the **DPIA** + explicit research consent before any data leaves the
  user's account.
- Rate-limiting and logging access to the function.
