import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

// ── Cycle Phase ────────────────────────────────────────────────────────────
enum CyclePhase { menstrual, follicular, ovulation, luteal }

extension CyclePhaseX on CyclePhase {
  String get label {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Menstrual';
      case CyclePhase.follicular:
        return 'Follicular';
      case CyclePhase.ovulation:
        return 'Ovulation';
      case CyclePhase.luteal:
        return 'Luteal';
    }
  }

  String get description {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Days 1–5 · Low oestrogen. Prioritise rest and easy efforts.';
      case CyclePhase.follicular:
        return 'Days 6–13 · Rising oestrogen. Energy typically builds.';
      case CyclePhase.ovulation:
        return 'Days 14–16 · Oestrogen peaks. Many athletes feel strongest.';
      case CyclePhase.luteal:
        return 'Days 17–28 · Progesterone rises. Recovery focus.';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case CyclePhase.menstrual:
        return FemoraTheme.menstrualColor;
      case CyclePhase.follicular:
        return FemoraTheme.follicularColor;
      case CyclePhase.ovulation:
        return FemoraTheme.ovulationColor;
      case CyclePhase.luteal:
        return FemoraTheme.lutealColor;
    }
  }

  Color get textColor {
    switch (this) {
      case CyclePhase.menstrual:
        return FemoraTheme.menstrualText;
      case CyclePhase.follicular:
        return FemoraTheme.follicularText;
      case CyclePhase.ovulation:
        return FemoraTheme.ovulationText;
      case CyclePhase.luteal:
        return FemoraTheme.lutealText;
    }
  }

  // Proportion of a standard 28-day cycle
  double get cycleWeight {
    switch (this) {
      case CyclePhase.menstrual:
        return 5 / 28;
      case CyclePhase.follicular:
        return 8 / 28;
      case CyclePhase.ovulation:
        return 3 / 28;
      case CyclePhase.luteal:
        return 12 / 28;
    }
  }

  // Suggested intensity 0–5
  int get suggestedIntensity {
    switch (this) {
      case CyclePhase.menstrual:
        return 2;
      case CyclePhase.follicular:
        return 4;
      case CyclePhase.ovulation:
        return 5;
      case CyclePhase.luteal:
        return 3;
    }
  }
}

// ── Run Entry ──────────────────────────────────────────────────────────────
class RunEntry {
  final DateTime date;
  final double distanceKm;
  final Duration duration;
  final CyclePhase phase;
  final double? hrv;
  final double? restingHr;

  const RunEntry({
    required this.date,
    required this.distanceKm,
    required this.duration,
    required this.phase,
    this.hrv,
    this.restingHr,
  });

  /// Pace in minutes per km
  double get paceMinPerKm => duration.inSeconds / 60 / distanceKm;

  String get paceFormatted {
    final totalSeconds = (paceMinPerKm * 60).round();
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}

// ── Week Summary ───────────────────────────────────────────────────────────
class WeekSummary {
  final String label;
  final double totalKm;
  final int runs;
  final CyclePhase dominantPhase;

  const WeekSummary({
    required this.label,
    required this.totalKm,
    required this.runs,
    required this.dominantPhase,
  });
}

// ── Training Recommendation ────────────────────────────────────────────────
class DayRecommendation {
  final String dayLabel;
  final String sessionType;
  final String distanceRange;
  final int intensity; // 0–5
  final CyclePhase phase;
  final String note;

  const DayRecommendation({
    required this.dayLabel,
    required this.sessionType,
    required this.distanceRange,
    required this.intensity,
    required this.phase,
    required this.note,
  });
}

// ── Science Fact ───────────────────────────────────────────────────────────
class ScienceFact {
  final String emoji;
  final String tag;
  final String body;
  final Color cardColor;

  const ScienceFact({
    required this.emoji,
    required this.tag,
    required this.body,
    required this.cardColor,
  });
}

// ── Athlete Profile ────────────────────────────────────────────────────────
class AthleteProfile {
  final String name;
  final int cycleDay;
  final int cycleLength;
  final double weeklyGoalKm;
  final double currentWeekKm;
  final double readinessPercent;
  final double hrv;
  final double sleepHours;
  final double recoveryPercent;

  const AthleteProfile({
    required this.name,
    required this.cycleDay,
    required this.cycleLength,
    required this.weeklyGoalKm,
    required this.currentWeekKm,
    required this.readinessPercent,
    required this.hrv,
    required this.sleepHours,
    required this.recoveryPercent,
  });

  CyclePhase get currentPhase {
    if (cycleDay <= 5) return CyclePhase.menstrual;
    if (cycleDay <= 13) return CyclePhase.follicular;
    if (cycleDay <= 16) return CyclePhase.ovulation;
    return CyclePhase.luteal;
  }

  String get currentPhaseLabel {
    if (cycleDay >= 11 && cycleDay <= 13) return 'Late follicular';
    if (cycleDay >= 6 && cycleDay <= 10) return 'Early follicular';
    return currentPhase.label;
  }
}