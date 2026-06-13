import 'package:flutter/material.dart';
import '../config/strava_config.dart';
import '../services/strava_service.dart';
import '../themes/app_theme.dart';

/// Self-contained card to connect / disconnect Strava. Drop it into any screen
/// (e.g. the dashboard list) — it manages its own state and completes the OAuth
/// handshake when the app loads back from Strava with a `?code=...`.
class StravaConnectCard extends StatefulWidget {
  /// Called after a successful connect/disconnect so the host screen can reload
  /// its data (e.g. re-fetch runs). Optional.
  final VoidCallback? onChanged;

  const StravaConnectCard({super.key, this.onChanged});

  @override
  State<StravaConnectCard> createState() => _StravaConnectCardState();
}

class _StravaConnectCardState extends State<StravaConnectCard> {
  bool _loading = true;
  bool _connected = false;
  String? _athlete;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // If we returned from Strava with ?code=..., finish the handshake.
    final justConnected =
        await StravaService.instance.completeAuthorizationFromUrl();
    final connected = await StravaService.instance.isConnected();
    final name = await StravaService.instance.connectedAthleteName();
    if (!mounted) return;
    setState(() {
      _connected = connected;
      _athlete = name;
      _loading = false;
    });
    if (justConnected) widget.onChanged?.call();
  }

  Future<void> _connect() async {
    if (!StravaConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Strava not configured yet — add your Client ID and backend URL in lib/config/strava_config.dart'),
      ));
      return;
    }
    await StravaService.instance.beginAuthorization();
  }

  Future<void> _disconnect() async {
    await StravaService.instance.disconnect();
    if (!mounted) return;
    setState(() {
      _connected = false;
      _athlete = null;
    });
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.directions_run, color: FemoraTheme.sage),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _connected ? 'Strava connected' : 'Connect Strava',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _connected
                        ? 'Syncing ${_athlete ?? 'your'} runs for real insights.'
                        : 'Import your runs to replace the demo data.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _connected
                ? TextButton(onPressed: _disconnect, child: const Text('Disconnect'))
                : FilledButton(onPressed: _connect, child: const Text('Connect')),
          ],
        ),
      ),
    );
  }
}
