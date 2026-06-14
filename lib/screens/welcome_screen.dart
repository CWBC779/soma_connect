import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/strava_service.dart';
import '../themes/app_theme.dart';

const consentVersion = 'v1';

/// Multi-step start-up: intro → about you → consent + Connect with Strava.
/// Connecting Strava IS the sign-in. Cycle is set later on the Cycle page.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _page = 0;
  bool _consent = false;
  bool _busy = false;
  String _ageRange = '25–34';
  String _trainingLevel = 'Recreational';

  static const _ageRanges = ['Under 18', '18–24', '25–34', '35–44', '45+'];
  static const _levels = ['Beginner', 'Recreational', 'Competitive', 'Elite'];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() => _pageController.nextPage(
      duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  void _back() => _pageController.previousPage(
      duration: const Duration(milliseconds: 300), curve: Curves.easeOut);

  Future<void> _connect() async {
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please tick the consent box to join.'),
      ));
      return;
    }
    if (_ageRange == 'Under 18') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This study is for participants aged 18 or over.'),
      ));
      return;
    }
    setState(() => _busy = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pending_consent', true);
    await prefs.setString('pending_age_range', _ageRange);
    await prefs.setString('pending_training_level', _trainingLevel);
    await prefs.setString('profile_name', _nameController.text.trim());
    await prefs.setBool('seen_setup_done', false);
    await StravaService.instance.beginAuthorization();
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
                  _intro(context),
                  _aboutYou(context),
                  _consentPage(context),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton(onPressed: _back, child: const Text('Back')),
                  const Spacer(),
                  if (_page < 2)
                    FilledButton(
                        onPressed: _next, child: const Text('Next')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intro(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        Text('Welcome to SOMA Connect',
            style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 12),
        Text(
          'A research study on how menstrual-cycle phase relates to running performance. You join by connecting Strava — that\'s your secure sign-in, no password needed. We collect your runs (via Strava) and the cycle dates you enter, stored under a pseudonymous ID.\n\n'
          'Your data is used only for this research, kept confidential, and you can withdraw and request deletion at any time. Cycle phases are estimates from dates, not hormone measurements, and nothing here is medical advice.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 14),
        Text(
          '[Placeholder consent text — replace with your IRB/DPIA-approved wording before launch.]',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),
        Text('Press Next to continue',
            style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _aboutYou(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        Text('About you', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 6),
        Text('This helps us personalise your dashboard.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Display name (optional)',
            filled: true,
            fillColor: FemoraTheme.warmGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _dropdown('Age range', _ageRange, _ageRanges,
            (v) => setState(() => _ageRange = v)),
        const SizedBox(height: 12),
        _dropdown('Training level', _trainingLevel, _levels,
            (v) => setState(() => _trainingLevel = v)),
      ],
    );
  }

  Widget _consentPage(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        Text('Consent', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 12),
        Text(
          'By joining you agree to take part in this research and to the collection of your activity and cycle data, as described. You can withdraw any time.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'I am 18 or older and consent to taking part in this research and to the collection of my activity and cycle data.',
                  style: TextStyle(fontSize: 13, color: FemoraTheme.ink),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy ? null : _connect,
            icon: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.directions_run),
            label: const Text('Agree & connect with Strava'),
          ),
        ),
      ],
    );
  }

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: FemoraTheme.warmGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: (v) => onChanged(v ?? value),
        ),
      ),
    );
  }
}
