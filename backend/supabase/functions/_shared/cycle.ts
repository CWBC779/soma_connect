export type Phase = "menstrual" | "follicular" | "ovulation" | "luteal";

/// Estimate cycle phase + 1-based cycle day for an activity date.
/// Mirrors the in-app CycleEstimator. NOT a hormone measurement.
export function phaseForDate(
  activity: Date,
  lastPeriodStart: Date,
  cycleLength: number,
): { phase: Phase; cycleDay: number } {
  const len = cycleLength > 0 ? cycleLength : 28;
  const a = Date.UTC(
    activity.getUTCFullYear(),
    activity.getUTCMonth(),
    activity.getUTCDate(),
  );
  const p = Date.UTC(
    lastPeriodStart.getUTCFullYear(),
    lastPeriodStart.getUTCMonth(),
    lastPeriodStart.getUTCDate(),
  );
  const diff = Math.floor((a - p) / 86400000);
  let mod = diff % len;
  if (mod < 0) mod += len;
  const day = mod + 1;

  const menstrualEnd = Math.round((5 * len) / 28);
  const follicularEnd = Math.round((13 * len) / 28);
  const ovulationEnd = Math.round((16 * len) / 28);

  let phase: Phase;
  if (day <= menstrualEnd) phase = "menstrual";
  else if (day <= follicularEnd) phase = "follicular";
  else if (day <= ovulationEnd) phase = "ovulation";
  else phase = "luteal";

  return { phase, cycleDay: day };
}
