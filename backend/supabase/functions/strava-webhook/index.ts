// strava-webhook — receives Strava push events so runs are captured the moment
// a participant uploads, even if they never open the app.
//
// GET  = Strava subscription validation (echoes hub.challenge).
// POST = activity event → fetch the activity and store it for the owner.
//
// Public function (Strava calls it). Deploy with verify_jwt = false.

import { adminClient } from "../_shared/supabase.ts";
import { getActivity } from "../_shared/strava.ts";
import { storeActivities, validToken } from "../_shared/tokens.ts";

const VERIFY = Deno.env.get("STRAVA_WEBHOOK_VERIFY_TOKEN") ?? "";

Deno.serve(async (req) => {
  const url = new URL(req.url);

  // 1) Subscription handshake
  if (req.method === "GET") {
    const mode = url.searchParams.get("hub.mode");
    const token = url.searchParams.get("hub.verify_token");
    const challenge = url.searchParams.get("hub.challenge");
    if (mode === "subscribe" && token === VERIFY && challenge) {
      return new Response(JSON.stringify({ "hub.challenge": challenge }), {
        headers: { "Content-Type": "application/json" },
      });
    }
    return new Response("forbidden", { status: 403 });
  }

  // 2) Activity events. Always 200 fast so Strava doesn't retry-storm us.
  if (req.method === "POST") {
    try {
      const evt = await req.json();
      if (
        evt?.object_type === "activity" &&
        (evt.aspect_type === "create" || evt.aspect_type === "update")
      ) {
        const sb = adminClient();
        const { data: tok } = await sb
          .from("strava_tokens")
          .select("user_id")
          .eq("athlete_id", evt.owner_id)
          .maybeSingle();
        if (tok) {
          const t = await validToken(tok.user_id);
          if (t) {
            const act = await getActivity(t.accessToken, evt.object_id);
            await storeActivities(tok.user_id, [act]);
          }
        }
      }
    } catch (e) {
      console.error("webhook error", e);
    }
    return new Response("ok", { status: 200 });
  }

  return new Response("method not allowed", { status: 405 });
});
