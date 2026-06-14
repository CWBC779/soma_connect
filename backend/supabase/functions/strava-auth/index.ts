// strava-auth — authenticated Strava connect for research participants.
//
// Requires a Supabase user JWT (the app sends the logged-in participant's
// session token). Stores Strava tokens SERVER-SIDE (never on the device),
// keyed to the participant, and backfills their recent runs.
//
// Body: { action: "exchange", code }  |  { action: "sync" }  |  { action: "disconnect" }

import { corsHeaders, json } from "../_shared/cors.ts";
import { adminClient, userClient } from "../_shared/supabase.ts";
import { exchangeCode, getActivities } from "../_shared/strava.ts";
import { storeActivities, validToken } from "../_shared/tokens.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader) return json({ error: "Missing Authorization" }, 401);

  const { data: { user } } = await userClient(authHeader).auth.getUser();
  if (!user) return json({ error: "Not authenticated" }, 401);

  let body: Record<string, unknown> = {};
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  try {
    switch (body.action) {
      case "exchange": {
        const tok = await exchangeCode(String(body.code ?? ""));
        const sb = adminClient();
        await sb.from("strava_tokens").upsert({
          user_id: user.id,
          athlete_id: tok.athlete?.id ?? null,
          access_token: tok.access_token,
          refresh_token: tok.refresh_token,
          expires_at: tok.expires_at,
          updated_at: new Date().toISOString(),
        });
        const acts = await getActivities(tok.access_token, { per_page: 100 });
        const imported = await storeActivities(user.id, acts);
        return json({ ok: true, imported });
      }
      case "sync": {
        const t = await validToken(user.id);
        if (!t) return json({ error: "Strava not connected" }, 400);
        const acts = await getActivities(t.accessToken, { per_page: 100 });
        const imported = await storeActivities(user.id, acts);
        return json({ ok: true, imported });
      }
      case "disconnect": {
        await adminClient()
          .from("strava_tokens")
          .delete()
          .eq("user_id", user.id);
        return json({ ok: true });
      }
      case "status": {
        const { data } = await adminClient()
          .from("strava_tokens")
          .select("user_id")
          .eq("user_id", user.id)
          .maybeSingle();
        return json({ connected: !!data });
      }
      default:
        return json({ error: "Unknown action" }, 400);
    }
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
