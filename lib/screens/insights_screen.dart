import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../data/sample_data.dart';
import '../themes/app_theme.dart';
import '../widgets/shared_widgets.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  _MetricMode _selectedMode = _MetricMode.paceVsCycleDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Header ───────────────────────────────────────────────
            Text('Your performance insights',
                style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            const Text(
                'Patterns in your personal data — not population averages',
                style:
                    TextStyle(fontSize: 14, color: FemoraTheme.warmText)),

            const SizedBox(height: 20),

            // ── Phase Performance Table ───────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel(
                        'pace vs estimated phase (last 3 months)'),
                    const SizedBox(height: 12),
                    _PhaseTable(stats: SampleData.phaseStats),
                    const SizedBox(height: 8),
                    const Text(
                      'Phases estimated from cycle dates. Individual variation is expected.',
                      style: TextStyle(
                          fontSize: 11,
                          color: FemoraTheme.warmText,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── HRV Chart ─────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('HRV across cycle phases'),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _HrvChart(stats: SampleData.phaseStats),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Scatter / Explorer ────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('correlation explorer'),
                    const SizedBox(height: 10),
                    // Segmented selector
                    _MetricSelector(
                      selected: _selectedMode,
                      onChanged: (mode) =>
                          setState(() => _selectedMode = mode),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: _ScatterChart(mode: _selectedMode),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedMode.caption,
                      style: const TextStyle(
                          fontSize: 12, color: FemoraTheme.warmText),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            const DisclaimerBox(
              'These correlations are observed in your logged training data and estimated cycle phases. Hormone levels are not directly measured. Correlation does not imply causation.',
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Metric Mode Enum ────────────────────────────────────────────────────────
enum _MetricMode {
  paceVsCycleDay,
  hrvVsCycleDay,
  distanceVsHrv,
}

extension _MetricModeX on _MetricMode {
  String get label {
    switch (this) {
      case _MetricMode.paceVsCycleDay:
        return 'Pace vs day';
      case _MetricMode.hrvVsCycleDay:
        return 'HRV vs day';
      case _MetricMode.distanceVsHrv:
        return 'Distance vs HRV';
    }
  }

  String get caption {
    switch (this) {
      case _MetricMode.paceVsCycleDay:
        return 'Pace (min/km) across cycle days. Lower = faster. Observe faster paces around days 10–16.';
      case _MetricMode.hrvVsCycleDay:
        return 'HRV (ms) across cycle days. Higher HRV typically indicates better recovery readiness.';
      case _MetricMode.distanceVsHrv:
        return 'Run distance plotted against HRV score. Higher HRV days may correspond to longer runs.';
    }
  }
}

// ── Phase Table ────────────────────────────────────────────────────────────
class _PhaseTable extends StatelessWidget {
  final Map<CyclePhase, Map<String, dynamic>> stats;

  const _PhaseTable({required this.stats});

  String _formatPace(double paceDecimal) {
    final mins = paceDecimal.floor();
    final secs = ((paceDecimal - mins) * 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')} /km';
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1),
      },
      children: [
        // Header
        TableRow(
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: FemoraTheme.warmBorder)),
          ),
          children: ['Phase', 'Avg pace', 'vs avg', 'Runs']
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
        // Data rows
        ...CyclePhase.values.map((phase) {
          final s = stats[phase]!;
          final isBest = s['trend'] == 'best';
          return TableRow(
            decoration: BoxDecoration(
              color: isBest
                  ? FemoraTheme.sageLight.withValues(alpha: 0.6)
                  : Colors.transparent,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: PhaseBadge(phase, fontSize: 11),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _formatPace(s['avgPace'] as double),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: isBest
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: FemoraTheme.ink),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _trendLabel(s['trend'] as String),
                  style: TextStyle(
                      fontSize: 12,
                      color: _trendColor(s['trend'] as String)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '${s['runs']}',
                  style: const TextStyle(
                      fontSize: 13, color: FemoraTheme.warmText),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  String _trendLabel(String trend) {
    switch (trend) {
      case 'best':
        return '▲▲ best';
      case 'faster':
        return '▲ faster';
      case 'slower':
        return '▼ slower';
      default:
        return '≈ average';
    }
  }

  Color _trendColor(String trend) {
    switch (trend) {
      case 'best':
      case 'faster':
        return FemoraTheme.sage;
      case 'slower':
        return FemoraTheme.amber;
      default:
        return FemoraTheme.warmText;
    }
  }
}

// ── HRV Chart ──────────────────────────────────────────────────────────────
class _HrvChart extends StatelessWidget {
  final Map<CyclePhase, Map<String, dynamic>> stats;

  const _HrvChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final phases = CyclePhase.values;

    return BarChart(
      BarChartData(
        minY: 40,
        maxY: 90,
        barGroups: phases.asMap().entries.map((entry) {
          final i = entry.key;
          final phase = entry.value;
          final hrv = stats[phase]!['avgHrv'] as double;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: hrv,
                fromY: 40,
                color: phase.backgroundColor,
                borderSide:
                    BorderSide(color: phase.textColor, width: 1.5),
                width: 40,
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
                if (i < phases.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(phases[i].label,
                        style: const TextStyle(
                            fontSize: 10,
                            color: FemoraTheme.warmText)),
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
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: FemoraTheme.warmBorder, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

// ── Metric Selector ────────────────────────────────────────────────────────
class _MetricSelector extends StatelessWidget {
  final _MetricMode selected;
  final ValueChanged<_MetricMode> onChanged;

  const _MetricSelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: FemoraTheme.warmGray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: _MetricMode.values.map((mode) {
          final isSelected = mode == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? FemoraTheme.cardBg
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  mode.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w500
                        : FontWeight.w400,
                    color: isSelected
                        ? FemoraTheme.ink
                        : FemoraTheme.warmText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Scatter Chart ──────────────────────────────────────────────────────────
class _ScatterChart extends StatelessWidget {
  final _MetricMode mode;

  const _ScatterChart({required this.mode});

  List<ScatterSpot> _generateSpots() {
    final rng = math.Random(42);
    switch (mode) {
      case _MetricMode.paceVsCycleDay:
        return List.generate(28, (i) {
          final day = i + 1;
          double base;
          if (day <= 5) {
            base = 5.5;
          } else if (day <= 13) base = 5.1;
          else if (day <= 16) base = 4.97;
          else base = 5.3;
          return ScatterSpot(
            day.toDouble(),
            base + (rng.nextDouble() - 0.5) * 0.2,
          );
        });
      case _MetricMode.hrvVsCycleDay:
        return List.generate(28, (i) {
          final day = i + 1;
          double base;
          if (day <= 5) {
            base = 58;
          } else if (day <= 13) base = 72;
          else if (day <= 16) base = 77;
          else base = 64;
          return ScatterSpot(
            day.toDouble(),
            base + (rng.nextDouble() - 0.5) * 10,
          );
        });
      case _MetricMode.distanceVsHrv:
        return List.generate(30, (_) => ScatterSpot(
          55 + rng.nextDouble() * 25,
          4 + rng.nextDouble() * 9,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = _generateSpots();

    return ScatterChart(
      ScatterChartData(
        scatterSpots: spots
            .map((s) => ScatterSpot(
                  s.x,
                  s.y,
                  dotPainter: FlDotCirclePainter(
                    radius: 5,
                    color: FemoraTheme.rose.withValues(alpha: 0.55),
                    strokeColor: FemoraTheme.rose,
                    strokeWidth: 1.5,
                  ),
                ))
            .toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) => Text(
                '${val.round()}',
                style: const TextStyle(
                    fontSize: 10, color: FemoraTheme.warmText),
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
          getDrawingHorizontalLine: (_) =>
              FlLine(color: FemoraTheme.warmBorder, strokeWidth: 0.5),
          getDrawingVerticalLine: (_) =>
              FlLine(color: FemoraTheme.warmBorder, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}