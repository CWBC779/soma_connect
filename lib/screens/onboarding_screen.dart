import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';
import 'setup_loading_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  // profile fields
  String _displayName = '';
  int _age = 25;
  int _height = 165;
  int _weight = 60;
  String _trainingLevel = 'Beginner';
  String _goal = 'Stay healthy';
  final List<String> _dietOptions = [
    'None',
    'Vegan',
    'Vegetarian',
    'Pescatarian',
    'Gluten-free',
    'Dairy-free',
    'Diabetic-friendly',
    'Allergy-free',
    'Halal',
    'Kosher',
    'Keto',
    'Low-FODMAP',
    'Other',
  ];
  final Set<String> _dietSelected = {};
  String _dietOther = '';
  bool _consent = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 5) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_page > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _finish() async {
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please give consent to continue.'),
      ));
      return;
    }

    // save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _displayName);
    await prefs.setInt('profile_age', _age);
    await prefs.setInt('profile_height', _height);
    await prefs.setInt('profile_weight', _weight);
    await prefs.setString('profile_trainingLevel', _trainingLevel);
    await prefs.setString('profile_goal', _goal);
    final dietList = [..._dietSelected];
    if (_dietSelected.contains('Other')) dietList.remove('Other');
    if (_dietOther.isNotEmpty) dietList.add(_dietOther);
    await prefs.setStringList('profile_diet', dietList);

    // show loading / processing screen, then complete
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SetupLoadingScreen(onDone: () async {
        final prefs2 = await SharedPreferences.getInstance();
        await prefs2.setBool('hasCompletedOnboarding', true);
        widget.onCompleted();
      }),
    ));
  }

  Widget _numberPicker({required int value, required void Function(int) onChanged, required int min, required int max}) {
    return SizedBox(
      height: 180,
      child: ListWheelScrollView.useDelegate(
        physics: const FixedExtentScrollPhysics(),
        itemExtent: 40,
        diameterRatio: 1.4,
        onSelectedItemChanged: onChanged,
        controller: FixedExtentScrollController(initialItem: value - min),
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            final v = min + index;
            if (v > max) return null;
            return Center(
              child: Text(
                '$v',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemoraTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _buildWelcome(),
                  _buildName(),
                  _buildNumbers(),
                  _buildPreferences(),
                  _buildDiet(),
                  _buildConsent(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton(onPressed: _back, child: const Text('Back')),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FemoraTheme.rose,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(140, 48),
                    ),
                    child: Text(_page < 5 ? 'Next' : 'Finish', style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Welcome to SOMA Connect', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 12),
          Text(
            'This app is for research purposes. SOMA Connect will record your activity levels and menstrual data for analysis. We will request permission to access related apps on your device.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text('Swipe or press Next to continue', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildName() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('How should we call you?', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(labelText: 'Display name', filled: true, fillColor: FemoraTheme.warmGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            onChanged: (v) => _displayName = v.trim(),
          ),
        ],
      ),
    );
  }

  Widget _buildNumbers() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Text('Age', style: Theme.of(context).textTheme.headlineMedium),
          _numberPicker(value: _age, onChanged: (v) => setState(()=> _age = v + 12), min: 12, max: 100),
          const SizedBox(height: 8),
          Text('Height (cm)', style: Theme.of(context).textTheme.headlineMedium),
          _numberPicker(value: _height, onChanged: (v) => setState(()=> _height = v + 120), min: 120, max: 230),
          const SizedBox(height: 8),
          Text('Weight (kg)', style: Theme.of(context).textTheme.headlineMedium),
          _numberPicker(value: _weight, onChanged: (v) => setState(()=> _weight = v + 30), min: 30, max: 160),
        ],
      ),
    );
  }

  Widget _buildPreferences() {
    final goals = ['Stay healthy', 'Improve', 'Challenge yourself', 'Professional competitions'];
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Training level', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: InputDecoration(filled: true, fillColor: FemoraTheme.warmGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _trainingLevel,
                items: const [
                  DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                  DropdownMenuItem(value: 'Intermediate', child: Text('Intermediate')),
                  DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
                  DropdownMenuItem(value: 'Elite', child: Text('Elite')),
                ],
                onChanged: (v) => setState(()=> _trainingLevel = v ?? _trainingLevel),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Goal', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: goals.map((g) {
              final selected = _goal == g;
              return ChoiceChip(label: Text(g), selected: selected, onSelected: (_) => setState(()=> _goal = g));
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDietOption(String option) {
    final selected = _dietSelected.contains(option);
    return CheckboxListTile(
      value: selected,
      title: Text(option),
      onChanged: (v) {
        setState(() {
          if (v == true) {
            _dietSelected.add(option);
          } else {
            _dietSelected.remove(option);
          }
        });
      },
    );
  }

  Widget _buildDiet() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dietary requirements', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                ..._dietOptions.map(_buildDietOption),
                if (_dietSelected.contains('Other'))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Other details', filled: true),
                      onChanged: (v) => _dietOther = v.trim(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Consent', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(value: _consent, onChanged: (v) => setState(()=> _consent = v ?? false)),
              const SizedBox(width: 8),
              Expanded(child: Text('I consent to SOMA Connect collecting my activity and menstrual data for research purposes.'))
            ],
          ),
          const SizedBox(height: 12),
          Text('Privacy note', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Your data will remain private and will not be disclosed publicly. It will be used only for female sports research.', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
