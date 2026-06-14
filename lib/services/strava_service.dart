import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/strava_config.dart';

/// "Sign in with Strava" client. Connecting Strava is the participant's login:
/// the public `strava-login` function maps the athlete to an account and hands
/// back a session. Tokens live server-side; this client stores none.
class StravaService {
  StravaService._();
  static final StravaService instance = StravaService._();

  String? lastError;

  SupabaseClient get _sb => Supabase.instance.client;

  /// Step 1 — redirect to Strava to authorise (same-tab on web).
  Future<void> beginAuthorization() async {
    await launchUrl(
      StravaConfig.authorizeUrl(),
      webOnlyWindowName: '_self',
      mode: LaunchMode.externalApplication,
    );
  }

  /// Step 2a (no session) — exchange the OAuth code for a participant session.
  /// [consent] carries consent_version + demographics captured on the welcome
  /// screen. Returns true and adopts the session on success.
  Future<bool> loginWithStrava(String code, Map<String, dynamic> consent) async {
    lastError = null;
    try {
      final res = await _sb.functions
          .invoke('strava-login', body: {'code': code, ...consent});
      final data = res.data;
      if (data is Map && data['error'] != null) {
        lastError = data['error'].toString();
        return false;
      }
      final rt = (data is Map) ? data['refresh_token'] : null;
      if (rt is String) {
        await _sb.auth.setSession(rt);
        return true;
      }
      lastError = 'Unexpected login response.';
      return false;
    } catch (e) {
      lastError = 'Login failed: $e';
      debugPrint('strava-login failed: $e');
      return false;
    }
  }

  /// Step 2b (already signed in) — re-connect Strava for the current account.
  Future<bool> exchangeCode(String code) async {
    lastError = null;
    try {
      final res = await _sb.functions
          .invoke('strava-auth', body: {'action': 'exchange', 'code': code});
      final data = res.data;
      if (data is Map && data['error'] != null) {
        lastError = data['error'].toString();
        return false;
      }
      return true;
    } catch (e) {
      lastError = 'Connect failed: $e';
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
