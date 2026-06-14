import 'dart:async';
import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

/// Shown once after a participant connects: a short "setting up" loading phase,
/// then "You're all set" with a Go-to-dashboard button.
class AllSetScreen extends StatefulWidget {
  final VoidCallback onContinue;
  const AllSetScreen({super.key, required this.onContinue});

  @override
  State<AllSetScreen> createState() => _AllSetScreenState();
}

class _AllSetScreenState extends State<AllSetScreen> {
  double _progress = 0;
  bool _done = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 220), (t) {
      setState(() {
        _progress += 0.1;
        if (_progress >= 1.0) {
          _progress = 1.0;
          t.cancel();
          _done = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemoraTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: _done ? _doneView(context) : _loadingView(context),
        ),
      ),
    );
  }

  Widget _loadingView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Setting up your dashboard',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text('Personalising things from what you told us…',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 22),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 12,
            backgroundColor: FemoraTheme.warmGray,
            valueColor:
                const AlwaysStoppedAnimation<Color>(FemoraTheme.rose),
          ),
        ),
        const SizedBox(height: 14),
        Text('${(_progress * 100).round()}%',
            style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
  }

  Widget _doneView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline,
            size: 88, color: FemoraTheme.sage),
        const SizedBox(height: 16),
        Text("You're all set!",
            style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 8),
        Text(
          "We've personalised your dashboard from what you told us. Your runs will sync automatically from Strava.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: widget.onContinue,
          child: const Text('Go to dashboard'),
        ),
      ],
    );
  }
}
