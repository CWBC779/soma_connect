import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'cycle_estimator.dart';
import 'strava_service.dart';

/// Single source of truth for the athlete's runs + cycle + weekly goal.
///
/// There is NO demo data: if Strava isn't connected (or there are no runs),
/// `runs` is empty and screens show an explicit empty state. Only real,
/// fetched data is ever shown.
class RunRepository extends ChangeNotifier {
  RunRepository._();
  static final RunRepository instance = RunRepository._();

  static const _kLastPeriod = 'cycle_last_period';
  static const _kCycleLength = 'cycle_length';
  static const _kWeeklyGoal = 'weekly_goal_km';

  List<RunEntry> _runs = const [];
  bool _loading = false;
  bool _connected = false;
  DateTime? _lastPeriodStart;
  int _cycleLength = 28;
  double _weeklyGoalKm = 30;

  List<RunEntry> get runs => _runs;
  bool get hasData => _runs.isNotEmpty;
  bool get loading => _loading;
  bool get connected => _connected;
  DateTime? get lastPeriodStart => _lastPeriodStart;
  int get cycleLength => _cycleLength;
  bool get hasCycle => _lastPeriodStart != null;
  double get weeklyGoalKm => _weeklyGoalKm;

  CycleEstimator? get estimator => _lastPeriodStart == null
      ? null
      : CycleEstimator(
          lastPeriodStart: _lastPeriodStart!, cycleLength: _cycleLength);

  int? get cycleDayToday => estimator?.cycleDayFor(DateTime.now());
  CyclePhase? get phaseToday => estimator?.phaseFor(DateTime.now());

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final iso = p.getString(_kLastPeriod);
    _lastPeriodStart = iso == null ? null : DateTime.tryParse(iso);
    _cycleLength = p.getInt(_kCycleLength) ?? 28;
    _weeklyGoalKm = p.getDouble(_kWeeklyGoal) ?? 30;
    notifyListeners();
    await refresh();
  }

  Future<void> setCycle(DateTime start, int length) async {
    final p = await SharedPreferences.getInstance();
    _lastPeriodStart = DateTime(start.year, start.month, start.day);
    _cycleLength = length;
    await p.setString(_kLastPeriod, _lastPeriodStart!.toIso8601String());
    await p.setInt(_kCycleLength, length);
    notifyListeners();
    await refresh();
  }

  Future<void> setWeeklyGoal(double km) async {
    final p = await SharedPreferences.getInstance();
    _weeklyGoalKm = km;
    await p.setDouble(_kWeeklyGoal, km);
    notifyListeners();
  }

  /// Pull real runs if connected + a cycle anchor is set; otherwise clear.
  Future<void> refresh() async {
    _connected = await StravaService.instance.isConnected();
    if (_connected && estimator != null) {
      _loading = true;
      notifyListeners();
      final fetched =
          await StravaService.instance.fetchRuns(estimator!, perPage: 100);
      fetched.sort((a, b) => b.date.compareTo(a.date));
      _runs = fetched;
      _loading = false;
      notifyListeners();
    } else {
      if (_runs.isNotEmpty) _runs = const [];
      notifyListeners();
    }
  }
}
