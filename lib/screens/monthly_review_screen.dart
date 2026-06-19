import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../themes/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/analytics.dart';
import '../services/run_repository.dart';

class MonthlyReviewScreen extends StatelessWidget {
  const MonthlyReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RunRepository.instance,
      builder: (context, _) {
        final repo = RunRepository.instance;
        final now = DateTime.now();
        final from = now.subtract(const Duration(days: 30));
        final runs =
            repo.runs.where((r) => r.date.isAfter(from)).toList();

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Your last 30 days',
                    style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 4),
                const Text('A look back at your recent running',
                    style: TextStyle(
                        fontSize: 14, color: FemoraTheme.warmText)),
                const SizedBox(height: 20),
                if (runs.isEmpty)
                  const _EmptyReview()
                else ...[
                  _TopStats(runs: runs),
                  const SizedBox(height: 16),
                  _WeeklyCard(runs: runs, now: now),
                  const SizedBox(height: 12),
                  _PaceByPhaseCard(runs: runs),
                  const SizedBox(height: 16),
                  _ShareCard(summary: _summary(runs)),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  String _summary(List<RunEntry> runs) {
    final km = Analytics.totalKm(runs);
    final pace = Analytics.avgPaceMinPerKm(runs);
    final paceStr = pace != null ? '${Analytics.formatPace(pace)}/km' : '–';
    return 'My last 30 days on SOMA Connect 🏃‍♀️\n'
        '${km.toStringAsFixed(1)} km · ${runs.length} runs · avg ${paceStr}\n'
        'Training with my cycle. #SOMAConnect';
  }
}

class _EmptyReview extends StatelessWidget {
  const _EmptyReview();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.calendar_month_outlined,
                size: 40, color: FemoraTheme.warmText),
            const SizedBox(height: 12),
            Text('Nothing to review yet',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Once you upload some runs, your monthly recap — distance, pace and your strongest phase — shows up here, ready to share.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopStats extends StatelessWidget {
  final List<RunEntry> runs;
  const _TopStats({required this.runs});

  @override
  Widget build(BuildContext context) {
    final km = Analytics.totalKm(runs);
    final fastest = runs
        .where((r) => r.distanceKm > 0)
        .map((r) => r.paceMinPerKm)
        .fold<double?>(null, (best, p) => best == null || p < best ? p : best);
    return Row(
      children: [
        Expanded(
            child: _MonthStat(
                number: km.toStringAsFixed(0), label: 'km logged')),
        const SizedBox(width: 10),
        Expanded(
            child: _MonthStat(
                number: '${runs.length}', label: 'runs completed')),
        const SizedBox(width: 10),
        Expanded(
            child: _MonthStat(
                number:
                    fastest != null ? Analytics.formatPace(fastest) : '–',
                label: 'fastest pace')),
      ],
    );
  }
}

class _MonthStat extends StatelessWidget {
  final String number;
  final String label;
  const _MonthStat({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FemoraTheme.warmGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(number, style: FemoraTheme.serif(fontSize: 24)),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: FemoraTheme.warmText)),
        ],
      ),
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  final List<RunEntry> runs;
  final DateTime now;
  const _WeeklyCard({required this.runs, required this.now});

  @override
  Widget build(BuildContext context) {
    // 4 weekly buckets, oldest (W1) -> most recent (W4 = this week).
    final today = DateTime(now.year, now.month, now.day);
    final totals = List<double>.filled(4, 0);
    for (final r in runs) {
      final daysAgo = today.difference(DateTime(r.date.year, r.date.month, r.date.day)).inDays;
      if (daysAgo < 0 || daysAgo > 27) continue;
      final bucket = 3 - (daysAgo ~/ 7); // 0..3 -> W1..W4
      if (bucket >= 0 && bucket < 4) totals[bucket] += r.distanceKm;
    }
    final maxY = (totals.reduce((a, b) => a > b ? a : b)).clamp(1, 1000) * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('weekly distance (km)'),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY.toDouble(),
                  barGroups: List.generate(4, (i) {
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: totals[i],
                        color: FemoraTheme.rose,
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ]);
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('W${val.toInt() + 1}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: FemoraTheme.warmText)),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (val, meta) => Text(
                          '${val.round()}',
                          style: const TextStyle(
                              fontSize: 10, color: FemoraTheme.warmText),
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
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                          color: FemoraTheme.warmBorder,
                          strokeWidth: 0.5)),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text('W4 is this week.',
                style:
                    TextStyle(fontSize: 11, color: FemoraTheme.warmText)),
          ],
        ),
      ),
    );
  }
}

class _PaceByPhaseCard extends StatelessWidget {
  final List<RunEntry> runs;
  const _PaceByPhaseCard({required this.runs});

  @override
  Widget build(BuildContext context) {
    final stats = Analytics.phaseCorrelation(runs);
    final phases = CyclePhase.values;
    final paces =
        phases.map((p) => stats[p]!['avgPace'] as double?).toList();
    final withData = paces.where((p) => p != null).cast<double>().toList();
    if (withData.isEmpty) return const SizedBox.shrink();
    final maxPace = withData.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('avg pace by cycle phase'),
            const SizedBox(height: 16),
            SizedBox(
              height: 170,
              child: BarChart(
                BarChartData(
                  maxY: maxPace * 1.15,
                  barGroups: phases.asMap().entries.map((e) {
                    final pace = paces[e.key] ?? 0;
                    return BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(
                        toY: pace,
                        color: e.value.backgroundColor,
                        borderSide: BorderSide(
                            color: e.value.textColor, width: 1.5),
                        width: 36,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ]);
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final i = val.toInt();
                          if (i < 0 || i >= phases.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(phases[i].label,
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: FemoraTheme.warmText)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (val, meta) => Text(
                          val.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 10, color: FemoraTheme.warmText),
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
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                          color: FemoraTheme.warmBorder,
                          strokeWidth: 0.5)),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Lower bars = faster average pace.',
                style:
                    TextStyle(fontSize: 11, color: FemoraTheme.warmText)),
          ],
        ),
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final String summary;
  const _ShareCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FemoraTheme.roseLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FemoraTheme.roseMid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Share your recap',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(summary,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: summary));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Recap copied — paste it anywhere to share.'),
                ));
              }
            },
            icon: const Icon(Icons.ios_share, size: 18),
            label: const Text('Copy to share'),
          ),
        ],
      ),
    );
  }
}
