import 'package:flutter/material.dart';
import '../services/run_repository.dart';
import '../themes/app_theme.dart';

/// Small card prompting the athlete to enter their last period date so cycle
/// phases can be estimated for their runs. Shown until a cycle is set.
class CycleSetupCard extends StatelessWidget {
  const CycleSetupCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: FemoraTheme.lavender),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set your cycle',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Add your last period date to personalise phase insights.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => showCycleSetupSheet(context),
              child: const Text('Set'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to capture last-period date + average cycle length, saving into
/// [RunRepository] (which triggers a re-sync).
Future<void> showCycleSetupSheet(BuildContext context) async {
  DateTime selected = RunRepository.instance.lastPeriodStart ?? DateTime.now();
  int length = RunRepository.instance.cycleLength;

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
            Text('Your cycle', style: Theme.of(ctx).textTheme.displaySmall),
            const SizedBox(height: 4),
            Text(
              'Used only to estimate your cycle phase — never a hormone measurement.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Last period start'),
              subtitle: Text(
                  '${selected.day}/${selected.month}/${selected.year}'),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: selected,
                  firstDate: DateTime.now().subtract(const Duration(days: 90)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setSheet(() => selected = picked);
              },
            ),
            const SizedBox(height: 12),
            Text('Average cycle length: $length days',
                style: Theme.of(ctx).textTheme.bodyMedium),
            Slider(
              value: length.toDouble(),
              min: 21,
              max: 35,
              divisions: 14,
              label: '$length',
              onChanged: (v) => setSheet(() => length = v.round()),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await RunRepository.instance.setCycle(selected, length);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
