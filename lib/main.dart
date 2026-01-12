import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/config/app_secrets.dart';
import 'features/ledger/presentation/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting
  await initializeDateFormatting();

  // Initialize Supabase
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const ProviderScope(child: CyberFinanceApp()));
}

class CyberFinanceApp extends StatelessWidget {
  const CyberFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stardust - Sci-Fi Finance',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
        primaryColor: const Color(0xFF00D9FF), // Cyan
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D9FF), // Cyan
          secondary: Color(0xFF00B8D4), // Darker cyan
          background: Color(0xFF0A0E27), // Dark space
          surface: Color(0xFF1A1F3A), // Dark panel
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Color(0xFFE0FFFF), // Light cyan
          onSurface: Color(0xFFE0FFFF),
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
      home: const MainScreen(),
    );
  }
}
