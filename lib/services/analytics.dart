import 'dart:math';

import '../data/sample_data.dart';
import '../models/models.dart';

class Analytics {
  // Sum of distances in the last 7 days ending at `reference` (inclusive)
  static double weeklyLoadKm(List<RunEntry> runs, DateTime reference) {
    final from = DateTime(reference.year, reference.month, reference.day).subtract(const Duration(days: 6));
    return runs
        .where((r) => !r.date.isBefore(from) && !r.date.isAfter(reference))
        .fold(0.0, (s, r) => s + r.distanceKm);
  }

  // Average weekly km from weekly summaries (baseline)
  static double baselineWeeklyKm() {
    final sums = SampleData.weeklySummaries.map((w) => w.totalKm.toDouble()).toList();
    if (sums.isEmpty) return 1.0;
    return sums.fold(0.0, (a, b) => a + b) / sums.length;
  }

  // Recovery percent derived from recent load vs baseline (0..1)
  // If load is much higher than baseline, recovery reduces.
  static double recoveryFromLoad(List<RunEntry> runs, DateTime reference) {
    final weekly = weeklyLoadKm(runs, reference);
    final baseline = max(1.0, baselineWeeklyKm());
    final ratio = weekly / baseline; // 1 = baseline
    // Map ratio to recovery: when ratio==1 => recovery 1.0
    // when ratio 1.5 => recovery 0.75 ; when ratio 2.0 => 0.5
    final rec = 1.0 - ((ratio - 1.0) * 0.5);
    return rec.clamp(0.0, 1.0);
  }

  // Readiness combines HRV (0..100), sleepHours, and recovery metric into 0..1
  // weights: HRV 45%, sleep 25%, recovery 30%
  static double readiness({required double hrv, required double sleepHours, required double recovery}) {
    final hrvScore = (hrv / 100.0).clamp(0.0, 1.0);
    final sleepScore = (sleepHours / 8.0).clamp(0.0, 1.0);
    final val = 0.45 * hrvScore + 0.25 * sleepScore + 0.30 * recovery;
    return val.clamp(0.0, 1.0);
  }

  // Compute average pace (min/km) and avg HRV per cycle phase from runs
  static Map<CyclePhase, Map<String, dynamic>> phaseCorrelation(List<RunEntry> runs) {
    final grouped = <CyclePhase, List<RunEntry>>{};
    for (var phase in CyclePhase.values) {
      grouped[phase] = [];
    }
    for (var r in runs) {
      grouped[r.phase]?.add(r);
    }

    final out = <CyclePhase, Map<String, dynamic>>{};
    grouped.forEach((phase, list) {
      if (list.isEmpty) {
        out[phase] = {'avgPace': null, 'avgHrv': null, 'runs': 0};
      } else {
        final avgPace = list.map((r) => (r.duration.inSeconds / 60.0) / r.distanceKm).fold(0.0, (a, b) => a + b) / list.length;
        final hrvList = list.map((r) => r.hrv).where((v) => v != null).map((v) => v!).toList();
        final avgHrv = hrvList.isEmpty ? null : hrvList.fold(0.0, (a, b) => a + b) / hrvList.length;
        out[phase] = {'avgPace': double.parse(avgPace.toStringAsFixed(2)), 'avgHrv': avgHrv == null ? null : double.parse(avgHrv.toStringAsFixed(1)), 'runs': list.length};
      }
    });
    return out;
  }

  // Weekly progress vs target
  static double weeklyProgress(List<RunEntry> runs, DateTime reference, double weeklyGoalKm) {
    final weekKm = weeklyLoadKm(runs, reference);
    if (weeklyGoalKm <= 0) return 0.0;
    return (weekKm / weeklyGoalKm).clamp(0.0, 1.0);
  }
}
