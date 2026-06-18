import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../themes/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/cycle_setup_card.dart';
import '../services/analytics.dart';
import '../services/run_repository.dart';
import 'cycle_screen.dart';
import 'upload_screen.dart';

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
    if (!mounted) return;
    setState(() => _displayName = name);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String _fmtDate(DateTime d) {
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RunRepository.instance,
      builder: (context, _) {
        final repo = RunRepository.instance;
        final name = (_displayName != null && _displayName!.isNotEmpty)
            ? _displayName!
            : 'there';

        final now = DateTime.now();
        final dateLabel =
            '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

        final runs = repo.runs;
        final goal = repo.weeklyGoalKm;
        final weekKm = Analytics.weeklyLoadKm(runs, now);
        final progress = Analytics.weeklyProgress(runs, now, goal);
        final latest = Analytics.latest(runs);
        final avgPace = Analytics.avgPaceMinPerKm(runs);

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Header ───────────────────────────────────────────
                Text('${_greeting()}, $name ✦',
                    style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 4),
                Text(dateLabel,
                    style: Theme.of(context).textTheme.bodyMedium),
                if (repo.hasCycle) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Day ${repo.cycleDayToday} · ${repo.phaseToday?.label ?? ''}',
                    style: const TextStyle(
                        fontSize: 14, color: FemoraTheme.warmText),
                  ),
                ],

                if (repo.loading) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 2),
                ],

                const SizedBox(height: 16),

                // ── Cycle setup (if needed) ──────────────────────────
                if (!repo.hasCycle) ...[
                  const CycleSetupCard(),
                  const SizedBox(height: 12),
                ],

                // ── Upload activity data + last-uploaded ─────────────
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UploadScreen()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.upload_file,
                              color: FemoraTheme.sage),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Upload activity data',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium),
                                const SizedBox(height: 2),
                                Text(
                                  repo.lastUploadAt != null
                                      ? 'Last uploaded: ${_fmtDate(repo.lastUploadAt!)}'
                                      : 'No data uploaded yet.',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 18, color: FemoraTheme.warmText),
                        ],
                      ),
                    ),
                  ),
                ),
                if (repo.uploadReminderDue) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: FemoraTheme.amberLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined,
                            size: 18, color: FemoraTheme.amber),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            repo.lastUploadAt == null
                                ? 'Upload your activity export to start contributing your data.'
                                : "It's been over a month since your last upload — please upload your recent activities.",
                            style: const TextStyle(
                                fontSize: 13, color: FemoraTheme.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ── Weekly activity + editable goal ──────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _ActivityMeter(
                              value: progress,
                              centerText: '${(progress * 100).round()}%',
                              label: 'of goal',
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const SectionLabel('this week'),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${weekKm.toStringAsFixed(1)} km',
                                    style: FemoraTheme.serif(fontSize: 26),
                                  ),
                                  Text('of ${goal.round()} km goal',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                  const SizedBox(height: 10),
                                  if (repo.phaseToday != null)
                                    PhaseBadge(repo.phaseToday!),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Weekly goal',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: FemoraTheme.warmText)),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _showWeeklyGoalSheet(context, repo),
                              icon: const Icon(Icons.tune, size: 16),
                              label: Text('${goal.round()} km'),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: FemoraTheme.rose,
                                side: const BorderSide(
                                    color: FemoraTheme.warmBorder),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: FemoraTheme.warmGray,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    FemoraTheme.rose),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${weekKm.toStringAsFixed(1)} km done · ${(goal - weekKm).clamp(0, double.infinity).toStringAsFixed(1)} km to go',
                          style:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Quick metrics (real or "–") ──────────────────────
                Row(
                  children: [
                    Expanded(
                      child: MetricTile(
                        value: latest != null
                            ? latest.distanceKm.toStringAsFixed(1)
                            : '–',
                        unit: 'km',
                        label: 'latest run',
                        sub: latest != null
                            ? '${latest.date.day}/${latest.date.month}'
                            : 'no runs yet',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricTile(
                        value: avgPace != null
                            ? Analytics.formatPace(avgPace)
                            : '–',
                        unit: '/km',
                        label: 'average pace',
                        sub: '${runs.length} runs',
                        subColor: FemoraTheme.rose,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Cycle phase timeline (tap to open Cycle page) ────
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CycleScreen()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const SectionLabel(
                                  'cycle phase — this month'),
                              Row(
                                children: [
                                  if (repo.hasCycle)
                                    Text('Day ${repo.cycleDayToday}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: FemoraTheme.rose)),
                                  const Icon(Icons.chevron_right,
                                      size: 18,
                                      color: FemoraTheme.warmText),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (repo.hasCycle)
                            _CycleTimeline(
                              cycleDay: repo.cycleDayToday ?? 1,
                              cycleLength: repo.cycleLength,
                            )
                          else
                            Text(
                              'Tap to log your last period date and see your estimated cycle phases.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const DisclaimerBox(
                  'Research app — not medical advice. Cycle phases are estimated from entered cycle dates, not hormone measurements. For informational and research purposes only.',
                ),

                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () =>
                        Supabase.instance.client.auth.signOut(),
                    child: const Text('Sign out'),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Bottom sheet to edit the weekly distance goal (syncs the bar live).
Future<void> _showWeeklyGoalSheet(
    BuildContext context, RunRepository repo) async {
  double goal = repo.weeklyGoalKm;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: FemoraTheme.cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly goal',
                style: Theme.of(ctx).textTheme.displaySmall),
            const SizedBox(height: 4),
            Text('How many kilometres do you want to run this week?',
                style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 16),
            Text('${goal.round()} km',
                style: FemoraTheme.serif(fontSize: 30)),
            Slider(
              value: goal,
              min: 5,
              max: 120,
              divisions: 115,
              label: '${goal.round()} km',
              onChanged: (v) => setSheet(() => goal = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await repo.setWeeklyGoal(goal);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save goal'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Activity Meter Widget ─────────────────────────────────────────────────
class _ActivityMeter extends StatelessWidget {
  final double value; // 0.0 – 1.0
  final String centerText;
  final String label;

  const _ActivityMeter({
    required this.value,
    required this.centerText,
    required this.label,
  });

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
              Text(centerText,
                  style: FemoraTheme.serif(
                      fontSize: 26, fontWeight: FontWeight.w500)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: FemoraTheme.warmText)),
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

    final trackPaint = Paint()
      ..color = FemoraTheme.warmGray
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final fillPaint = Paint()
      ..color = FemoraTheme.rose
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final sweepAngle = 2 * math.pi * value.clamp(0.0, 1.0);
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

  const _CycleTimeline({required this.cycleDay, required this.cycleLength});

  @override
  Widget build(BuildContext context) {
    final phases = CyclePhase.values;
    final span = (cycleLength - 1) <= 0 ? 1 : (cycleLength - 1);
    final frac = ((cycleDay - 1) / span).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Marker that moves with the current cycle day.
        SizedBox(
          height: 20,
          width: double.infinity,
          child: Align(
            alignment: Alignment(2 * frac - 1, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Day $cycleDay',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: FemoraTheme.rose)),
                const Icon(Icons.arrow_drop_down,
                    size: 14, color: FemoraTheme.rose),
              ],
            ),
          ),
        ),
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
            const Text('Day 1',
                style:
                    TextStyle(fontSize: 11, color: FemoraTheme.warmText)),
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
