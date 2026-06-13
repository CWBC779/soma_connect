import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../data/sample_data.dart';
import '../themes/app_theme.dart';
import '../widgets/shared_widgets.dart';

class MonthlyReviewScreen extends StatelessWidget {
  const MonthlyReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Header ───────────────────────────────────────────────
            Text('Your May 2025',
                style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            const Text('A look back at your strongest month yet',
                style:
                    TextStyle(fontSize: 14, color: FemoraTheme.warmText)),

            const SizedBox(height: 20),

            // ── Top Stats ────────────────────────────────────────────
            Row(
              children: const [
                Expanded(child: _MonthStat(number: '142', label: 'km logged', highlight: '↑ +12% vs April')),
                SizedBox(width: 10),
                Expanded(child: _MonthStat(number: '19', label: 'runs completed')),
                SizedBox(width: 10),
                Expanded(child: _MonthStat(number: '4:51', label: 'fastest 5km', highlight: 'Personal best ✦')),
              ],
            ),

            const SizedBox(height: 16),

            // ── Weekly Distance Chart ─────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('weekly distance (km)'),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _WeeklyBarChart(
                          summaries: SampleData.weeklySummaries),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Pace by Phase Chart ───────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('pace by cycle phase — may'),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: _PaceByPhaseChart(
                          stats: SampleData.phaseStats),
                    ),
                    const SizedBox(height: 12),
                    const InsightBanner(
                      text: 'You ran an estimated 18% faster during your follicular and ovulation phases compared to your luteal phase. This pattern was consistent across 4 weeks.',
                      emoji: '✦',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Mini Stats ────────────────────────────────────────────
            Row(
              children: const [
                Expanded(
                  child: MetricTile(
                    value: '3.2',
                    unit: 'hrs',
                    label: 'zone 4+ training',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: MetricTile(
                    value: '7.4',
                    unit: 'avg',
                    label: 'sleep quality score',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Share Banner ──────────────────────────────────────────
            _ShareBanner(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Month Stat Tile ────────────────────────────────────────────────────────
class _MonthStat extends StatelessWidget {
  final String number;
  final String label;
  final String? highlight;

  const _MonthStat({
    required this.number,
    required this.label,
    this.highlight,
  });

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
          Text(
            number,
            style: FemoraTheme.serif(fontSize: 26),
          ),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: FemoraTheme.warmText)),
          if (highlight != null) ...[
            const SizedBox(height: 4),
            Text(highlight!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: FemoraTheme.rose)),
          ],
        ],
      ),
    );
  }
}

// ── Weekly Bar Chart ───────────────────────────────────────────────────────
class _WeeklyBarChart extends StatelessWidget {
  final List<WeekSummary> summaries;

  const _WeeklyBarChart({required this.summaries});

  @override
  Widget build(BuildContext context) {
    final maxKm =
        summaries.map((s) => s.totalKm).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxKm + 10,
        barGroups: summaries.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final isBest = s.totalKm == maxKm;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: s.totalKm,
                color: isBest ? FemoraTheme.rose : FemoraTheme.roseMid,
                width: 36,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final i = val.toInt();
                if (i < summaries.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(summaries[i].label,
                        style: const TextStyle(
                            fontSize: 11, color: FemoraTheme.warmText)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (val, meta) => Text(
                '${val.round()}',
                style: const TextStyle(
                    fontSize: 10, color: FemoraTheme.warmText),
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: FemoraTheme.warmBorder,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

// ── Pace by Phase Chart ────────────────────────────────────────────────────
class _PaceByPhaseChart extends StatelessWidget {
  final Map<CyclePhase, Map<String, dynamic>> stats;

  const _PaceByPhaseChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final phases = CyclePhase.values;

    return BarChart(
      BarChartData(
        minY: 4.7,
        maxY: 5.7,
        barGroups: phases.asMap().entries.map((entry) {
          final i = entry.key;
          final phase = entry.value;
          final pace = stats[phase]!['avgPace'] as double;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: pace,
                fromY: 4.7,
                color: phase.backgroundColor,
                borderSide:
                    BorderSide(color: phase.textColor, width: 1.5),
                width: 40,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final i = val.toInt();
                if (i < phases.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(phases[i].label,
                        style: const TextStyle(
                            fontSize: 10, color: FemoraTheme.warmText)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (val, meta) {
                final mins = val.floor();
                final secs = ((val - mins) * 60).round();
                return Text(
                  '$mins:${secs.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontSize: 10, color: FemoraTheme.warmText),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: FemoraTheme.warmBorder,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

// ── Share Banner ───────────────────────────────────────────────────────────
class _ShareBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FemoraTheme.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'May looked great on you',
            style: FemoraTheme.serif(fontSize: 22, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            '142km · 19 runs · a new personal best\nStrongest phase: follicular',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color: Colors.white60,
                height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Share card generated! (Implement share_plus in the full build)'),
                  backgroundColor: FemoraTheme.rose,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FemoraTheme.rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('✦  Share your review',
                style: TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}