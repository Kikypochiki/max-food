abstract final class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hiayuymbmolmzrzvrcrd.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpYXl1eW1ibW9sbXpyenZyY3JkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4NDA5NjUsImV4cCI6MjA5MTQxNjk2NX0.PoKV0zWYz2-JewVtWLpOo1aLqs59UOj4lEz-Z_Tvurg',
  );
}
