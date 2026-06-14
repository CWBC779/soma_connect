/// Supabase project connection (public values — safe to ship).
///
/// The anon key is a publishable key; access is governed by Row-Level Security
/// in the database, so it is safe to embed in the client and commit.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://ichfwawdqtxxkmnvmmzy.supabase.co';

  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImljaGZ3YXdkcXR4eGttbnZtbXp5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzODczNzYsImV4cCI6MjA5Njk2MzM3Nn0.kw-cPgAyOPcjOPj5qI2NZOggRDuHz3PpWSJXDYHqrZk';

  /// Where magic-link / OAuth redirects return to (must be in Supabase's
  /// Auth redirect allow-list).
  static const String redirectUrl = 'https://cwbc779.github.io/soma_connect/';
}
