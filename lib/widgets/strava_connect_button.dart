import 'package:flutter/material.dart';
import '../config/strava_config.dart';
import '../services/strava_service.dart';
import '../services/run_repository.dart';
import '../themes/app_theme.dart';

/// Connect / refresh / disconnect Strava, with live run count + error feedback.
/// Completes the OAuth handshake when the app loads back from Strava.
class StravaConnectCard extends StatefulWidget {
  const StravaConnectCard({super.key});

  @override
  State<StravaConnectCard> createState() => _StravaConnectCardState();
}

class _StravaConnectCardState extends State<StravaConnectCard> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final justConnected =
        await StravaService.instance.completeAuthorizationFromUrl();
    if (justConnected) {
      await RunRepository.instance.syncFromStrava();
    }
    if (mounted) setState(() {});
  }

  Future<void> _connect() async {
    if (!StravaConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Strava is not configured yet.'),
      ));
      return;
    }
    await StravaService.instance.beginAuthorization();
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    await RunRepository.instance.syncFromStrava();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _disconnect() async {
    await StravaService.instance.disconnect();
    await RunRepository.instance.refresh();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RunRepository.instance,
      builder: (context, _) {
        final repo = RunRepository.instance;
        final connected = repo.connected;
        final error = repo.lastError;
        final spinning = _busy || repo.loading;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_run,
                        color: FemoraTheme.sage),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            connected
                                ? 'Strava connected'
                                : 'Connect Strava',
                            style:
                                Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            connected
                                ? '${repo.runs.length} runs synced'
                                : 'Import your runs to see real insights.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (connected) ...[
                      spinning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : IconButton(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Refresh runs',
                              color: FemoraTheme.rose,
                            ),
                      TextButton(
                          onPressed: _disconnect,
                          child: const Text('Disconnect')),
                    ] else
                      FilledButton(
                          onPressed: _connect,
                          child: const Text('Connect')),
                  ],
                ),
                if (connected && error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FemoraTheme.warmGray,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(error,
                        style: const TextStyle(
                            fontSize: 12, color: FemoraTheme.ink)),
                  ),
                ],
                if (connected &&
                    error == null &&
                    repo.runs.isEmpty &&
                    !spinning) ...[
                  const SizedBox(height: 10),
                  Text(
                    'No runs synced yet. Once you record a run on Strava, tap refresh to see it here.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
