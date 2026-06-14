import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'cycle_estimator.dart';
import 'strava_service.dart';

/// Single source of truth for the screens. Runs are read from the Supabase
/// `runs` table (kept fresh server-side by the Strava webhook + nightly sync).
/// Cycle dates live in the `cycles` table; the weekly goal is a local pref.
class RunRepository extends ChangeNotifier {
  RunRepository._();
  static final RunRepository instance = RunRepository._();

  static const _kWeeklyGoal = 'weekly_goal_km';

  List<RunEntry> _runs = const [];
  bool _loading = false;
  bool _connected = false;
  DateTime? _lastPeriodStart;
  int _cycleLength = 28;
  double _weeklyGoalKm = 30;

  SupabaseClient get _sb => Supabase.instance.client;

  List<RunEntry> get runs => _runs;
  bool get hasData => _runs.isNotEmpty;
  bool get loading => _loading;
  bool get connected => _connected;
  DateTime? get lastPeriodStart => _lastPeriodStart;
  int get cycleLength => _cycleLength;
  bool get hasCycle => _lastPeriodStart != null;
  double get weeklyGoalKm => _weeklyGoalKm;
  String? get lastError => StravaService.instance.lastError;

  CycleEstimator? get estimator => _lastPeriodStart == null
      ? null
      : CycleEstimator(
          lastPeriodStart: _lastPeriodStart!, cycleLength: _cycleLength);

  int? get cycleDayToday => estimator?.cycleDayFor(DateTime.now());
  CyclePhase? get phaseToday => estimator?.phaseFor(DateTime.now());

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _weeklyGoalKm = p.getDouble(_kWeeklyGoal) ?? 30;
    await _loadCycle();
    await refresh();
  }

  Future<void> _loadCycle() async {
    try {
      final uid = _sb.auth.currentUser?.id;
      if (uid == null) return;
      final row = await _sb
          .from('cycles')
          .select()
          .eq('user_id', uid)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row != null) {
        _lastPeriodStart =
            DateTime.tryParse(row['last_period_start'].toString());
        _cycleLength = (row['cycle_length'] as num?)?.toInt() ?? 28;
      }
    } catch (e) {
      debugPrint('load cycle failed: $e');
    }
  }

  /// Reload from the database and refresh connection status (no Strava pull).
  Future<void> refresh() async {
    _connected = await StravaService.instance.isConnected();
    await _loadRunsFromDb();
    notifyListeners();
  }

  /// Pull the latest from Strava into the database, then reload.
  Future<void> syncFromStrava() async {
    _connected = await StravaService.instance.isConnected();
    if (_connected) {
      _loading = true;
      notifyListeners();
      await StravaService.instance.syncNow();
      _loading = false;
    }
    await _loadRunsFromDb();
    notifyListeners();
  }

  Future<void> _loadRunsFromDb() async {
    try {
      final uid = _sb.auth.currentUser?.id;
      if (uid == null) {
        _runs = const [];
        return;
      }
      final rows = await _sb
          .from('runs')
          .select()
          .eq('user_id', uid)
          .order('start_date', ascending: false)
          .limit(500);
      _runs = (rows as List)
          .map(_fromRow)
          .whereType<RunEntry>()
          .toList();
    } catch (e) {
      debugPrint('load runs failed: $e');
    }
  }

  RunEntry? _fromRow(dynamic r) {
    try {
      return RunEntry(
        date: DateTime.parse(r['start_date'].toString()).toLocal(),
        distanceKm: (r['distance_m'] as num).toDouble() / 1000.0,
        duration: Duration(seconds: (r['moving_time_s'] as num).toInt()),
        phase: _phaseFromString(r['estimated_phase'] as String?),
      );
    } catch (_) {
      return null;
    }
  }

  CyclePhase? _phaseFromString(String? s) {
    switch (s) {
      case 'menstrual':
        return CyclePhase.menstrual;
      case 'follicular':
        return CyclePhase.follicular;
      case 'ovulation':
        return CyclePhase.ovulation;
      case 'luteal':
        return CyclePhase.luteal;
      default:
        return null;
    }
  }

  Future<void> setCycle(DateTime start, int length) async {
    _lastPeriodStart = DateTime(start.year, start.month, start.day);
    _cycleLength = length;
    notifyListeners();
    final uid = _sb.auth.currentUser?.id;
    if (uid != null) {
      try {
        await _sb.from('cycles').insert({
          'user_id': uid,
          'last_period_start':
              _lastPeriodStart!.toIso8601String().split('T').first,
          'cycle_length': length,
        });
        await _sb
            .from('profiles')
            .update({'cycle_length': length}).eq('user_id', uid);
      } catch (e) {
        debugPrint('save cycle failed: $e');
      }
    }
    // Re-tag existing runs server-side with the new cycle, then reload.
    await syncFromStrava();
  }

  Future<void> setWeeklyGoal(double km) async {
    final p = await SharedPreferences.getInstance();
    _weeklyGoalKm = km;
    await p.setDouble(_kWeeklyGoal, km);
    notifyListeners();
  }
}
