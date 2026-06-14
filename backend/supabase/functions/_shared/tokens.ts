import { adminClient } from "./supabase.ts";
import { refreshToken } from "./strava.ts";
import { phaseForDate } from "./cycle.ts";

/// Return a valid (auto-refreshed) Strava access token for a participant.
export async function validToken(
  userId: string,
): Promise<{ accessToken: string; athleteId: number | null } | null> {
  const sb = adminClient();
  const { data } = await sb
    .from("strava_tokens")
    .select("*")
    .eq("user_id", userId)
    .maybeSingle();
  if (!data) return null;

  const now = Math.floor(Date.now() / 1000);
  if (data.access_token && now < data.expires_at - 60) {
    return { accessToken: data.access_token, athleteId: data.athlete_id };
  }
  const fresh = await refreshToken(data.refresh_token);
  await sb
    .from("strava_tokens")
    .update({
      access_token: fresh.access_token,
      refresh_token: fresh.refresh_token,
      expires_at: fresh.expires_at,
      updated_at: new Date().toISOString(),
    })
    .eq("user_id", userId);
  return { accessToken: fresh.access_token, athleteId: data.athlete_id };
}

/// Insert/refresh runs for a participant from raw Strava activities.
/// Only runs with a distance are stored. Returns the number upserted.
export async function storeActivities(
  userId: string,
  activities: unknown[],
): Promise<number> {
  const sb = adminClient();
  const { data: cyc } = await sb
    .from("cycles")
    .select("*")
    .eq("user_id", userId)
    .order("recorded_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  const rows: Record<string, unknown>[] = [];
  for (const raw of activities) {
    const a = raw as Record<string, unknown>;
    const type = String(a.type ?? a.sport_type ?? "");
    const distance = Number(a.distance ?? 0);
    if (!type.toLowerCase().includes("run")) continue;
    if (!(distance > 0)) continue;

    const start = new Date(String(a.start_date));
    let phase: string | null = null;
    let cycleDay: number | null = null;
    if (cyc) {
      const e = phaseForDate(
        start,
        new Date(cyc.last_period_start),
        cyc.cycle_length,
      );
      phase = e.phase;
      cycleDay = e.cycleDay;
    }
    const movingTime = Number(a.moving_time ?? 0);
    const pace = distance > 0 ? movingTime / (distance / 1000) : null;

    rows.push({
      user_id: userId,
      source: "strava",
      external_id: String(a.id),
      start_date: start.toISOString(),
      distance_m: distance,
      moving_time_s: movingTime,
      avg_pace_s_per_km: pace,
      avg_heartrate: a.average_heartrate ?? null,
      estimated_phase: phase,
      estimated_cycle_day: cycleDay,
      synced_at: new Date().toISOString(),
    });
  }

  if (rows.length === 0) return 0;
  const { error } = await sb
    .from("runs")
    .upsert(rows, { onConflict: "user_id,source,external_id" });
  if (error) throw new Error(`upsert runs failed: ${error.message}`);
  return rows.length;
}
