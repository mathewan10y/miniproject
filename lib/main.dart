import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/gamification/services/tutorial_engine_service.dart';
import 'core/config/app_secrets.dart';
import 'features/auth/login_screen.dart';
import 'features/ledger/presentation/main_screen.dart';
import 'core/services/audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file (secrets) before any service initialization
  await dotenv.load(fileName: '.env');

  // Initialize date formatting
  await initializeDateFormatting();

  // Initialize Supabase with credentials from .env
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const CyberFinanceApp(),
    ),
  );
}

class CyberFinanceApp extends ConsumerWidget {
  const CyberFinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly initialize AudioService to start BGM if enabled
    ref.read(audioServiceProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stardust - Sci-Fi Finance',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
        primaryColor: const Color(0xFF00D9FF), // Cyan
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D9FF), // Cyan
          secondary: Color(0xFF00B8D4), // Darker cyan
          surface: Color(0xFF0A0E27), // Dark space
          surfaceContainer: Color(0xFF1A1F3A), // Dark panel
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFE0FFFF), // Light cyan
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.orbitron(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFE0FFFF),
            letterSpacing: 2,
          ),
          displayMedium: GoogleFonts.orbitron(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFE0FFFF),
            letterSpacing: 1.5,
          ),
          titleLarge: GoogleFonts.orbitron(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00D9FF),
            letterSpacing: 1,
          ),
          bodyLarge: GoogleFonts.roboto(
            fontSize: 16,
            color: const Color(0xFFE0FFFF),
          ),
          bodyMedium: GoogleFonts.roboto(
            fontSize: 14,
            color: const Color(0xFFBBDEFF),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0A0E27),
          elevation: 0,
          titleTextStyle: GoogleFonts.orbitron(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00D9FF),
            letterSpacing: 1,
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// ── Auth Gate ─────────────────────────────────────────────────────────────────

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Still waiting for the first auth event
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        final session = snapshot.data?.session;
        if (session != null) {
          return const MainScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// ── Themed Loading Screen (shown while auth state resolves) ───────────────────

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Color(0xFF00D9FF),
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'INITIALIZING SYSTEMS...',
              style: GoogleFonts.orbitron(
                fontSize: 12,
                color: const Color(0xFF00D9FF).withAlpha(180),
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
