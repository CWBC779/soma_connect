import '../models/models.dart';

/// Pure helpers over a list of real [RunEntry]s. No demo data.
class Analytics {
  /// Sum of distances in the last 7 days ending at [reference] (inclusive).
  static double weeklyLoadKm(List<RunEntry> runs, DateTime reference) {
    final from = DateTime(reference.year, reference.month, reference.day)
        .subtract(const Duration(days: 6));
    return runs
        .where((r) => !r.date.isBefore(from) && !r.date.isAfter(reference))
        .fold(0.0, (s, r) => s + r.distanceKm);
  }

  /// Weekly progress toward [weeklyGoalKm], clamped 0..1.
  static double weeklyProgress(
      List<RunEntry> runs, DateTime reference, double weeklyGoalKm) {
    if (weeklyGoalKm <= 0) return 0.0;
    return (weeklyLoadKm(runs, reference) / weeklyGoalKm).clamp(0.0, 1.0);
  }

  static double totalKm(List<RunEntry> runs) =>
      runs.fold(0.0, (s, r) => s + r.distanceKm);

  static double? avgPaceMinPerKm(List<RunEntry> runs) {
    final valid = runs.where((r) => r.distanceKm > 0).toList();
    if (valid.isEmpty) return null;
    return valid.map((r) => r.paceMinPerKm).fold(0.0, (a, b) => a + b) /
        valid.length;
  }

  static RunEntry? latest(List<RunEntry> runs) {
    if (runs.isEmpty) return null;
    return runs.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }

  /// Average pace (min/km) + run count per cycle phase. avgPace is null for
  /// phases with no runs.
  static Map<CyclePhase, Map<String, dynamic>> phaseCorrelation(
      List<RunEntry> runs) {
    final grouped = {for (final p in CyclePhase.values) p: <RunEntry>[]};
    for (final r in runs) {
      grouped[r.phase]!.add(r);
    }
    final out = <CyclePhase, Map<String, dynamic>>{};
    grouped.forEach((phase, list) {
      if (list.isEmpty) {
        out[phase] = {'avgPace': null, 'runs': 0};
      } else {
        final avgPace =
            list.map((r) => r.paceMinPerKm).fold(0.0, (a, b) => a + b) /
                list.length;
        out[phase] = {'avgPace': avgPace, 'runs': list.length};
      }
    });
    return out;
  }

  /// Format a pace in minutes/km as "m:ss".
  static String formatPace(double minPerKm) {
    final totalSeconds = (minPerKm * 60).round();
    return '${totalSeconds ~/ 60}:${(totalSeconds % 60).toString().padLeft(2, '0')}';
  }
}
