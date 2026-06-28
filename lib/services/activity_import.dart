import 'dart:convert';
import 'dart:math' as math;
import 'package:csv/csv.dart';
import 'package:xml/xml.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cycle_estimator.dart';
import 'run_repository.dart';

/// A picked file: its name (for extension dispatch) and raw bytes.
typedef NamedBytes = ({String name, List<int> bytes});

/// Result of parsing one or more uploaded activity files.
class ImportPreview {
  final List<Map<String, dynamic>> rows;
  final int totalRows; // activity rows/files looked at
  final int runs; // runs successfully parsed (== rows.length)
  final int skipped; // looked like an activity but missing date/distance/time
  final int files; // files processed
  final List<String> unsupported; // file names we couldn't read (e.g. .fit)
  final String? error; // fatal: nothing could be read at all

  const ImportPreview({
    required this.rows,
    required this.totalRows,
    required this.runs,
    required this.skipped,
    this.files = 1,
    this.unsupported = const [],
    this.error,
  });
}

/// Parses a participant's exported activities into `runs` rows and stores them
/// (source = 'upload'). Supports:
///   • CSV  — Garmin Connect / Strava activities export (many runs per file)
///   • GPX  — Suunto, Garmin, Polar, Coros… (one run per file; distance is
///            computed from the GPS track)
///   • TCX  — Garmin, training-centre exports (one run per file)
/// Multiple files can be parsed in one go (see [parseFiles]).
class ActivityImporter {
  // ── shared helpers ────────────────────────────────────────────────────────

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
    final m = RegExp(r'(\d{1,4})[/-](\d{1,2})[/-](\d{2,4})').firstMatch(s);
    if (m != null) {
      final a = int.parse(m.group(1)!);
      final b = int.parse(m.group(2)!);
      var c = int.parse(m.group(3)!);
      if (a > 1000) return DateTime(a, b, c);
      if (c < 100) c += 2000;
      if (a > 12) return DateTime(c, b, a); // day-first
      return DateTime(c, a, b);
    }
    return null;
  }

  static double? _parseDistanceKm(String s) {
    final clean = s.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '');
    return double.tryParse(clean); // assumed kilometres
  }

  static int? _parseDuration(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    if (t.contains(':')) {
      final parts = t.split(':').map((p) => double.tryParse(p) ?? 0).toList();
      if (parts.length == 3) {
        return (parts[0] * 3600 + parts[1] * 60 + parts[2]).round();
      }
      if (parts.length == 2) return (parts[0] * 60 + parts[1]).round();
    }
    return double.tryParse(t)?.round();
  }

  /// Builds a single `runs` row (with estimated phase) from cleaned values.
  static Map<String, dynamic> _row({
    required String? uid,
    required CycleEstimator? est,
    required String nowIso,
    required DateTime date,
    required double distKm,
    required int secs,
    double? hr,
  }) {
    String? phase;
    int? cycleDay;
    if (est != null) {
      phase = est.phaseFor(date).name;
      cycleDay = est.cycleDayFor(date);
    }
    return {
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
      'synced_at': nowIso,
    };
  }

  static String? _uid() => Supabase.instance.client.auth.currentUser?.id;

  // ── public entry points ───────────────────────────────────────────────────

  /// Parse several picked files and merge into one preview (deduping by the
  /// activity's external id, so the same run picked twice isn't double-counted).
  static ImportPreview parseFiles(List<NamedBytes> files) {
    if (files.isEmpty) {
      return const ImportPreview(
          rows: [], totalRows: 0, runs: 0, skipped: 0, files: 0);
    }
    final byId = <String, Map<String, dynamic>>{};
    int total = 0, skipped = 0;
    final unsupported = <String>[];
    final errors = <String>[];

    for (final f in files) {
      final p = parseFile(f.name, f.bytes);
      if (p.unsupported.isNotEmpty) {
        unsupported.addAll(p.unsupported);
        continue;
      }
      if (p.error != null && p.rows.isEmpty && p.skipped == 0) {
        errors.add('${f.name}: ${p.error}');
        continue;
      }
      total += p.totalRows;
      skipped += p.skipped;
      for (final r in p.rows) {
        byId[r['external_id'] as String] = r; // last wins; dedupes repeats
      }
    }

    final rows = byId.values.toList();
    // Only surface a fatal error if literally nothing usable came through.
    final fatal = (rows.isEmpty && skipped == 0 && unsupported.isEmpty)
        ? (errors.isNotEmpty
            ? errors.first
            : 'Could not read any runs from the selected file(s).')
        : null;
    return ImportPreview(
      rows: rows,
      totalRows: total,
      runs: rows.length,
      skipped: skipped,
      files: files.length,
      unsupported: unsupported,
      error: fatal,
    );
  }

  /// Dispatch a single file to the right parser by extension.
  static ImportPreview parseFile(String name, List<int> bytes) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.csv')) return parseCsv(bytes);
    if (lower.endsWith('.gpx')) return _parseGpx(bytes);
    if (lower.endsWith('.tcx')) return _parseTcx(bytes);
    if (lower.endsWith('.fit')) return _parseFit(bytes);
    // Unknown extension — report, don't crash.
    return ImportPreview(
        rows: const [], totalRows: 0, runs: 0, skipped: 0, unsupported: [name]);
  }

  // ── CSV (many runs per file) ──────────────────────────────────────────────

  static ImportPreview parseCsv(List<int> bytes) {
    try {
      final text = utf8.decode(bytes, allowMalformed: true);
      final table =
          const CsvToListConverter(shouldParseNumbers: false, eol: '\n')
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
      final hrIdx =
          _idx(headers, ['avg hr', 'average heart', 'avg heart', 'heart rate']);

      if (dateIdx < 0 || distIdx < 0 || timeIdx < 0) {
        return const ImportPreview(
            rows: [],
            totalRows: 0,
            runs: 0,
            skipped: 0,
            error:
                'Could not find Date / Distance / Time columns. Make sure this is an activities CSV export.');
      }

      final uid = _uid();
      final CycleEstimator? est = RunRepository.instance.estimator;
      final nowIso = DateTime.now().toUtc().toIso8601String();

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
          continue; // not a run
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
        rows.add(_row(
            uid: uid,
            est: est,
            nowIso: nowIso,
            date: date,
            distKm: distKm,
            secs: secs,
            hr: hr));
      }
      return ImportPreview(
          rows: rows, totalRows: total, runs: runs, skipped: skipped);
    } catch (e) {
      return ImportPreview(
          rows: const [], totalRows: 0, runs: 0, skipped: 0, error: '$e');
    }
  }

  // ── GPX (one run per file; distance from the GPS track) ───────────────────

  /// All descendant elements whose *local* name matches (ignores namespace
  /// prefixes like `gpxtpx:` so HR extensions are found whatever the app uses).
  static Iterable<XmlElement> _local(XmlNode root, String local) =>
      root.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == local);

  static double _haversineM(double la1, double lo1, double la2, double lo2) {
    const r = 6371000.0; // metres
    const d = math.pi / 180.0;
    final dLat = (la2 - la1) * d;
    final dLon = (lo2 - lo1) * d;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la1 * d) *
            math.cos(la2 * d) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * r * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static ImportPreview _parseGpx(List<int> bytes) {
    try {
      final doc = XmlDocument.parse(utf8.decode(bytes, allowMalformed: true));

      // Skip clearly non-running tracks (cycling/walking/swim/etc.).
      final typeText = _local(doc, 'type')
          .map((e) => e.innerText.toLowerCase())
          .firstWhere((t) => t.isNotEmpty, orElse: () => '');
      const nonRun = ['cycl', 'bike', 'biking', 'swim', 'walk', 'hik'];
      if (typeText.isNotEmpty && nonRun.any(typeText.contains)) {
        return const ImportPreview(
            rows: [], totalRows: 1, runs: 0, skipped: 1);
      }

      final pts = _local(doc, 'trkpt').toList();
      if (pts.length < 2) {
        return const ImportPreview(
            rows: [], totalRows: 1, runs: 0, skipped: 1);
      }

      double distM = 0;
      double? prevLat, prevLon;
      DateTime? start, end;
      final hrs = <double>[];
      for (final p in pts) {
        final lat = double.tryParse(p.getAttribute('lat') ?? '');
        final lon = double.tryParse(p.getAttribute('lon') ?? '');
        if (lat != null && lon != null) {
          if (prevLat != null && prevLon != null) {
            distM += _haversineM(prevLat, prevLon, lat, lon);
          }
          prevLat = lat;
          prevLon = lon;
        }
        final t = _local(p, 'time')
            .map((e) => DateTime.tryParse(e.innerText.trim()))
            .firstWhere((d) => d != null, orElse: () => null);
        if (t != null) {
          start ??= t;
          if (end == null || t.isAfter(end)) end = t;
        }
        final hr = _local(p, 'hr')
            .map((e) => double.tryParse(e.innerText.trim()))
            .firstWhere((v) => v != null, orElse: () => null);
        if (hr != null && hr > 0) hrs.add(hr);
      }

      final secs =
          (start != null && end != null) ? end.difference(start).inSeconds : 0;
      final distKm = distM / 1000.0;
      if (start == null || distKm <= 0 || secs <= 0) {
        return const ImportPreview(
            rows: [], totalRows: 1, runs: 0, skipped: 1);
      }
      final hr = hrs.isEmpty ? null : hrs.reduce((a, b) => a + b) / hrs.length;
      final row = _row(
        uid: _uid(),
        est: RunRepository.instance.estimator,
        nowIso: DateTime.now().toUtc().toIso8601String(),
        date: start,
        distKm: distKm,
        secs: secs,
        hr: hr,
      );
      return ImportPreview(rows: [row], totalRows: 1, runs: 1, skipped: 0);
    } catch (e) {
      return ImportPreview(
          rows: const [], totalRows: 1, runs: 0, skipped: 0, error: '$e');
    }
  }

  // ── TCX (one run per file; distance/time read directly) ───────────────────

  static ImportPreview _parseTcx(List<int> bytes) {
    try {
      final doc = XmlDocument.parse(utf8.decode(bytes, allowMalformed: true));

      final sport = _local(doc, 'Activity')
          .map((e) => (e.getAttribute('Sport') ?? '').toLowerCase())
          .firstWhere((s) => s.isNotEmpty, orElse: () => '');
      if (sport.isNotEmpty && !sport.contains('run')) {
        return const ImportPreview(
            rows: [], totalRows: 1, runs: 0, skipped: 1);
      }

      double distM = 0;
      int secs = 0;
      for (final e in _local(doc, 'DistanceMeters')) {
        distM += double.tryParse(e.innerText.trim()) ?? 0;
      }
      for (final e in _local(doc, 'TotalTimeSeconds')) {
        secs += (double.tryParse(e.innerText.trim()) ?? 0).round();
      }
      final hrs = _local(doc, 'AverageHeartRateBpm')
          .expand((e) => _local(e, 'Value'))
          .map((e) => double.tryParse(e.innerText.trim()))
          .whereType<double>()
          .where((v) => v > 0)
          .toList();

      // Start time: <Id> on the activity, else first trackpoint <Time>.
      DateTime? start = _local(doc, 'Id')
          .map((e) => DateTime.tryParse(e.innerText.trim()))
          .firstWhere((d) => d != null, orElse: () => null);
      start ??= _local(doc, 'Time')
          .map((e) => DateTime.tryParse(e.innerText.trim()))
          .firstWhere((d) => d != null, orElse: () => null);

      final distKm = distM / 1000.0;
      if (start == null || distKm <= 0 || secs <= 0) {
        return const ImportPreview(
            rows: [], totalRows: 1, runs: 0, skipped: 1);
      }
      final hr = hrs.isEmpty ? null : hrs.reduce((a, b) => a + b) / hrs.length;
      final row = _row(
        uid: _uid(),
        est: RunRepository.instance.estimator,
        nowIso: DateTime.now().toUtc().toIso8601String(),
        date: start,
        distKm: distKm,
        secs: secs,
        hr: hr,
      );
      return ImportPreview(rows: [row], totalRows: 1, runs: 1, skipped: 0);
    } catch (e) {
      return ImportPreview(
          rows: const [], totalRows: 1, runs: 0, skipped: 0, error: '$e');
    }
  }

  // ── FIT (binary; one or more sessions per file) ───────────────────────────
  //
  // A compact reader for just the `session` summary message (global num 18),
  // which holds the device's own totals. Verified byte-for-byte against a real
  // Garmin .fit export. We avoid bitwise shifts (Dart-on-web truncates them to
  // 32-bit signed, corrupting uint32 reads) and use `* 256` accumulation.
  //
  // FIT timestamps are seconds since 1989-12-31 UTC; add this to reach Unix.
  static const int _fitEpoch = 631065600;

  static int _readUint(List<int> b, int off, int size, bool big) {
    int v = 0;
    if (big) {
      for (var i = 0; i < size; i++) {
        v = v * 256 + (b[off + i] & 0xff);
      }
    } else {
      for (var i = size - 1; i >= 0; i--) {
        v = v * 256 + (b[off + i] & 0xff);
      }
    }
    return v;
  }

  static ImportPreview _parseFit(List<int> b) {
    try {
      if (b.length < 14) {
        return const ImportPreview(
            rows: [], totalRows: 0, runs: 0, skipped: 0, error: 'Not a FIT file.');
      }
      final headerSize = b[0];
      final dataSize = _readUint(b, 4, 4, false);
      var end = headerSize + dataSize;
      if (end > b.length) end = b.length; // tolerate a missing/short CRC

      final uid = _uid();
      final est = RunRepository.instance.estimator;
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final lowerBound = DateTime.utc(2015);
      final upperBound = DateTime.now().toUtc().add(const Duration(days: 2));

      final defs = <int, _FitDef>{};
      final rows = <Map<String, dynamic>>[];
      int sessions = 0, skipped = 0;
      var pos = headerSize;

      while (pos < end) {
        final h = b[pos];
        pos++;
        if ((h & 0x80) != 0) {
          // compressed-timestamp data message
          final local = (h >> 5) & 0x03;
          final def = defs[local];
          if (def == null) break;
          final start = pos;
          pos += def.totalSize;
          if (def.global == 18) {
            sessions++;
            if (!_addFitSession(b, start, def, uid, est, nowIso, lowerBound,
                upperBound, rows)) {
              skipped++;
            }
          }
          continue;
        }
        if ((h & 0x40) != 0) {
          // definition message
          final local = h & 0x0f;
          pos++; // reserved
          final big = b[pos] == 1;
          pos++;
          final global = _readUint(b, pos, 2, big);
          pos += 2;
          final numFields = b[pos];
          pos++;
          final fields = <_FitField>[];
          var total = 0;
          for (var f = 0; f < numFields; f++) {
            final fnum = b[pos];
            final fsize = b[pos + 1];
            pos += 3; // num, size, base type
            fields.add(_FitField(fnum, fsize, total));
            total += fsize;
          }
          if ((h & 0x20) != 0) {
            // developer fields: count + 3 bytes each; sizes count toward record
            final numDev = b[pos];
            pos++;
            for (var d = 0; d < numDev; d++) {
              total += b[pos + 1];
              pos += 3;
            }
          }
          defs[local] = _FitDef(global, big, fields, total);
          continue;
        }
        // normal data message
        final local = h & 0x0f;
        final def = defs[local];
        if (def == null) break;
        final start = pos;
        pos += def.totalSize;
        if (def.global == 18) {
          sessions++;
          if (!_addFitSession(b, start, def, uid, est, nowIso, lowerBound,
              upperBound, rows)) {
            skipped++;
          }
        }
      }

      if (rows.isEmpty && sessions == 0) {
        return const ImportPreview(
            rows: [],
            totalRows: 0,
            runs: 0,
            skipped: 0,
            error: 'No session summary found in this FIT file.');
      }
      return ImportPreview(
          rows: rows, totalRows: sessions, runs: rows.length, skipped: skipped);
    } catch (e) {
      return ImportPreview(
          rows: const [], totalRows: 0, runs: 0, skipped: 0, error: '$e');
    }
  }

  /// Reads the fields we need from one session record. Returns true if it was a
  /// valid running session and a row was added.
  static bool _addFitSession(
    List<int> b,
    int start,
    _FitDef def,
    String? uid,
    CycleEstimator? est,
    String nowIso,
    DateTime lowerBound,
    DateTime upperBound,
    List<Map<String, dynamic>> rows,
  ) {
    int? field(int num) {
      for (final f in def.fields) {
        if (f.num == num) return _readUint(b, start + f.offset, f.size, def.big);
      }
      return null;
    }

    final sport = field(5); // 1 = running
    if (sport != null && sport != 1) return false; // skip non-runs

    final rawStart = field(2);
    if (rawStart == null || rawStart == 4294967295) return false;
    final date = DateTime.fromMillisecondsSinceEpoch(
        (rawStart + _fitEpoch) * 1000,
        isUtc: true);
    if (date.isBefore(lowerBound) || date.isAfter(upperBound)) {
      return false; // implausible date → reject rather than corrupt the dataset
    }

    final distRaw = field(9); // cm? no — 1/100 m
    if (distRaw == null || distRaw == 4294967295 || distRaw == 0) return false;
    final distKm = distRaw / 100.0 / 1000.0;

    // Prefer moving (timer) time; fall back to elapsed.
    final timer = field(8);
    final elapsed = field(7);
    final msRaw = (timer != null && timer != 4294967295)
        ? timer
        : (elapsed != null && elapsed != 4294967295 ? elapsed : null);
    if (msRaw == null || msRaw == 0) return false;
    final secs = (msRaw / 1000.0).round();

    final hrRaw = field(16);
    final hr = (hrRaw == null || hrRaw == 255) ? null : hrRaw.toDouble();

    rows.add(_row(
      uid: uid,
      est: est,
      nowIso: nowIso,
      date: date,
      distKm: distKm,
      secs: secs,
      hr: hr,
    ));
    return true;
  }

  // ── store ─────────────────────────────────────────────────────────────────

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

/// One field within a FIT message definition (field number, byte size, and its
/// offset within the data record).
class _FitField {
  final int num;
  final int size;
  final int offset;
  const _FitField(this.num, this.size, this.offset);
}

/// A FIT local-message definition: which global message it is, its byte order,
/// its ordered fields, and the total byte size of a data record using it.
class _FitDef {
  final int global;
  final bool big;
  final List<_FitField> fields;
  final int totalSize;
  const _FitDef(this.global, this.big, this.fields, this.totalSize);
}
