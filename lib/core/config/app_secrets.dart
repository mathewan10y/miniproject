import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase project URL — loaded from .env at runtime.
String get supabaseUrl =>
    dotenv.env['SUPABASE_URL'] ?? 'https://upuolzqaenhihczxycll.supabase.co';

/// Supabase anon key — loaded from .env at runtime.
String get supabaseAnonKey =>
    dotenv.env['SUPABASE_ANON_KEY'] ??
    'sb_publishable_J_2RiPZ06lr1rwo3420gyg_rFV8e0b2';

/// Gemini API key — loaded from .env at runtime.
String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
