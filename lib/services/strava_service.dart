import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/strava_config.dart';

/// Thin client over the authenticated `strava-auth` Edge Function.
///
/// The participant's Strava tokens live SERVER-SIDE (in the database, keyed to
/// their account). This client never stores tokens — it just kicks off the
/// OAuth redirect and asks the function to exchange / sync / disconnect, with
/// the user's Supabase session attached automatically.
class StravaService {
  StravaService._();
  static final StravaService instance = StravaService._();

  String? lastError;

  SupabaseClient get _sb => Supabase.instance.client;

  /// Step 1 — send the user to Strava to authorise (same-tab on web).
  Future<void> beginAuthorization() async {
    await launchUrl(
      StravaConfig.authorizeUrl(),
      webOnlyWindowName: '_self',
      mode: LaunchMode.externalApplication,
    );
  }

  /// Step 2 — on return, if the URL carries `?code=...`, hand it to the backend
  /// to exchange + store tokens + backfill. Returns true if a code was handled.
  Future<bool> completeAuthorizationFromUrl() async {
    final code = Uri.base.queryParameters['code'];
    if (code == null || code.isEmpty) return false;
    lastError = null;
    try {
      final res = await _sb.functions.invoke('strava-auth',
          body: {'action': 'exchange', 'code': code});
      final data = res.data;
      if (data is Map && data['error'] != null) {
        lastError = data['error'].toString();
        return false;
      }
      return true;
    } catch (e) {
      lastError = 'Could not connect Strava: $e';
      debugPrint('strava exchange failed: $e');
      return false;
    }
  }

  Future<bool> isConnected() async {
    try {
      final res = await _sb.functions
          .invoke('strava-auth', body: {'action': 'status'});
      final data = res.data;
      return data is Map && data['connected'] == true;
    } catch (e) {
      debugPrint('strava status failed: $e');
      return false;
    }
  }

  /// Ask the backend to pull the latest activities into the database.
  Future<int> syncNow() async {
    lastError = null;
    try {
      final res =
          await _sb.functions.invoke('strava-auth', body: {'action': 'sync'});
      final data = res.data;
      if (data is Map && data['error'] != null) {
        lastError = data['error'].toString();
        return 0;
      }
      return (data is Map ? (data['imported'] ?? 0) : 0) as int;
    } catch (e) {
      lastError = 'Sync failed: $e';
      debugPrint('strava sync failed: $e');
      return 0;
    }
  }

  Future<void> disconnect() async {
    try {
      await _sb.functions
          .invoke('strava-auth', body: {'action': 'disconnect'});
    } catch (e) {
      debugPrint('strava disconnect failed: $e');
    }
  }
}
