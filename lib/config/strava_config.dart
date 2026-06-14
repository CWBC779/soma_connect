/// Strava OAuth + API configuration.
///
/// SECURITY: never put your Strava client *secret* in this file. The secret
/// lives only in the Supabase Edge Function's environment
/// (`STRAVA_CLIENT_SECRET`). This file holds only public values that are safe
/// to ship inside a web/mobile client.
class StravaConfig {
  StravaConfig._();

  /// Your app's "Client ID" from https://www.strava.com/settings/api
  static const String clientId = 'YOUR_STRAVA_CLIENT_ID';

  /// Where Strava sends the user back after they authorise.
  ///
  /// This must match your Strava API "Authorization Callback Domain"
  /// (domain only, e.g. `cwbc779.github.io`) and the full URL below.
  /// GitHub Pages build:
  static const String redirectUri = 'https://cwbc779.github.io/soma_connect/';

  /// Your deployed Supabase Edge Function URL (token exchange + API proxy):
  /// https://<project-ref>.functions.supabase.co/strava-auth
  static const String backendUrl =
      'https://ichfwawdqtxxkmnvmmzy.functions.supabase.co/strava-auth';

  /// Supabase anon (public) key — used to invoke the Edge Function. This is a
  /// publishable key and is safe in the client. It is NOT the service-role key.
  /// Leave blank if you deploy the function with `--no-verify-jwt`.
  static const String supabaseAnonKey = '';

  /// Scopes: read activities (incl. private) so we can compute training load.
  static const String scope = 'activity:read_all';

  /// True once the placeholders above have been filled in.
  static bool get isConfigured =>
      !clientId.startsWith('YOUR_') && !backendUrl.contains('YOUR_');

  /// The Strava authorize URL the user is redirected to (step 1 of OAuth).
  static Uri authorizeUrl() => Uri.https('www.strava.com', '/oauth/authorize', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'approval_prompt': 'auto',
        'scope': scope,
      });
}
