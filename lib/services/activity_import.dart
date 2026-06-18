import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cycle_estimator.dart';
import 'run_repository.dart';

/// Result of parsing an uploaded activity export.
class ImportPreview {
  final List<Map<String, dynamic>> rows;
  final int totalRows;
  final int runs;
  final int skipped;
  final String? error;
  const ImportPreview({
    required this.rows,
    required this.totalRows,
    required this.runs,
    required this.skipped,
    this.error,
  });
}

/// Parses a participant's exported activities CSV (Garmin Connect, Strava bulk
/// export, etc.) into `runs` rows and stores them (source = 'upload').
class ActivityImporter {
  static int _idx(List<String> headers, List<String> keys) {
    for (final k in keys) {
      final i = headers.indexWhere((h) => h.contains(k));
      if (i >= 0) return i;
    }
    return -1;
  }

  static DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;
    final direct = DateTime.tryParse(s);
    if (direct != null) return direct;
    // Try "MM/DD/YYYY" or "DD/MM/YYYY HH:MM:SS" style.
    final m = RegExp(r'(\d{1,4})[/-](\d{1,2})[/-](\d{2,4})').firstMatch(s);
    if (m != null) {
      var a = int.parse(m.group(1)!);
      final b = int.parse(m.group(2)!);
      var c = int.parse(m.group(3)!);
      // Heuristic: if first group is a 4-digit year keep as-is, else assume
      // day/month then year.
      if (a > 1000) {
        return DateTime(a, b, c);
      } else {
        if (c < 100) c += 2000;
        // assume day-first if a > 12
        if (a > 12) return DateTime(c, b, a);
        return DateTime(c, a, b);
      }
    }
    return null;
  }

  static double? _parseDistanceKm(String s) {
    final clean = s.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '');
    final v = double.tryParse(clean);
    return v; // assumed kilometres
  }

  static int? _parseDuration(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    if (t.contains(':')) {
      final parts = t.split(':').map((p) => double.tryParse(p) ?? 0).toList();
      if (parts.length == 3) {
        return (parts[0] * 3600 + parts[1] * 60 + parts[2]).round();
      }
      if (parts.length == 2) {
        return (parts[0] * 60 + parts[1]).round();
      }
    }
    final secs = double.tryParse(t);
    return secs?.round();
  }

  static ImportPreview parseCsv(List<int> bytes) {
    try {
      final text = utf8.decode(bytes, allowMalformed: true);
      final table = const CsvToListConverter(shouldParseNumbers: false, eol: '\n')
          .convert(text.replaceAll('\r\n', '\n'));
      if (table.length < 2) {
        return const ImportPreview(
            rows: [], totalRows: 0, runs: 0, skipped: 0, error: 'No rows found.');
      }
      final headers =
          table.first.map((h) => h.toString().toLowerCase().trim()).toList();
      final dateIdx = _idx(headers, ['date', 'start']);
      final distIdx = _idx(headers, ['distance']);
      final timeIdx =
          _idx(headers, ['moving time', 'elapsed time', 'time', 'duration']);
      final typeIdx = _idx(headers, ['activity type', 'sport', 'type']);
      final hrIdx = _idx(headers, ['avg hr', 'average heart', 'avg heart', 'heart rate']);

      if (dateIdx < 0 || distIdx < 0 || timeIdx < 0) {
        return const ImportPreview(
            rows: [],
            totalRows: 0,
            runs: 0,
            skipped: 0,
            error:
                'Could not find Date / Distance / Time columns. Make sure this is an activities CSV export.');
      }

      final uid = Supabase.instance.client.auth.currentUser?.id;
      final CycleEstimator? est = RunRepository.instance.estimator;

      final rows = <Map<String, dynamic>>[];
      int total = 0, runs = 0, skipped = 0;
      for (var r = 1; r < table.length; r++) {
        final row = table[r];
        if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) {
          continue;
        }
        total++;
        String cell(int i) =>
            (i >= 0 && i < row.length) ? row[i].toString().trim() : '';

        if (typeIdx >= 0 && !cell(typeIdx).toLowerCase().contains('run')) {
          continue; // not a run — ignore quietly
        }
        final date = _parseDate(cell(dateIdx));
        final distKm = _parseDistanceKm(cell(distIdx));
        final secs = _parseDuration(cell(timeIdx));
        if (date == null ||
            distKm == null ||
            distKm <= 0 ||
            secs == null ||
            secs <= 0) {
          skipped++;
          continue;
        }
        runs++;
        final hr = hrIdx >= 0
            ? double.tryParse(cell(hrIdx).replaceAll(RegExp(r'[^0-9.]'), ''))
            : null;
        String? phase;
        int? cycleDay;
        if (est != null) {
          phase = est.phaseFor(date).name;
          cycleDay = est.cycleDayFor(date);
        }
        rows.add({
          'user_id': uid,
          'source': 'upload',
          'external_id':
              '${date.millisecondsSinceEpoch}_${(distKm * 1000).round()}',
          'start_date': date.toUtc().toIso8601String(),
          'distance_m': distKm * 1000,
          'moving_time_s': secs,
          'avg_pace_s_per_km': secs / distKm,
          'avg_heartrate': hr,
          'estimated_phase': phase,
          'estimated_cycle_day': cycleDay,
        });
      }
      return ImportPreview(
          rows: rows, totalRows: total, runs: runs, skipped: skipped);
    } catch (e) {
      return ImportPreview(
          rows: const [], totalRows: 0, runs: 0, skipped: 0, error: '$e');
    }
  }

  /// Upsert parsed rows (skips duplicates from re-uploads). Returns count sent.
  static Future<int> import(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return 0;
    await Supabase.instance.client.from('runs').upsert(
          rows,
          onConflict: 'user_id,source,external_id',
          ignoreDuplicates: true,
        );
    await RunRepository.instance.refresh();
    return rows.length;
  }
}
