import 'package:flutter/material.dart';
import '../models/models.dart';
import '../themes/app_theme.dart';

class SampleData {
  // ── Athlete ──────────────────────────────────────────────────────────────
  static const AthleteProfile athlete = AthleteProfile(
    name: 'Sarah',
    cycleDay: 12,
    cycleLength: 28,
    weeklyGoalKm: 38,
    currentWeekKm: 16,
    readinessPercent: 0.80,
    hrv: 74,
    sleepHours: 7.1,
    recoveryPercent: 0.82,
  );

  // ── Runs (last 3 months) ─────────────────────────────────────────────────
  static final List<RunEntry> runs = [
    RunEntry(date: DateTime(2025, 5, 28), distanceKm: 6.2, duration: const Duration(minutes: 32, seconds: 14), phase: CyclePhase.follicular, hrv: 74),
    RunEntry(date: DateTime(2025, 5, 26), distanceKm: 10.1, duration: const Duration(minutes: 51, seconds: 30), phase: CyclePhase.follicular, hrv: 71),
    RunEntry(date: DateTime(2025, 5, 24), distanceKm: 14.5, duration: const Duration(minutes: 72, seconds: 15), phase: CyclePhase.follicular, hrv: 68),
    RunEntry(date: DateTime(2025, 5, 20), distanceKm: 5.0, duration: const Duration(minutes: 27, seconds: 0), phase: CyclePhase.menstrual, hrv: 58),
    RunEntry(date: DateTime(2025, 5, 18), distanceKm: 7.2, duration: const Duration(minutes: 39, seconds: 36), phase: CyclePhase.menstrual, hrv: 61),
    RunEntry(date: DateTime(2025, 5, 15), distanceKm: 16.0, duration: const Duration(minutes: 77, seconds: 44), phase: CyclePhase.luteal, hrv: 65),
    RunEntry(date: DateTime(2025, 5, 13), distanceKm: 8.5, duration: const Duration(minutes: 44, seconds: 20), phase: CyclePhase.ovulation, hrv: 78),
    RunEntry(date: DateTime(2025, 5, 11), distanceKm: 5.0, duration: const Duration(minutes: 24, seconds: 50), phase: CyclePhase.ovulation, hrv: 76),
    RunEntry(date: DateTime(2025, 5, 9), distanceKm: 12.0, duration: const Duration(minutes: 61, seconds: 12), phase: CyclePhase.follicular, hrv: 72),
    RunEntry(date: DateTime(2025, 5, 7), distanceKm: 6.0, duration: const Duration(minutes: 31, seconds: 0), phase: CyclePhase.follicular, hrv: 69),
    RunEntry(date: DateTime(2025, 5, 5), distanceKm: 10.0, duration: const Duration(minutes: 54, seconds: 0), phase: CyclePhase.menstrual, hrv: 56),
    RunEntry(date: DateTime(2025, 4, 28), distanceKm: 9.0, duration: const Duration(minutes: 48, seconds: 36), phase: CyclePhase.luteal, hrv: 63),
    RunEntry(date: DateTime(2025, 4, 25), distanceKm: 15.2, duration: const Duration(minutes: 81, seconds: 4), phase: CyclePhase.luteal, hrv: 66),
    RunEntry(date: DateTime(2025, 4, 22), distanceKm: 6.5, duration: const Duration(minutes: 33, seconds: 45), phase: CyclePhase.ovulation, hrv: 77),
  ];

  // ── Week Summaries ───────────────────────────────────────────────────────
  static const List<WeekSummary> weeklySummaries = [
    WeekSummary(label: 'Week 1', totalKm: 31, runs: 4, dominantPhase: CyclePhase.menstrual),
    WeekSummary(label: 'Week 2', totalKm: 38, runs: 5, dominantPhase: CyclePhase.follicular),
    WeekSummary(label: 'Week 3', totalKm: 27, runs: 4, dominantPhase: CyclePhase.luteal),
    WeekSummary(label: 'Week 4', totalKm: 46, runs: 6, dominantPhase: CyclePhase.ovulation),
  ];

  // ── Phase Performance Summary ────────────────────────────────────────────
  static Map<CyclePhase, Map<String, dynamic>> phaseStats = {
    CyclePhase.menstrual: {'avgPace': 5.50, 'avgHrv': 58.0, 'runs': 14, 'trend': 'slower'},
    CyclePhase.follicular: {'avgPace': 5.17, 'avgHrv': 71.0, 'runs': 21, 'trend': 'faster'},
    CyclePhase.ovulation: {'avgPace': 4.97, 'avgHrv': 76.0, 'runs': 11, 'trend': 'best'},
    CyclePhase.luteal: {'avgPace': 5.40, 'avgHrv': 64.0, 'runs': 28, 'trend': 'average'},
  };

  // ── 7-Day Training Plan ──────────────────────────────────────────────────
  static const List<DayRecommendation> weekPlan = [
    DayRecommendation(dayLabel: 'Today', sessionType: 'Threshold run', distanceRange: '8–12 km', intensity: 4, phase: CyclePhase.follicular, note: 'HRV elevated — good day for quality work'),
    DayRecommendation(dayLabel: 'Tomorrow', sessionType: 'Easy run', distanceRange: '4–6 km', intensity: 2, phase: CyclePhase.follicular, note: 'Recovery between hard sessions'),
    DayRecommendation(dayLabel: 'Sat', sessionType: 'Long run', distanceRange: '14–18 km', intensity: 5, phase: CyclePhase.ovulation, note: 'Estimated peak energy phase'),
    DayRecommendation(dayLabel: 'Sun', sessionType: 'Active recovery', distanceRange: '3–5 km', intensity: 1, phase: CyclePhase.ovulation, note: 'Keep it gentle after long run'),
    DayRecommendation(dayLabel: 'Mon', sessionType: 'Speed intervals', distanceRange: '6–10 km', intensity: 4, phase: CyclePhase.luteal, note: 'Early luteal — still good for quality'),
    DayRecommendation(dayLabel: 'Tue', sessionType: 'Steady-state run', distanceRange: '8–10 km', intensity: 3, phase: CyclePhase.luteal, note: 'Moderate effort recommended'),
    DayRecommendation(dayLabel: 'Wed', sessionType: 'Rest day', distanceRange: 'Recovery', intensity: 0, phase: CyclePhase.luteal, note: 'Full rest supports hormonal balance'),
  ];

  // ── Science Facts ────────────────────────────────────────────────────────
  static const List<ScienceFact> scienceFacts = [
    ScienceFact(
      emoji: '🧬',
      tag: 'Physiology',
      body: 'Oestrogen may act as an anabolic agent, supporting muscle protein synthesis. Some research suggests female athletes recover differently across cycle phases — though individual responses vary enormously.',
      cardColor: Color(0xFFFDF5F7),
    ),
    ScienceFact(
      emoji: '🩸',
      tag: 'RED-S Awareness',
      body: 'Relative Energy Deficiency in Sport (RED-S) affects female runners at all levels. Under-fuelling impairs hormonal function, bone health, and performance — often invisibly at first.',
      cardColor: Color(0xFFF5F9F7),
    ),
    ScienceFact(
      emoji: '❤️',
      tag: 'Heart health',
      body: 'Female athletes show distinct cardiac adaptations to endurance training. Studies suggest oestrogen may have cardioprotective effects, though the mechanisms are still being actively researched.',
      cardColor: Color(0xFFF8F5FD),
    ),
    ScienceFact(
      emoji: '🦴',
      tag: 'Bone health',
      body: 'Bone density in female runners is influenced by training load, nutrition, and hormonal status. Running supports bone health, but energy availability matters significantly.',
      cardColor: Color(0xFFF5F9F0),
    ),
    ScienceFact(
      emoji: '😴',
      tag: 'Sleep & recovery',
      body: 'Research indicates that women may experience more sleep disruption in the luteal phase due to rising progesterone. Prioritising sleep during this phase may support recovery and mood.',
      cardColor: Color(0xFFFDF8F3),
    ),
    ScienceFact(
      emoji: '🏃‍♀️',
      tag: 'Research history',
      body: 'Until the 1990s, most exercise science research excluded women. Female performance science is growing rapidly — you are part of that movement by participating in research platforms.',
      cardColor: Color(0xFFF0F5FD),
    ),
    ScienceFact(
      emoji: '🧠',
      tag: 'Neuroscience',
      body: 'Brain regions governing effort perception and mood are influenced by oestrogen and progesterone. This may partly explain why perceived exertion can fluctuate across the cycle.',
      cardColor: Color(0xFFFDF5F0),
    ),
    ScienceFact(
      emoji: '💧',
      tag: 'Hydration',
      body: 'Plasma volume and thermoregulation shift across the menstrual cycle. Some athletes find they need slightly more fluid in the late luteal phase when core temperature is slightly elevated.',
      cardColor: Color(0xFFF5FDF8),
    ),
  ];
}