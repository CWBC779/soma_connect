import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../data/sample_data.dart';
import '../themes/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/strava_connect_button.dart';
import '../services/analytics.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('profile_name');
    setState(() {
      _displayName = name;
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final athlete = SampleData.athlete;
    final name = _displayName ?? athlete.name;

    final now = DateTime.now();
    final dateLabel = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    // live analytics
    final recovery = Analytics.recoveryFromLoad(SampleData.runs, now);
    final readiness = Analytics.readiness(hrv: athlete.hrv.toDouble(), sleepHours: athlete.sleepHours, recovery: recovery);
    final weekKm = Analytics.weeklyLoadKm(SampleData.runs, now);
    final weeklyProgressValue = Analytics.weeklyProgress(SampleData.runs, now, athlete.weeklyGoalKm);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Header ───────────────────────────────────────────────
            Text(
              '${_greeting()}, $name ✦',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 4),
            Text(dateLabel, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              'Day ${athlete.cycleDay} of your cycle',
              style: const TextStyle(
                  fontSize: 14, color: FemoraTheme.warmText),
            ),

            const SizedBox(height: 16),

            // ── Connect Strava ───────────────────────────────────────
            const StravaConnectCard(),

            const SizedBox(height: 20),

            // ── Readiness Card ───────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SectionLabel('activity readiness'),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Circular meter
                        _ActivityMeter(value: readiness),
                        const SizedBox(width: 24),
                        // Right side stats
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionLabel('estimated phase'),
                              const SizedBox(height: 6),
                              PhaseBadge(
                                athlete.currentPhase,
                                customLabel: athlete.currentPhaseLabel,
                              ),
                              const SizedBox(height: 14),
                              ProgressRow(
                                label: 'Recovery',
                                value: recovery,
                                displayValue: '${(recovery * 100).round()}%',
                                barColor: FemoraTheme.sage,
                              ),
                              ProgressRow(
                                label: 'HRV score',
                                value: athlete.hrv / 100,
                                displayValue: '${athlete.hrv.round()}ms',
                                barColor: FemoraTheme.rose,
                              ),
                              ProgressRow(
                                label: 'Sleep',
                                value: athlete.sleepHours / 9,
                                displayValue: '${athlete.sleepHours}h',
                                barColor: FemoraTheme.lavender,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    InsightBanner(
                      text: '${athlete.currentPhaseLabel} is associated with rising energy in many athletes — consider a quality session if you feel up for it.',
                      emoji: '📈',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Quick Metrics ────────────────────────────────────────
            Row(
              children: const [
                Expanded(
                  child: MetricTile(
                    value: '6.2',
                    unit: 'km',
                    label: 'yesterday\'s run',
                    sub: '↑ +8% vs avg',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: MetricTile(
                    value: '5:12',
                    unit: '/km',
                    label: 'average pace',
                    sub: 'Best phase',
                    subColor: FemoraTheme.rose,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Cycle Phase Timeline ─────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('cycle phase — this month'),
                    const SizedBox(height: 12),
                    _CycleTimeline(
                      cycleDay: SampleData.athlete.cycleDay,
                      cycleLength: SampleData.athlete.cycleLength,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Weekly Goal ──────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('weekly goal'),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Target this week',
                            style: TextStyle(
                                fontSize: 13,
                                color: FemoraTheme.warmText)),
                        Text(
                          '${athlete.weeklyGoalKm.round()} km',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: FemoraTheme.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: weeklyProgressValue,
                        backgroundColor: FemoraTheme.warmGray,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            FemoraTheme.rose),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${weekKm.round()} km completed · ${(athlete.weeklyGoalKm - weekKm).round()} km remaining',
                      style: const TextStyle(
                          fontSize: 12, color: FemoraTheme.warmText),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Connect Apps ─────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('connect your data'),
                    const SizedBox(height: 6),
                    const Text(
                      'Sync wearable and cycle tracking apps',
                      style: TextStyle(
                          fontSize: 13, color: FemoraTheme.warmText),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        ConnectButton('⌚ Garmin Connect'),
                        ConnectButton('🍎 Apple Health'),
                        ConnectButton('🔴 Strava'),
                        ConnectButton('🌸 Clue'),
                        ConnectButton('💗 Flo'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            const DisclaimerBox(
              'Research app — not medical advice. Cycle phases are estimated from entered cycle dates, not hormone measurements. For informational and research purposes only.',
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Activity Meter Widget ─────────────────────────────────────────────────
class _ActivityMeter extends StatelessWidget {
  final double value; // 0.0 – 1.0

  const _ActivityMeter({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(120, 120),
            painter: _MeterPainter(value: value),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(value * 100).round()}%',
                style: FemoraTheme.serif(fontSize: 26, fontWeight: FontWeight.w500),
              ),
              const Text(
                'readiness',
                style:
                    TextStyle(fontSize: 11, color: FemoraTheme.warmText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  final double value;
  const _MeterPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    // Track
    final trackPaint = Paint()
      ..color = FemoraTheme.warmGray
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Fill
    final fillPaint = Paint()
      ..color = FemoraTheme.rose
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_MeterPainter old) => old.value != value;
}

// ── Cycle Timeline Widget ─────────────────────────────────────────────────
class _CycleTimeline extends StatelessWidget {
  final int cycleDay;
  final int cycleLength;

  const _CycleTimeline(
      {required this.cycleDay, required this.cycleLength});

  @override
  Widget build(BuildContext context) {
    final phases = CyclePhase.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: phases.map((phase) {
              final isActive = _isActivePhase(phase, cycleDay);
              return Expanded(
                flex: (phase.cycleWeight * 100).round(),
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: phase.backgroundColor,
                    border: isActive
                        ? Border.all(color: FemoraTheme.ink, width: 2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _shortLabel(phase),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: phase.textColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Day 1',
                style: const TextStyle(
                    fontSize: 11, color: FemoraTheme.warmText)),
            Text(
              'Today: Day $cycleDay ↑',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: FemoraTheme.rose),
            ),
            Text('Day $cycleLength',
                style: const TextStyle(
                    fontSize: 11, color: FemoraTheme.warmText)),
          ],
        ),
      ],
    );
  }

  bool _isActivePhase(CyclePhase phase, int day) {
    switch (phase) {
      case CyclePhase.menstrual:
        return day <= 5;
      case CyclePhase.follicular:
        return day > 5 && day <= 13;
      case CyclePhase.ovulation:
        return day > 13 && day <= 16;
      case CyclePhase.luteal:
        return day > 16;
    }
  }

  String _shortLabel(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'Men.';
      case CyclePhase.follicular:
        return 'Foll.';
      case CyclePhase.ovulation:
        return 'Ovul.';
      case CyclePhase.luteal:
        return 'Luteal';
    }
  }
}