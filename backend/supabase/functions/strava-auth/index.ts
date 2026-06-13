// Supabase Edge Function: strava-auth
//
// Proxies the Strava OAuth token exchange + refresh + activity fetch so that:
//   1. the Strava client_secret never ships inside the app, and
//   2. browser CORS on the Strava API is avoided.
//
// Deploy:
//   supabase functions deploy strava-auth --no-verify-jwt
//   supabase secrets set STRAVA_CLIENT_ID=xxxxx STRAVA_CLIENT_SECRET=xxxxx
//
// Request body (JSON):
//   { "action": "exchange",   "code": "..." }
//   { "action": "refresh",    "refresh_token": "..." }
//   { "action": "activities", "access_token": "...", "per_page": 30, "after": 0 }

const STRAVA_CLIENT_ID = Deno.env.get("STRAVA_CLIENT_ID") ?? "";
const STRAVA_CLIENT_SECRET = Deno.env.get("STRAVA_CLIENT_SECRET") ?? "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (!STRAVA_CLIENT_ID || !STRAVA_CLIENT_SECRET) {
    return json(
      { error: "Server not configured: set STRAVA_CLIENT_ID / STRAVA_CLIENT_SECRET" },
      500,
    );
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const action = body.action;

  try {
    if (action === "exchange" || action === "refresh") {
      const form = new URLSearchParams({
        client_id: STRAVA_CLIENT_ID,
        client_secret: STRAVA_CLIENT_SECRET,
      });
      if (action === "exchange") {
        form.set("code", String(body.code ?? ""));
        form.set("grant_type", "authorization_code");
      } else {
        form.set("refresh_token", String(body.refresh_token ?? ""));
        form.set("grant_type", "refresh_token");
      }
      const r = await fetch("https://www.strava.com/oauth/token", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: form,
      });
      const data = await r.json();
      if (!r.ok) return json({ error: "Strava token error", detail: data }, r.status);
      // Return only what the client needs.
      return json({
        access_token: data.access_token,
        refresh_token: data.refresh_token,
        expires_at: data.expires_at,
        athlete: data.athlete ?? null,
      });
    }

    if (action === "activities") {
      const accessToken = String(body.access_token ?? "");
      if (!accessToken) return json({ error: "Missing access_token" }, 400);
      const perPage = Number(body.per_page ?? 30);
      const after = body.after ? `&after=${Number(body.after)}` : "";
      const r = await fetch(
        `https://www.strava.com/api/v3/athlete/activities?per_page=${perPage}${after}`,
        { headers: { Authorization: `Bearer ${accessToken}` } },
      );
      const data = await r.json();
      if (!r.ok) return json({ error: "Strava API error", detail: data }, r.status);
      return json({ activities: data });
    }

    return json({ error: "Unknown action" }, 400);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
