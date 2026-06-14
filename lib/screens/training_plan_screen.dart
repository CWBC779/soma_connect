import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../themes/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/analytics.dart';
import '../services/run_repository.dart';

const _sessionTypes = [
  'Easy run',
  'Long run',
  'Intervals',
  'Tempo',
  'Recovery',
  'Rest',
  'Cross-train',
];

class _PlanEntry {
  String type;
  int intensity;
  _PlanEntry(this.type, this.intensity);
}

class TrainingPlanScreen extends StatefulWidget {
  const TrainingPlanScreen({super.key});

  @override
  State<TrainingPlanScreen> createState() => _TrainingPlanScreenState();
}

class _TrainingPlanScreenState extends State<TrainingPlanScreen> {
  final Map<String, _PlanEntry> _plan = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('training_plan');
    if (raw == null) return;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    if (!mounted) return;
    setState(() {
      _plan.clear();
      m.forEach((k, v) {
        _plan[k] = _PlanEntry(
            (v['type'] ?? 'Easy run') as String,
            ((v['intensity'] ?? 0) as num).toInt());
      });
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    final m = _plan.map(
        (k, v) => MapEntry(k, {'type': v.type, 'intensity': v.intensity}));
    await p.setString('training_plan', jsonEncode(m));
  }

  Future<void> _editDay(DateTime date) async {
    final key = _key(date);
    final existing = _plan[key];
    String type = existing?.type ?? 'Easy run';
    int intensity = existing?.intensity ?? 2;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FemoraTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan ${_weekday(date)} ${date.day}/${date.month}',
                  style: Theme.of(ctx).textTheme.displaySmall),
              const SizedBox(height: 14),
              const Text('Session',
                  style: TextStyle(
                      fontSize: 12, color: FemoraTheme.warmText)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sessionTypes.map((t) {
                  final selected = t == type;
                  return ChoiceChip(
                    label: Text(t),
                    selected: selected,
                    onSelected: (_) => setSheet(() => type = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Intensity: $intensity / 5',
                  style: Theme.of(ctx).textTheme.bodyMedium),
              Slider(
                value: intensity.toDouble(),
                min: 0,
                max: 5,
                divisions: 5,
                label: '$intensity',
                onChanged: (v) =>
                    setSheet(() => intensity = v.round()),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (existing != null)
                    TextButton(
                      onPressed: () async {
                        setState(() => _plan.remove(key));
                        await _save();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Clear'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      setState(() =>
                          _plan[key] = _PlanEntry(type, intensity));
                      await _save();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _weekday(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RunRepository.instance,
      builder: (context, _) {
        final repo = RunRepository.instance;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final days = List.generate(7, (i) => today.add(Duration(days: i)));
        final weekKm = Analytics.weeklyLoadKm(repo.runs, now);

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Your training plan',
                    style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 4),
                const Text(
                    'Plan your week around your estimated cycle phase',
                    style: TextStyle(
                        fontSize: 14, color: FemoraTheme.warmText)),
                const SizedBox(height: 20),

                _SuggestionCard(repo: repo),
                const SizedBox(height: 16),

                const SectionLabel('plan your next 7 days'),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: days.asMap().entries.map((entry) {
                      final i = entry.key;
                      final date = entry.value;
                      final phase = repo.estimator?.phaseFor(date);
                      final plan = _plan[_key(date)];
                      return Column(
                        children: [
                          _DayRow(
                            label: i == 0 ? 'Today' : _weekday(date),
                            dateLabel: '${date.day}/${date.month}',
                            phase: phase,
                            plan: plan,
                            onTap: () => _editDay(date),
                          ),
                          if (i < days.length - 1)
                            const Divider(
                                height: 1, indent: 16, endIndent: 16),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),
                _WeeklyLoadCard(weekKm: weekKm, goal: repo.weeklyGoalKm),

                const SizedBox(height: 12),
                const DisclaimerBox(
                  "These are your own plans plus pattern-based suggestions, not prescriptions. Your body knows best — adjust to how you feel.",
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

// ── Today's phase-based suggestion ──────────────────────────────────────────
class _SuggestionCard extends StatelessWidget {
  final RunRepository repo;
  const _SuggestionCard({required this.repo});

  @override
  Widget build(BuildContext context) {
    if (!repo.hasCycle) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: FemoraTheme.warmGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Set your last period date on the Home tab to get phase-based suggestions for each day.',
          style: TextStyle(fontSize: 13, color: FemoraTheme.ink),
        ),
      );
    }
    final phase = repo.phaseToday!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FemoraTheme.roseLight,
        border: Border.all(color: FemoraTheme.roseMid, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionLabel('today · day ${repo.cycleDayToday}'),
              const SizedBox(width: 8),
              PhaseBadge(phase, fontSize: 11),
            ],
          ),
          const SizedBox(height: 10),
          Text('Suggested intensity',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          IntensityDots(intensity: phase.suggestedIntensity),
          const SizedBox(height: 10),
          Text(phase.description,
              style: const TextStyle(
                  fontSize: 13, color: FemoraTheme.ink, height: 1.4)),
        ],
      ),
    );
  }
}

// ── A single editable day row ───────────────────────────────────────────────
class _DayRow extends StatelessWidget {
  final String label;
  final String dateLabel;
  final CyclePhase? phase;
  final _PlanEntry? plan;
  final VoidCallback onTap;

  const _DayRow({
    required this.label,
    required this.dateLabel,
    required this.phase,
    required this.plan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: FemoraTheme.ink)),
                  Text(dateLabel,
                      style: const TextStyle(
                          fontSize: 11, color: FemoraTheme.warmText)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan?.type ?? 'Tap to plan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: plan == null
                          ? FemoraTheme.warmText
                          : FemoraTheme.ink,
                    ),
                  ),
                  if (plan != null) ...[
                    const SizedBox(height: 6),
                    IntensityDots(intensity: plan!.intensity, size: 8),
                  ],
                ],
              ),
            ),
            if (phase != null) PhaseBadge(phase!, fontSize: 10),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                size: 18, color: FemoraTheme.warmText),
          ],
        ),
      ),
    );
  }
}

// ── This week's load ────────────────────────────────────────────────────────
class _WeeklyLoadCard extends StatelessWidget {
  final double weekKm;
  final double goal;
  const _WeeklyLoadCard({required this.weekKm, required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = goal <= 0 ? 0.0 : (weekKm / goal).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('this week so far'),
            const SizedBox(height: 10),
            ProgressRow(
              label: 'Distance',
              value: progress,
              displayValue:
                  '${weekKm.toStringAsFixed(1)} / ${goal.round()} km',
              barColor: FemoraTheme.rose,
            ),
          ],
        ),
      ),
    );
  }
}
