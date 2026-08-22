import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hlzcdxnigjyiwfhtwanl.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhsemNkeG5pZ2p5aXdmaHR3YW5sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODczNjU3NjYsImV4cCI6MjEwMjk0MTc2Nn0.qNMRJ9xehih8pTx8Ow5QUXA7uTSYso0uK53J3lmfq0Q',
  );

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static Future<void> initialize() async {
    try {
      // Normalize URL (strip /rest/v1 if included)
      final cleanUrl = supabaseUrl.replaceAll('/rest/v1/', '').replaceAll('/rest/v1', '').trim();
      await Supabase.initialize(
        url: cleanUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey.trim(),
      );
      _isInitialized = true;
      debugPrint('[Supabase] Connected successfully to $cleanUrl for MUSTER.');
    } catch (e) {
      debugPrint('[Supabase] Notice: $e (Operating in hybrid resilience mode)');
      _isInitialized = false;
    }
  }
}
