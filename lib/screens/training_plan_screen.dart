import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/sample_data.dart';
import '../themes/app_theme.dart';
import '../widgets/shared_widgets.dart';

class TrainingPlanScreen extends StatelessWidget {
  const TrainingPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Header ───────────────────────────────────────────────
            Text('Your training plan',
                style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            const Text(
                'Based on estimated cycle phase and recovery signals',
                style:
                    TextStyle(fontSize: 14, color: FemoraTheme.warmText)),

            const SizedBox(height: 20),

            // ── Today's Recommendation ───────────────────────────────
            _TodayRecoCard(reco: SampleData.weekPlan.first),

            const SizedBox(height: 16),

            // ── 7-Day Plan ────────────────────────────────────────────
            const SectionLabel('next 7 days'),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: SampleData.weekPlan.asMap().entries.map((entry) {
                  final i = entry.key;
                  final reco = entry.value;
                  return Column(
                    children: [
                      _DayRow(reco: reco, isFirst: i == 0),
                      if (i < SampleData.weekPlan.length - 1)
                        const Divider(
                            height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ── Weekly Load Card ──────────────────────────────────────
            _WeeklyLoadCard(),

            const SizedBox(height: 12),

            const DisclaimerBox(
              "These are suggestions, not prescriptions. Language like 'may,' 'suggests,' and 'consider' is intentional. Your body knows best — these are pattern-based and should not override how you feel.",
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Today's Recommendation Card ────────────────────────────────────────────
class _TodayRecoCard extends StatelessWidget {
  final DayRecommendation reco;

  const _TodayRecoCard({required this.reco});

  @override
  Widget build(BuildContext context) {
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
              const SectionLabel('today · day 12'),
              const SizedBox(width: 8),
              PhaseBadge(reco.phase,
                  customLabel: 'Late follicular', fontSize: 11),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Suggested intensity: High',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: FemoraTheme.ink),
          ),
          const SizedBox(height: 6),
          Text(
            reco.note,
            style: const TextStyle(
                fontSize: 13, color: FemoraTheme.ink, height: 1.5),
          ),
          const SizedBox(height: 12),
          IntensityDots(intensity: reco.intensity),
          const SizedBox(height: 8),
          Text(
            '${reco.sessionType} · ${reco.distanceRange}',
            style: const TextStyle(
                fontSize: 12, color: FemoraTheme.warmText),
          ),
        ],
      ),
    );
  }
}

// ── Day Row ────────────────────────────────────────────────────────────────
class _DayRow extends StatelessWidget {
  final DayRecommendation reco;
  final bool isFirst;

  const _DayRow({required this.reco, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isFirst
          ? FemoraTheme.roseLight.withValues(alpha: 0.3)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Day label
          SizedBox(
            width: 50,
            child: Text(
              reco.dayLabel,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: FemoraTheme.warmText),
            ),
          ),
          // Session details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reco.sessionType,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: FemoraTheme.ink)),
                const SizedBox(height: 2),
                Text(
                  '${reco.phase.label} · ${reco.distanceRange}',
                  style: const TextStyle(
                      fontSize: 11, color: FemoraTheme.warmText),
                ),
              ],
            ),
          ),
          // Intensity dots
          IntensityDots(
            intensity: reco.intensity,
            fillColor: reco.intensity >= 4
                ? FemoraTheme.rose
                : reco.intensity >= 3
                    ? FemoraTheme.lavender
                    : FemoraTheme.sage,
            size: 8,
          ),
        ],
      ),
    );
  }
}

// ── Weekly Load Card ───────────────────────────────────────────────────────
class _WeeklyLoadCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const current = 16.0;
    const goal = 38.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('weekly training load'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Target this week',
                    style: TextStyle(
                        fontSize: 13, color: FemoraTheme.warmText)),
                Text('${goal.round()} km',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: FemoraTheme.ink)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: current / goal,
                backgroundColor: FemoraTheme.warmGray,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    FemoraTheme.rose),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '16 km completed · 22 km remaining',
              style:
                  TextStyle(fontSize: 12, color: FemoraTheme.warmText),
            ),
            const SizedBox(height: 12),
            const InsightBanner(
              text: 'The next 3–5 days may suit higher intensity work based on your estimated cycle phase. This is a pattern observation, not a guarantee.',
              emoji: '💡',
            ),
          ],
        ),
      ),
    );
  }
}