import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/activity_import.dart';
import '../services/run_repository.dart';
import '../themes/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// Lets a participant upload activity files exported from their sports app —
/// a CSV summary (Garmin Connect / Strava) or individual GPX/TCX files
/// (Suunto, Garmin, Polar, Coros…). Multiple files can be chosen at once.
/// Uses the browser's native file chooser (no plugin).
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  ImportPreview? _preview;
  String? _fileName;
  bool _busy = false;
  String? _result;

  Future<Uint8List?> _read(html.File file) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoadEnd.first;
    final result = reader.result;
    if (result is ByteBuffer) return result.asUint8List();
    if (result is Uint8List) return result;
    if (result is List<int>) return Uint8List.fromList(result);
    return null;
  }

  Future<void> _pick() async {
    final input = html.FileUploadInputElement()
      ..accept = '.csv,.gpx,.tcx,.fit'
      ..multiple = true;
    input.click();
    await input.onChange.first;
    final files = input.files;
    if (files == null || files.isEmpty) return;

    final picked = <NamedBytes>[];
    for (final file in files) {
      final bytes = await _read(file);
      if (bytes != null) picked.add((name: file.name, bytes: bytes));
    }
    if (picked.isEmpty || !mounted) return;
    setState(() {
      _fileName = picked.length == 1
          ? picked.first.name
          : '${picked.length} files selected';
      _result = null;
      _preview = ActivityImporter.parseFiles(picked);
    });
  }

  Future<void> _import() async {
    final preview = _preview;
    if (preview == null || preview.rows.isEmpty) return;
    setState(() => _busy = true);
    try {
      final n = await ActivityImporter.import(preview.rows);
      if (!mounted) return;
      setState(() {
        _result = 'Imported $n runs. They\'ll appear on your dashboard.';
        _preview = null;
        _fileName = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _result = 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fmt(DateTime d) {
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload activity data')),
      body: ListenableBuilder(
        listenable: RunRepository.instance,
        builder: (context, _) {
          final repo = RunRepository.instance;
          final p = _preview;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Last uploaded + reminder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: FemoraTheme.warmGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repo.lastUploadAt != null
                          ? 'Last uploaded: ${_fmt(repo.lastUploadAt!)}'
                          : 'No data uploaded yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (repo.uploadReminderDue) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Please upload your activities at least once a month so your data stays up to date.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'We accept a CSV summary (many runs in one file) or individual '
                'GPX, TCX or FIT files. You can select several files at once.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              const SectionLabel('garmin (csv — all your runs at once)'),
              const SizedBox(height: 8),
              Text(
                'On a computer at connect.garmin.com:\n'
                '1. Menu → Activities → All Activities.\n'
                '2. (Optional) filter to "Running" and pick a date range. Scroll '
                'down to load all the activities you want included.\n'
                '3. Click "Export CSV" at the top-right of the list.\n'
                '4. Choose that downloaded CSV below.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const SectionLabel('suunto, polar, coros… (fit or gpx files)'),
              const SizedBox(height: 8),
              Text(
                'Suunto app: open a workout → tap ⋯ (top-right) → Export → '
                'choose FIT (most accurate, and works for treadmill runs too) or '
                'GPX. Repeat for each run, then select all the files here '
                'together.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const SectionLabel('strava (alternative)'),
              const SizedBox(height: 8),
              Text(
                'Strava (web): Settings → My Account → "Download or Delete Your '
                'Account" → Download Request. The zip you receive contains '
                'activities.csv — upload that.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.upload_file),
                label: Text(_fileName == null
                    ? 'Choose files (CSV, GPX, TCX or FIT)'
                    : 'Choose different files'),
              ),
              if (_fileName != null) ...[
                const SizedBox(height: 8),
                Text(_fileName!,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 16),

              if (p != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p.error != null)
                          Text(p.error!,
                              style: const TextStyle(
                                  fontSize: 13, color: FemoraTheme.rose))
                        else ...[
                          Text('Found ${p.runs} runs',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium),
                          const SizedBox(height: 4),
                          Text(
                            'From ${p.files} file${p.files == 1 ? '' : 's'} · ${p.skipped} skipped (couldn\'t read date/distance/time, or not a run).',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (p.unsupported.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${p.unsupported.length} file${p.unsupported.length == 1 ? '' : 's'} skipped (unsupported format — use CSV, GPX, TCX or FIT): ${p.unsupported.join(', ')}',
                              style: const TextStyle(
                                  fontSize: 12, color: FemoraTheme.rose),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (p.error == null && p.runs > 0)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _import,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Import ${p.runs} runs'),
                    ),
                  ),
              ],

              if (_result != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: FemoraTheme.sageLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_result!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],

              const SizedBox(height: 16),
              const DisclaimerBox(
                'CSV distances are read as kilometres. GPX distance is computed '
                'from the GPS track, so it may differ by ~1% from your watch. If '
                'a count looks off (e.g. a miles-based export), let us know and '
                'we\'ll adjust.',
              ),
            ],
          );
        },
      ),
    );
  }
}
