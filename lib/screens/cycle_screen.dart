import 'package:flutter/material.dart';
import '../services/run_repository.dart';
import '../themes/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// Dedicated cycle page: log period starts and see a calendar where each day is
/// shaded by activity intensity (km run), with period-start days ringed.
class CycleScreen extends StatefulWidget {
  const CycleScreen({super.key});

  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends State<CycleScreen> {
  late DateTime _month;
  int? _len;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month);
  }

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_month.year, _month.month + 1);
    if (next.isBefore(DateTime(now.year, now.month + 1))) {
      setState(() => _month = next);
    }
  }

  Future<void> _logPeriod() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'When did your period start?',
    );
    if (picked != null) {
      await RunRepository.instance.logPeriodStart(picked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Period start logged.'),
        ));
      }
    }
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RunRepository.instance,
      builder: (context, _) {
        final repo = RunRepository.instance;
        final daily = repo.dailyKm();
        final maxKm =
            daily.values.fold<double>(0, (m, v) => v > m ? v : m);
        final periodSet = repo.periodStarts
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet();
        final len = _len ?? repo.cycleLength;

        return Scaffold(
          appBar: AppBar(title: const Text('Your cycle')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _logPeriod,
                  icon: const Icon(Icons.water_drop_outlined),
                  label: const Text('Log period start'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                repo.hasCycle
                    ? 'Last period: ${_fmt(repo.lastPeriodStart!)} · Day ${repo.cycleDayToday} (${repo.phaseToday?.label})'
                    : 'No period logged yet — tap above to add your last period start.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),

              const SectionLabel('average cycle length'),
              const SizedBox(height: 6),
              Text('$len days',
                  style: Theme.of(context).textTheme.bodyMedium),
              Slider(
                value: len.toDouble(),
                min: 21,
                max: 35,
                divisions: 14,
                label: '$len',
                onChanged: (v) => setState(() => _len = v.round()),
                onChangeEnd: (v) =>
                    RunRepository.instance.setCycleLength(v.round()),
              ),
              const SizedBox(height: 12),

              _CalendarCard(
                month: _month,
                daily: daily,
                maxKm: maxKm <= 0 ? 1 : maxKm,
                periodSet: periodSet,
                onPrev: _prevMonth,
                onNext: _nextMonth,
              ),
              const SizedBox(height: 12),
              const _Legend(),
              const SizedBox(height: 12),
              const DisclaimerBox(
                'Cycle phases are estimated from your logged period dates, not hormone measurements. Day shading shows your running distance.',
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime month;
  final Map<DateTime, double> daily;
  final double maxKm;
  final Set<DateTime> periodSet;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _CalendarCard({
    required this.month,
    required this.daily,
    required this.maxKm,
    required this.periodSet,
    required this.onPrev,
    required this.onNext,
  });

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1..7
    final leading = firstWeekday - 1;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final km = daily[date] ?? 0;
      final intensity = (km / maxKm).clamp(0.0, 1.0);
      final isPeriod = periodSet.contains(date);
      final isToday = date == todayKey;
      final filled = km > 0;
      final bg = filled
          ? FemoraTheme.rose.withValues(alpha: 0.18 + 0.82 * intensity)
          : FemoraTheme.warmGray;
      final textColor = (filled && intensity > 0.5)
          ? Colors.white
          : FemoraTheme.ink;

      cells.add(Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPeriod
                ? FemoraTheme.sage
                : (isToday ? FemoraTheme.ink : Colors.transparent),
            width: isPeriod ? 2 : (isToday ? 1.5 : 0),
          ),
        ),
        alignment: Alignment.center,
        child: Text('$d',
            style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                color: textColor)),
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: onPrev,
                    icon: const Icon(Icons.chevron_left)),
                Text('${_months[month.month - 1]} ${month.year}',
                    style: Theme.of(context).textTheme.headlineMedium),
                IconButton(
                    onPressed: onNext,
                    icon: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: _weekdays
                  .map((w) => Expanded(
                        child: Center(
                          child: Text(w,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: FemoraTheme.warmText)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: cells,
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Less',
            style: TextStyle(fontSize: 11, color: FemoraTheme.warmText)),
        const SizedBox(width: 6),
        ...List.generate(5, (i) {
          return Container(
            width: 18,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: FemoraTheme.rose.withValues(alpha: 0.18 + 0.82 * (i / 4)),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
        const SizedBox(width: 6),
        const Text('More km',
            style: TextStyle(fontSize: 11, color: FemoraTheme.warmText)),
        const Spacer(),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: FemoraTheme.sage, width: 2),
          ),
        ),
        const SizedBox(width: 4),
        const Text('Period',
            style: TextStyle(fontSize: 11, color: FemoraTheme.warmText)),
      ],
    );
  }
}
