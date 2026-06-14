const CLIENT_ID = Deno.env.get("STRAVA_CLIENT_ID") ?? "";
const CLIENT_SECRET = Deno.env.get("STRAVA_CLIENT_SECRET") ?? "";

const TOKEN_URL = "https://www.strava.com/oauth/token";
const API = "https://www.strava.com/api/v3";

export async function exchangeCode(code: string) {
  const r = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      code,
      grant_type: "authorization_code",
    }),
  });
  if (!r.ok) throw new Error(`token exchange failed: ${await r.text()}`);
  return await r.json();
}

export async function refreshToken(refresh: string) {
  const r = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      refresh_token: refresh,
      grant_type: "refresh_token",
    }),
  });
  if (!r.ok) throw new Error(`token refresh failed: ${await r.text()}`);
  return await r.json();
}

export async function getActivities(
  accessToken: string,
  params: Record<string, string | number> = {},
) {
  const q = new URLSearchParams({ per_page: "100" });
  for (const [k, v] of Object.entries(params)) q.set(k, String(v));
  const r = await fetch(`${API}/athlete/activities?${q}`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!r.ok) throw new Error(`activities failed: ${await r.text()}`);
  return await r.json();
}

export async function getActivity(accessToken: string, id: number | string) {
  const r = await fetch(`${API}/activities/${id}`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!r.ok) throw new Error(`activity ${id} failed: ${await r.text()}`);
  return await r.json();
}
