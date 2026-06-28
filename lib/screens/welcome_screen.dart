import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../themes/app_theme.dart';

const consentVersion = 'v1';

/// Full start-up sequence for a new participant:
/// SOMA → consent info → name → age/height/weight → dietary → consent (18+) +
/// study code. Entering the study code is the sign-in.
///
/// Returning participants who already registered skip all of this via
/// "Already registered? Log in" on the first page — they just re-enter their
/// code and land straight on the dashboard (see [_returningLogin]).
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _page = 0;

  int _age = 25;
  int _height = 165;
  int _weight = 60;
  final Set<String> _diet = {};
  final _dietOtherController = TextEditingController();
  final _codeController = TextEditingController();
  bool _consent = false;
  bool _busy = false;

  static const _dietOptions = [
    'None', 'Vegan', 'Vegetarian', 'Pescatarian', 'Gluten-free',
    'Dairy-free', 'Diabetic-friendly', 'Allergy-free', 'Halal', 'Kosher',
    'Keto', 'Low-FODMAP', 'Other',
  ];

  static const _lastPage = 5;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _dietOtherController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _next() => _pageController.nextPage(
      duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  void _back() => _pageController.previousPage(
      duration: const Duration(milliseconds: 300), curve: Curves.easeOut);

  String _ageRange(int age) {
    if (age < 18) return 'Under 18';
    if (age <= 24) return '18–24';
    if (age <= 34) return '25–34';
    if (age <= 44) return '35–44';
    return '45+';
  }

  Future<void> _join() async {
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please tick the consent box to join.'),
      ));
      return;
    }
    if (_age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This study is for participants aged 18 or over.'),
      ));
      return;
    }
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter your study code.'),
      ));
      return;
    }
    setState(() => _busy = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _nameController.text.trim());
    await prefs.setInt('profile_age', _age);
    await prefs.setInt('profile_height', _height);
    await prefs.setInt('profile_weight', _weight);
    final diet = [..._diet];
    if (diet.contains('Other')) {
      diet.remove('Other');
      final other = _dietOtherController.text.trim();
      if (other.isNotEmpty) diet.add(other);
    }
    await prefs.setStringList('profile_diet', diet);
    await prefs.setBool('seen_setup_done', false);

    final consent = <String, dynamic>{
      'consent_version': consentVersion,
      'age_range': _ageRange(_age),
    };
    final ok = await AuthService.instance.loginWithCode(code, consent);
    if (!ok && mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AuthService.instance.lastError ?? 'Could not sign in.'),
      ));
    }
    // On success, AppEntry detects the new session and routes onward.
  }

  /// Returning participant: re-enter the study code only. We send no consent
  /// fields, so the existing profile (consent, demographics) is left untouched;
  /// the code maps to the same pseudonymous account, so all their data is there.
  Future<void> _returningLogin() async {
    final codeCtrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) {
        bool busy = false;
        String? error;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Log in with your study code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Enter the same code you registered with to pick up where '
                    'you left off.'),
                const SizedBox(height: 12),
                TextField(
                  controller: codeCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Study code',
                    hintText: 'e.g. SOMA-AB12CD',
                    errorText: error,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        final c = codeCtrl.text.trim();
                        if (c.isEmpty) {
                          setLocal(() => error = 'Please enter your code.');
                          return;
                        }
                        setLocal(() {
                          busy = true;
                          error = null;
                        });
                        final ok = await AuthService.instance
                            .loginWithCode(c, const {});
                        if (!ok) {
                          setLocal(() {
                            busy = false;
                            error = AuthService.instance.lastError ??
                                'Invalid study code.';
                          });
                          return;
                        }
                        // Returning users skip the "all set" setup screen.
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('seen_setup_done', true);
                        if (ctx.mounted) Navigator.pop(ctx, c);
                      },
                child: busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Log in'),
              ),
            ],
          ),
        );
      },
    );
    codeCtrl.dispose();
    // On success AppEntry sees the new session and routes to the dashboard.
    if (code != null) setState(() => _busy = true);
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
                  _soma(context),
                  _consentInfo(context),
                  _name(context),
                  _numbers(context),
                  _dietPage(context),
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
                  if (_page < _lastPage)
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

  Widget _soma(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('SOMA',
              style: FemoraTheme.serif(fontSize: 56, color: FemoraTheme.rose)),
          const SizedBox(height: 8),
          Text('Connect',
              style: FemoraTheme.serif(
                  fontSize: 28, color: FemoraTheme.warmText)),
          const SizedBox(height: 20),
          Text(
            'Female performance intelligence — training insights tailored to your cycle.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text('Press Next to get started',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _busy ? null : _returningLogin,
            child: const Text('Already registered? Log in with your code'),
          ),
        ],
      ),
    );
  }

  Widget _consentInfo(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        Text('About this study',
            style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 12),
        Text(
          'SOMA Connect is a research study on how menstrual-cycle phase relates to running performance. You join with a study code from our team, then contribute your running data by uploading the activity export from your sports app (such as Garmin Connect) and by entering your period dates in the app. Everything is stored under a pseudonymous ID.\n\n'
          'Your data is used only for this research, kept confidential, and you can withdraw and request deletion at any time. Cycle phases are estimates from dates, not hormone measurements, and nothing here is medical advice.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _name(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('How should we call you?',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Display name',
              filled: true,
              fillColor: FemoraTheme.warmGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numbers(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Text('Age', style: Theme.of(context).textTheme.headlineMedium),
          _wheel(
              value: _age,
              min: 12,
              max: 100,
              onChanged: (v) => setState(() => _age = v)),
          const SizedBox(height: 8),
          Text('Height (cm)',
              style: Theme.of(context).textTheme.headlineMedium),
          _wheel(
              value: _height,
              min: 120,
              max: 230,
              onChanged: (v) => setState(() => _height = v)),
          const SizedBox(height: 8),
          Text('Weight (kg)',
              style: Theme.of(context).textTheme.headlineMedium),
          _wheel(
              value: _weight,
              min: 30,
              max: 160,
              onChanged: (v) => setState(() => _weight = v)),
        ],
      ),
    );
  }

  Widget _wheel({
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
  }) {
    return SizedBox(
      height: 120,
      child: ListWheelScrollView.useDelegate(
        physics: const FixedExtentScrollPhysics(),
        itemExtent: 40,
        diameterRatio: 1.4,
        controller: FixedExtentScrollController(initialItem: value - min),
        onSelectedItemChanged: (index) => onChanged(min + index),
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            final v = min + index;
            if (v > max) return null;
            return Center(
              child: Text('$v',
                  style: Theme.of(context).textTheme.displaySmall),
            );
          },
        ),
      ),
    );
  }

  Widget _dietPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Dietary requirements',
                style: Theme.of(context).textTheme.displaySmall),
          ),
          Expanded(
            child: ListView(
              children: [
                ..._dietOptions.map((o) => CheckboxListTile(
                      value: _diet.contains(o),
                      title: Text(o),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _diet.add(o);
                        } else {
                          _diet.remove(o);
                        }
                      }),
                    )),
                if (_diet.contains('Other'))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _dietOtherController,
                      decoration: const InputDecoration(
                          labelText: 'Other details'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
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
        Text('Your study code',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text('Enter the code the research team gave you.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        TextField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Study code',
            hintText: 'e.g. SOMA-AB12CD',
            filled: true,
            fillColor: FemoraTheme.warmGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (_) => _join(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _busy ? null : _join,
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Agree & join study'),
          ),
        ),
      ],
    );
  }
}
