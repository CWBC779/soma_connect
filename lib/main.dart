import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/run_repository.dart';
import 'services/strava_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/training_plan_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/monthly_review_screen.dart';
import 'screens/science_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/consent_screen.dart';
import 'screens/all_set_screen.dart';
import 'themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const MyApp());
}

SupabaseClient get supabase => Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: FemoraTheme.theme,
      home: const AppEntry(),
    );
  }
}

/// Routes: splash → welcome/connect-Strava → (consent) → app, driven by the
/// Supabase session. Connecting Strava is the sign-in.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  StreamSubscription<AuthState>? _sub;
  bool _loading = true;
  bool _signedIn = false;
  bool _consented = false;
  bool _seenDone = false;
  bool _handlingCode = false;

  @override
  void initState() {
    super.initState();
    _evaluate();
    _sub = supabase.auth.onAuthStateChange.listen((_) => _evaluate());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _evaluate() async {
    // Handle the Strava OAuth return (?code). Single-use — guard re-entry.
    final code = Uri.base.queryParameters['code'];
    if (code != null && code.isNotEmpty && !_handlingCode) {
      _handlingCode = true;
      try {
        if (supabase.auth.currentSession == null) {
          final prefs = await SharedPreferences.getInstance();
          final consent = <String, dynamic>{};
          if (prefs.getBool('pending_consent') == true) {
            consent['consent_version'] = 'v1';
          }
          final age = prefs.getString('pending_age_range');
          if (age != null) consent['age_range'] = age;
          final lvl = prefs.getString('pending_training_level');
          if (lvl != null) consent['training_level'] = lvl;
          final cl = prefs.getInt('pending_cycle_length');
          if (cl != null) consent['cycle_length'] = cl;
          await StravaService.instance.loginWithStrava(code, consent);
        } else {
          // Already signed in; just reload (Strava is login-only now).
          await RunRepository.instance.refresh();
        }
      } finally {
        _handlingCode = false;
      }
    }

    final session = supabase.auth.currentSession;
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _signedIn = false;
        _consented = false;
        _loading = false;
      });
      return;
    }
    bool consented = false;
    try {
      final row = await supabase
          .from('profiles')
          .select('consented_at')
          .eq('user_id', session.user.id)
          .maybeSingle();
      consented = row != null && row['consented_at'] != null;
    } catch (_) {}
    bool seenDone = false;
    if (consented) {
      await RunRepository.instance.init();
      final prefs = await SharedPreferences.getInstance();
      seenDone = prefs.getBool('seen_setup_done') ?? false;
    }
    if (!mounted) return;
    setState(() {
      _signedIn = true;
      _consented = consented;
      _seenDone = seenDone;
      _loading = false;
    });
  }

  Future<void> _completeDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_setup_done', true);
    if (mounted) setState(() => _seenDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SplashScreen();
    if (!_signedIn) return const WelcomeScreen();
    if (!_consented) return ConsentScreen(onConsented: _evaluate);
    if (!_seenDone) return AllSetScreen(onContinue: _completeDone);
    return const AppShell();
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    DashboardScreen(),
    TrainingPlanScreen(),
    InsightsScreen(),
    MonthlyReviewScreen(),
    ScienceScreen(),
  ];

  static const List<String> _labels = <String>[
    'Home',
    'Plan',
    'Insights',
    'Review',
    'Science',
  ];

  static const List<IconData> _icons = <IconData>[
    Icons.home,
    Icons.fitness_center,
    Icons.bar_chart,
    Icons.calendar_month,
    Icons.science,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: List.generate(
          _pages.length,
          (index) => NavigationDestination(
            icon: Icon(_icons[index]),
            label: _labels[index],
          ),
        ),
      ),
    );
  }
}
