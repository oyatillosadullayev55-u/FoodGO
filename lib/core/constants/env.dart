/// Supabase sozlamalari --dart-define orqali beriladi.
/// Kod ichida ochiq yozilmaydi.
class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ombfpyoqcnrteavuhque.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9tYmZweW9xY25ydGVhdnVocXVlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4NTczNzYsImV4cCI6MjEwNzQzMzM3Nn0.1bcFYPquoHV5eeE4B_9nHABHmdiAJTXAzV3w3g12h5o',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
