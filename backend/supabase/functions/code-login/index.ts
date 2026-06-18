// code-login — "Sign in with a study code". Public function: no prior session.
//
// Validates the code against study_codes, maps it to a stable pseudonymous
// account (internal email keyed to the code, password derived via HMAC of
// CODE_LOGIN_SECRET), records consent + demographics, and returns a Supabase
// session for the app to adopt.
//
// Body: { code, consent_version?, age_range?, training_level?, cycle_length? }

import { corsHeaders, json } from "../_shared/cors.ts";
import { adminClient, anonClient } from "../_shared/supabase.ts";

const SECRET = Deno.env.get("CODE_LOGIN_SECRET") ?? "";

async function derivePassword(code: string): Promise<string> {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    enc.encode(SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, enc.encode(code));
  return btoa(String.fromCharCode(...new Uint8Array(sig)));
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (!SECRET) return json({ error: "Server not configured: CODE_LOGIN_SECRET" }, 500);

  let body: Record<string, unknown> = {};
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }
  const code = String(body.code ?? "").trim().toUpperCase();
  if (!code) return json({ error: "Please enter your study code." }, 400);

  try {
    const admin = adminClient();
    const { data: rec } = await admin
      .from("study_codes")
      .select("code, user_id")
      .eq("code", code)
      .maybeSingle();
    if (!rec) return json({ error: "Invalid study code." }, 403);

    const email = `code-${code.toLowerCase()}@participants.somafemtech.com`;
    const password = await derivePassword(code);
    const anon = anonClient();

    let signIn = await anon.auth.signInWithPassword({ email, password });
    if (signIn.error) {
      const created = await admin.auth.admin.createUser({
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

    if (!rec.user_id) {
      await admin
        .from("study_codes")
        .update({ user_id: userId, claimed_at: new Date().toISOString() })
        .eq("code", code);
    }

    const profile: Record<string, unknown> = { user_id: userId };
    if (body.consent_version) {
      profile.consent_version = body.consent_version;
      profile.consented_at = new Date().toISOString();
    }
    if (body.age_range) profile.age_range = body.age_range;
    if (body.training_level) profile.training_level = body.training_level;
    if (body.cycle_length) profile.cycle_length = body.cycle_length;
    await admin.from("profiles").upsert(profile);

    return json({
      access_token: session.access_token,
      refresh_token: session.refresh_token,
    });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
