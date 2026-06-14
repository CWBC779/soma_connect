// strava-sync — nightly catch-up. Iterates every connected participant,
// refreshes their token, pulls the last 30 days of activities and upserts any
// the webhook missed. Triggered by pg_cron (see migrations/cron template).
//
// Protected by a shared secret header (x-cron-secret). Deploy verify_jwt=false.

import { adminClient } from "../_shared/supabase.ts";
import { getActivities } from "../_shared/strava.ts";
import { storeActivities, validToken } from "../_shared/tokens.ts";

const CRON_SECRET = Deno.env.get("CRON_SECRET") ?? "";

Deno.serve(async (req) => {
  if (!CRON_SECRET || req.headers.get("x-cron-secret") !== CRON_SECRET) {
    return new Response("forbidden", { status: 403 });
  }

  const sb = adminClient();
  const { data: users } = await sb.from("strava_tokens").select("user_id");
  const after = Math.floor(Date.now() / 1000) - 30 * 86400;

  let synced = 0;
  let failed = 0;
  for (const u of users ?? []) {
    try {
      const t = await validToken(u.user_id);
      if (!t) continue;
      const acts = await getActivities(t.accessToken, { per_page: 100, after });
      synced += await storeActivities(u.user_id, acts);
    } catch (e) {
      failed++;
      console.error("sync failed for", u.user_id, e);
    }
  }

  return new Response(
    JSON.stringify({ ok: true, synced, failed, participants: users?.length ?? 0 }),
    { headers: { "Content-Type": "application/json" } },
  );
});
