import 'package:flutter/material.dart';
import '../screens/cycle_screen.dart';
import '../themes/app_theme.dart';

/// Prompt shown until the athlete has logged a cycle. Opens the Cycle page.
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
                    'Log your last period to personalise phase insights.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CycleScreen()),
              ),
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }
}
