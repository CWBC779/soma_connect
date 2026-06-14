import 'package:flutter/foundation.dart';
import 'models.dart';
import '../services/cycle_estimator.dart';

/// A single Strava activity (only the fields we use).
@immutable
class StravaActivity {
  final int id;
  final String name;
  final String type; // 'Run', 'Ride', ...
  final double distanceMeters;
  final int movingTimeSeconds;
  final DateTime startDate; // local time
  final double? averageHeartrate;

  const StravaActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.distanceMeters,
    required this.movingTimeSeconds,
    required this.startDate,
    this.averageHeartrate,
  });

  factory StravaActivity.fromJson(Map<String, dynamic> j) => StravaActivity(
        id: (j['id'] as num).toInt(),
        name: (j['name'] ?? '') as String,
        type: (j['type'] ?? j['sport_type'] ?? '') as String,
        distanceMeters: ((j['distance'] ?? 0) as num).toDouble(),
        movingTimeSeconds: ((j['moving_time'] ?? 0) as num).toInt(),
        startDate: DateTime.parse(j['start_date'] as String).toLocal(),
        averageHeartrate: (j['average_heartrate'] as num?)?.toDouble(),
      );

  bool get isRun => type.toLowerCase().contains('run');

  /// Convert to the app's [RunEntry]. [estimator] may be null — phase stays
  /// null until the athlete sets a cycle date.
  RunEntry toRunEntry(CycleEstimator? estimator) => RunEntry(
        date: startDate,
        distanceKm: distanceMeters / 1000.0,
        duration: Duration(seconds: movingTimeSeconds),
        phase: estimator?.phaseFor(startDate),
      );
}
