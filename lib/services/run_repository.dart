import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/sample_data.dart';
import '../models/models.dart';
import 'cycle_estimator.dart';
import 'strava_service.dart';

/// Single source of truth for the run list the screens render.
///
/// - Until the athlete connects Strava + sets a cycle date, it serves the demo
///   [SampleData.runs] so the UI looks complete.
/// - Once connected with a cycle anchor, it serves real runs fetched from
///   Strava, each tagged with its estimated cycle phase.
///
/// Screens listen to this (it's a [ChangeNotifier]) and rebuild when data
/// changes — e.g. after a sync completes.
class RunRepository extends ChangeNotifier {
  RunRepository._();
  static final RunRepository instance = RunRepository._();

  static const _kLastPeriod = 'cycle_last_period';
  static const _kCycleLength = 'cycle_length';

  List<RunEntry> _runs = SampleData.runs;
  bool _isReal = false;
  bool _loading = false;
  DateTime? _lastPeriodStart;
  int _cycleLength = 28;

  List<RunEntry> get runs => _runs;
  bool get isReal => _isReal;
  bool get loading => _loading;
  DateTime? get lastPeriodStart => _lastPeriodStart;
  int get cycleLength => _cycleLength;
  bool get hasCycle => _lastPeriodStart != null;

  CycleEstimator? get estimator => _lastPeriodStart == null
      ? null
      : CycleEstimator(
          lastPeriodStart: _lastPeriodStart!, cycleLength: _cycleLength);

  int? get cycleDayToday => estimator?.cycleDayFor(DateTime.now());
  CyclePhase? get phaseToday => estimator?.phaseFor(DateTime.now());

  /// Load saved cycle info, then sync from Strava if possible. Safe to call at
  /// app start; does nothing expensive when not connected.
  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final iso = p.getString(_kLastPeriod);
    _lastPeriodStart = iso == null ? null : DateTime.tryParse(iso);
    _cycleLength = p.getInt(_kCycleLength) ?? 28;
    notifyListeners();
    await refresh();
  }

  /// Persist the athlete's cycle anchor and re-sync.
  Future<void> setCycle(DateTime start, int length) async {
    final p = await SharedPreferences.getInstance();
    _lastPeriodStart = DateTime(start.year, start.month, start.day);
    _cycleLength = length;
    await p.setString(_kLastPeriod, _lastPeriodStart!.toIso8601String());
    await p.setInt(_kCycleLength, length);
    notifyListeners();
    await refresh();
  }

  /// Re-evaluate the data source: real runs if connected + cycle set, else demo.
  Future<void> refresh() async {
    if (await StravaService.instance.isConnected()) {
      await _syncFromStrava();
    } else {
      _resetToSample();
    }
  }

  Future<void> _syncFromStrava() async {
    final est = estimator;
    if (est == null) return; // need a cycle anchor to tag phases
    _loading = true;
    notifyListeners();
    final fetched = await StravaService.instance.fetchRuns(est, perPage: 60);
    if (fetched.isNotEmpty) {
      fetched.sort((a, b) => b.date.compareTo(a.date));
      _runs = fetched;
      _isReal = true;
    }
    _loading = false;
    notifyListeners();
  }

  void _resetToSample() {
    if (_isReal) {
      _runs = SampleData.runs;
      _isReal = false;
      notifyListeners();
    }
  }
}
