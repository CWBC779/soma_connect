import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class SetupDoneScreen extends StatelessWidget {
  final VoidCallback onContinue;
  const SetupDoneScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemoraTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 96, color: Colors.green),
              const SizedBox(height: 16),
              Text('You\'re all set!', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              Text('Welcome to your dashboard — let\'s explore your data.', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onContinue, child: const Text('Go to dashboard')),
            ],
          ),
        ),
      ),
    );
  }
}
