import '../models/models.dart';

/// Estimates menstrual-cycle phase for a given date from a known cycle anchor.
///
/// IMPORTANT: this is a *phase estimate* derived from cycle dates — NOT a
/// hormone measurement. Two athletes on the same cycle day can have very
/// different hormone levels. Always present results to the user as an
/// "estimated phase", never as a measured hormone level.
class CycleEstimator {
  /// First day of the most recent period the athlete logged.
  final DateTime lastPeriodStart;

  /// Typical cycle length in days (usually 21–35; default 28).
  final int cycleLength;

  const CycleEstimator({
    required this.lastPeriodStart,
    this.cycleLength = 28,
  });

  int get _len => cycleLength <= 0 ? 28 : cycleLength;

  /// 1-based day within the current cycle for [date].
  int cycleDayFor(DateTime date) {
    final anchor =
        DateTime(lastPeriodStart.year, lastPeriodStart.month, lastPeriodStart.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(anchor).inDays;
    final mod = diff % _len;
    final normalised = mod < 0 ? mod + _len : mod;
    return normalised + 1;
  }

  /// Estimated phase for [date].
  CyclePhase phaseFor(DateTime date) =>
      phaseForCycleDay(cycleDayFor(date), _len);

  /// Maps a cycle day to a phase, scaling the canonical 28-day boundaries
  /// (5 / 13 / 16) to the individual's cycle length.
  static CyclePhase phaseForCycleDay(int day, int cycleLength) {
    final len = cycleLength <= 0 ? 28 : cycleLength;
    final menstrualEnd = (5 * len / 28).round();
    final follicularEnd = (13 * len / 28).round();
    final ovulationEnd = (16 * len / 28).round();
    if (day <= menstrualEnd) return CyclePhase.menstrual;
    if (day <= follicularEnd) return CyclePhase.follicular;
    if (day <= ovulationEnd) return CyclePhase.ovulation;
    return CyclePhase.luteal;
  }
}
