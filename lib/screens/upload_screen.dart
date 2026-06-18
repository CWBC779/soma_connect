import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/activity_import.dart';
import '../services/run_repository.dart';
import '../themes/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// Lets a participant upload an activities CSV exported from Garmin Connect
/// (or Strava). Uses the browser's native file chooser (no plugin).
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

  Future<void> _pick() async {
    final input = html.FileUploadInputElement()..accept = '.csv,text/csv';
    input.click();
    await input.onChange.first;
    final files = input.files;
    if (files == null || files.isEmpty) return;
    final file = files.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoadEnd.first;
    final result = reader.result;
    Uint8List? bytes;
    if (result is ByteBuffer) {
      bytes = result.asUint8List();
    } else if (result is Uint8List) {
      bytes = result;
    } else if (result is List<int>) {
      bytes = Uint8List.fromList(result);
    }
    if (bytes == null) return;
    final b = bytes;
    if (!mounted) return;
    setState(() {
      _fileName = file.name;
      _result = null;
      _preview = ActivityImporter.parseCsv(b);
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

              const SectionLabel('garmin — how to export your runs'),
              const SizedBox(height: 8),
              Text(
                'On a computer, go to connect.garmin.com and sign in, then:\n'
                '1. Open the menu → Activities → All Activities.\n'
                '2. (Optional) filter to "Running" and pick the date range you want.\n'
                '3. Click "Export CSV" at the top-right of the activities list.\n'
                '4. Come back here and choose that downloaded CSV file below.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const SectionLabel('strava (alternative)'),
              const SizedBox(height: 8),
              Text(
                'Strava (web): Settings → My Account → "Download or Delete Your Account" → Download Request. The zip you receive contains activities.csv — upload that.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _pick,
                icon: const Icon(Icons.upload_file),
                label: Text(_fileName == null
                    ? 'Choose CSV file'
                    : 'Choose a different file'),
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
                            '${p.totalRows} rows read · ${p.skipped} skipped (couldn\'t read date/distance/time).',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
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
                'Distances are read as kilometres. If your export uses miles or a different date format and the run count looks off, let us know and we\'ll adjust.',
              ),
            ],
          );
        },
      ),
    );
  }
}
