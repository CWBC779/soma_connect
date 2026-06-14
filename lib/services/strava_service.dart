import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/strava_config.dart';
import '../models/models.dart';
import '../models/strava_activity.dart';
import 'cycle_estimator.dart';

/// Handles the Strava OAuth handshake and activity fetching.
///
/// The client_secret is never used here — the token exchange and the Strava
/// API calls are proxied through the Supabase Edge Function (see
/// `backend/supabase/functions/strava-auth/`). The client only ever holds the
/// (refreshable) access/refresh tokens in local storage.
class StravaService {
  StravaService._();
  static final StravaService instance = StravaService._();

  /// Human-readable status of the last activities fetch, for the UI to show.
  String? lastError;

  /// Number of activities Strava returned in the last fetch (before filtering).
  int lastFetchedCount = 0;

  static const _kAccess = 'strava_access_token';
  static const _kRefresh = 'strava_refresh_token';
  static const _kExpiry = 'strava_expires_at'; // epoch seconds
  static const _kAthlete = 'strava_athlete_name';

  Future<bool> isConnected() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRefresh) != null;
  }

  Future<String?> connectedAthleteName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kAthlete);
  }

  /// Step 1 — send the user to Strava to authorise. On web this is a same-tab
  /// redirect; the user returns to [StravaConfig.redirectUri] with a `code`.
  Future<void> beginAuthorization() async {
    await launchUrl(
      StravaConfig.authorizeUrl(),
      webOnlyWindowName: '_self', // same-tab redirect for the PWA
      mode: LaunchMode.externalApplication,
    );
  }

  /// Step 2 — call on app start. If the current URL carries a `?code=...` from
  /// Strava, exchange it for tokens and persist them. Returns true if a new
  /// connection was established.
  Future<bool> completeAuthorizationFromUrl() async {
    final code = Uri.base.queryParameters['code'];
    if (code == null || code.isEmpty) return false;
    return _exchangeCode(code);
  }

  Future<bool> _exchangeCode(String code) async {
    final res = await _callBackend({'action': 'exchange', 'code': code});
    if (res == null) return false;
    await _storeTokens(res);
    return true;
  }

  /// Returns a non-expired access token, refreshing it via the backend if
  /// needed. Null if the athlete is not connected.
  Future<String?> _validAccessToken() async {
    final p = await SharedPreferences.getInstance();
    final access = p.getString(_kAccess);
    final refresh = p.getString(_kRefresh);
    final expiry = p.getInt(_kExpiry) ?? 0;
    if (refresh == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (access != null && now < expiry - 60) return access;
    final res = await _callBackend({'action': 'refresh', 'refresh_token': refresh});
    if (res == null) return null;
    await _storeTokens(res);
    return res['access_token'] as String?;
  }

  /// Fetch recent runs and map them to [RunEntry], tagging each with the
  /// estimated cycle phase from [estimator].
  /// Fetch recent runs. [estimator] may be null — phases are only tagged once a
  /// cycle date is set; runs still load (distance/pace) without it.
  Future<List<RunEntry>> fetchRuns(CycleEstimator? estimator,
      {int perPage = 30}) async {
    lastError = null;
    lastFetchedCount = 0;
    final token = await _validAccessToken();
    if (token == null) {
      lastError = 'Not connected to Strava (no token).';
      return const [];
    }
    final res = await _callBackend({
      'action': 'activities',
      'access_token': token,
      'per_page': perPage,
    });
    if (res == null) return const []; // lastError set by _callBackend
    if (res['error'] != null) {
      lastError = 'Strava: ${res['error']}';
      return const [];
    }
    final list = (res['activities'] as List?) ?? const [];
    lastFetchedCount = list.length;
    final runs = list
        .map((e) => StravaActivity.fromJson(e as Map<String, dynamic>))
        .where((a) => a.isRun && a.distanceMeters > 0)
        .map((a) => a.toRunEntry(estimator))
        .toList();
    if (list.isNotEmpty && runs.isEmpty) {
      lastError =
          'Found ${list.length} Strava activities but none were runs with a distance. Log the entry as a "Run" with a distance.';
    }
    return runs;
  }

  Future<void> disconnect() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
    await p.remove(_kExpiry);
    await p.remove(_kAthlete);
  }

  // ── internals ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> _callBackend(Map<String, dynamic> body) async {
    try {
      final hasKey = StravaConfig.supabaseAnonKey.isNotEmpty &&
          !StravaConfig.supabaseAnonKey.startsWith('YOUR_');
      final res = await http.post(
        Uri.parse(StravaConfig.backendUrl),
        headers: {
          'Content-Type': 'application/json',
          if (hasKey) 'Authorization': 'Bearer ${StravaConfig.supabaseAnonKey}',
          if (hasKey) 'apikey': StravaConfig.supabaseAnonKey,
        },
        body: jsonEncode(body),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      lastError = 'Backend error ${res.statusCode}.';
      debugPrint('Strava backend error ${res.statusCode}: ${res.body}');
      return null;
    } catch (e) {
      lastError = 'Network error reaching the backend.';
      debugPrint('Strava backend call failed: $e');
      return null;
    }
  }

  Future<void> _storeTokens(Map<String, dynamic> res) async {
    final p = await SharedPreferences.getInstance();
    if (res['access_token'] != null) {
      await p.setString(_kAccess, res['access_token'] as String);
    }
    if (res['refresh_token'] != null) {
      await p.setString(_kRefresh, res['refresh_token'] as String);
    }
    if (res['expires_at'] != null) {
      await p.setInt(_kExpiry, (res['expires_at'] as num).toInt());
    }
    final athlete = res['athlete'];
    if (athlete is Map && athlete['firstname'] != null) {
      await p.setString(_kAthlete, athlete['firstname'].toString());
    }
  }
}
