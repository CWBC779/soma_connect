import 'dart:async';

import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import 'setup_done_screen.dart';

class SetupLoadingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SetupLoadingScreen({super.key, required this.onDone});

  @override
  State<SetupLoadingScreen> createState() => _SetupLoadingScreenState();
}

class _SetupLoadingScreenState extends State<SetupLoadingScreen> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    Timer.periodic(const Duration(milliseconds: 400), (t) {
      setState(() {
        _progress += 0.12;
        if (_progress >= 1.0) {
          t.cancel();
          Future.delayed(const Duration(milliseconds: 400), () {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SetupDoneScreen(onContinue: widget.onDone)));
          });
        }
      });
    });
  }

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
              Text('Uploading & analysing your data', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(value: _progress, minHeight: 12, backgroundColor: FemoraTheme.warmGray, valueColor: const AlwaysStoppedAnimation<Color>(FemoraTheme.rose)),
              ),
              const SizedBox(height: 16),
              Text('${(_progress * 100).clamp(0,100).round()}%', style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}
