import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../themes/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/analytics.dart';
import '../services/run_repository.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RunRepository.instance,
      builder: (context, _) {
        final repo = RunRepository.instance;
        final runs = repo.runs;

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Your performance insights',
                    style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 4),
                const Text(
                    'Patterns in your personal data — not population averages',
                    style: TextStyle(
                        fontSize: 14, color: FemoraTheme.warmText)),
                const SizedBox(height: 20),

                if (runs.isEmpty)
                  const _EmptyState()
                else ...[
                  if (!repo.hasCycle) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FemoraTheme.warmGray,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Set your last period date on the Home tab to unlock your pace-by-phase patterns below.',
                        style:
                            TextStyle(fontSize: 13, color: FemoraTheme.ink),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _PhaseCard(stats: Analytics.phaseCorrelation(runs)),
                  const SizedBox(height: 12),
                  _ScatterCard(repo: repo, runs: runs),
                  const SizedBox(height: 12),
                ],

                const DisclaimerBox(
                  'These correlations are observed in your logged training data and estimated cycle phases. Hormone levels are not directly measured. Correlation does not imply causation.',
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.insights_outlined,
                size: 40, color: FemoraTheme.warmText),
            const SizedBox(height: 12),
            Text('No insights yet',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Connect Strava and set your cycle date on the Home tab. Once your runs sync, your pace-by-phase patterns appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Phase performance card ──────────────────────────────────────────────────
class _PhaseCard extends StatelessWidget {
  final Map<CyclePhase, Map<String, dynamic>> stats;
  const _PhaseCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    // Fastest phase (lowest avg pace) among phases that have runs.
    CyclePhase? best;
    double? bestPace;
    stats.forEach((p, s) {
      final ap = s['avgPace'] as double?;
      if (ap != null && (bestPace == null || ap < bestPace!)) {
        bestPace = ap;
        best = p;
      }
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('pace vs estimated phase'),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: FemoraTheme.warmBorder)),
                  ),
                  children: ['Phase', 'Avg pace', 'Runs']
                      .map((h) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(h,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: FemoraTheme.warmText,
                                    letterSpacing: 0.6)),
                          ))
                      .toList(),
                ),
                ...CyclePhase.values.map((phase) {
                  final s = stats[phase]!;
                  final ap = s['avgPace'] as double?;
                  final isBest = phase == best && best != null;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: isBest
                          ? FemoraTheme.sageLight.withValues(alpha: 0.6)
                          : Colors.transparent,
                    ),
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        child: PhaseBadge(phase, fontSize: 11),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          ap != null
                              ? '${Analytics.formatPace(ap)} /km'
                              : '–',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: isBest
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: FemoraTheme.ink),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        child: Text('${s['runs']}',
                            style: const TextStyle(
                                fontSize: 13,
                                color: FemoraTheme.warmText)),
                      ),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              best != null
                  ? 'Your fastest average pace so far is in your ${best!.label.toLowerCase()} phase. Individual variation is expected.'
                  : 'Keep logging runs across your cycle to reveal your pattern.',
              style: const TextStyle(
                  fontSize: 11,
                  color: FemoraTheme.warmText,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scatter: pace vs cycle day ──────────────────────────────────────────────
class _ScatterCard extends StatelessWidget {
  final RunRepository repo;
  final List<RunEntry> runs;
  const _ScatterCard({required this.repo, required this.runs});

  @override
  Widget build(BuildContext context) {
    final est = repo.estimator;
    final cycleLength = repo.cycleLength.toDouble();
    final spots = <ScatterSpot>[];
    if (est != null) {
      for (final r in runs) {
        spots.add(ScatterSpot(
          est.cycleDayFor(r.date).toDouble(),
          r.paceMinPerKm,
          dotPainter: FlDotCirclePainter(
            radius: 5,
            color: FemoraTheme.rose.withValues(alpha: 0.55),
            strokeColor: FemoraTheme.rose,
            strokeWidth: 1.5,
          ),
        ));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('pace across your cycle'),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: ScatterChart(
                ScatterChartData(
                  minX: 1,
                  maxX: cycleLength,
                  scatterSpots: spots,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) => Text(
                          '${val.round()}',
                          style: const TextStyle(
                              fontSize: 10,
                              color: FemoraTheme.warmText),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (val, meta) => Text(
                          val.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 10,
                              color: FemoraTheme.warmText),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (_) => FlLine(
                        color: FemoraTheme.warmBorder, strokeWidth: 0.5),
                    getDrawingVerticalLine: (_) => FlLine(
                        color: FemoraTheme.warmBorder, strokeWidth: 0.5),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Each dot is a run: pace (min/km, lower = faster) against your estimated cycle day.',
              style: TextStyle(fontSize: 12, color: FemoraTheme.warmText),
            ),
          ],
        ),
      ),
    );
  }
}
