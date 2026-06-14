// strava-login — "Sign in with Strava". Public function: no prior session.
//
// Takes the Strava OAuth `code`, identifies the athlete, maps them to a stable
// participant account (deterministic internal email keyed to the Strava athlete
// id), stores tokens server-side, records consent + demographics, backfills
// runs, and returns a Supabase session for the app to adopt.
//
// Body: { code, consent_version?, age_range?, training_level?, cycle_length? }

import { corsHeaders, json } from "../_shared/cors.ts";
import { adminClient, anonClient } from "../_shared/supabase.ts";
import { exchangeCode, getActivities } from "../_shared/strava.ts";
import { storeActivities } from "../_shared/tokens.ts";

const LOGIN_SECRET = Deno.env.get("STRAVA_LOGIN_SECRET") ?? "";

async function derivePassword(athleteId: number | string): Promise<string> {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    enc.encode(LOGIN_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, enc.encode(String(athleteId)));
  return btoa(String.fromCharCode(...new Uint8Array(sig)));
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (!LOGIN_SECRET) {
    return json({ error: "Server not configured: STRAVA_LOGIN_SECRET" }, 500);
  }

  let body: Record<string, unknown> = {};
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }
  const code = String(body.code ?? "");
  if (!code) return json({ error: "Missing code" }, 400);

  try {
    const tok = await exchangeCode(code);
    const athleteId = tok.athlete?.id;
    if (!athleteId) return json({ error: "No athlete id from Strava" }, 400);

    const email = `strava-${athleteId}@participants.somafemtech.com`;
    const password = await derivePassword(athleteId);
    const anon = anonClient();

    // Sign in; create the participant account on first connect.
    let signIn = await anon.auth.signInWithPassword({ email, password });
    if (signIn.error) {
      const created = await adminClient().auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      });
      if (created.error &&
          !String(created.error.message).toLowerCase().includes("already")) {
        return json({ error: `create user failed: ${created.error.message}` }, 500);
      }
      signIn = await anon.auth.signInWithPassword({ email, password });
      if (signIn.error) {
        return json({ error: `sign-in failed: ${signIn.error.message}` }, 500);
      }
    }

    const session = signIn.data.session!;
    const userId = signIn.data.user!.id;
    const admin = adminClient();

    await admin.from("strava_tokens").upsert({
      user_id: userId,
      athlete_id: athleteId,
      access_token: tok.access_token,
      refresh_token: tok.refresh_token,
      expires_at: tok.expires_at,
      updated_at: new Date().toISOString(),
    });

    // Record consent + demographics (captured on the welcome screen).
    const profile: Record<string, unknown> = { user_id: userId };
    if (body.consent_version) {
      profile.consent_version = body.consent_version;
      profile.consented_at = new Date().toISOString();
    }
    if (body.age_range) profile.age_range = body.age_range;
    if (body.training_level) profile.training_level = body.training_level;
    if (body.cycle_length) profile.cycle_length = body.cycle_length;
    await admin.from("profiles").upsert(profile);

    const acts = await getActivities(tok.access_token, { per_page: 100 });
    const imported = await storeActivities(userId, acts);

    return json({
      access_token: session.access_token,
      refresh_token: session.refresh_token,
      imported,
    });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
