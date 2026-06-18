import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Study-code sign-in. The participant enters a code the researcher issued; the
/// public `code-login` function validates it and returns a session.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  String? lastError;

  SupabaseClient get _sb => Supabase.instance.client;

  /// Returns true and adopts the session on success; sets [lastError] on failure
  /// (e.g. "Invalid study code.").
  Future<bool> loginWithCode(String code, Map<String, dynamic> consent) async {
    lastError = null;
    try {
      final res = await _sb.functions
          .invoke('code-login', body: {'code': code, ...consent});
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
      lastError = 'Unexpected response. Please try again.';
      return false;
    } on FunctionException catch (e) {
      final d = e.details;
      lastError = (d is Map && d['error'] != null)
          ? d['error'].toString()
          : 'Invalid study code.';
      return false;
    } catch (e) {
      lastError = 'Login failed: $e';
      debugPrint('code-login failed: $e');
      return false;
    }
  }
}
