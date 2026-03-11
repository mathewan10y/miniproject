import 'package:flutter/material.dart';
import 'reactor_core_page.dart';
import 'logistics_page.dart';
import 'flight_deck_page.dart';
import '../../gamification/services/tutorial_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../gamification/user_stats_provider.dart';
import '../../gamification/services/tutorial_engine_service.dart';
import '../../gamification/presentation/tutorials/phase1_onboarding.dart';
import '../expense_provider.dart';
import '../income_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late PageController _pageController;
  int _currentIndex = 1;

  bool _tutorialLaunched = false;

  @override
  void initState() {
    super.initState();
    // Initialize with page 1 (center/reactor core)
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userStats = ref.watch(userStatsProvider).valueOrNull;
    final devMode = ref.watch(devModeProvider);
    final canAccessFlightDeck = devMode || (userStats?.currentLevel ?? 0) >= 1;

    final expensesAsync = ref.watch(expenseProvider);
    final incomesAsync = ref.watch(incomeProvider);

    if (!expensesAsync.isLoading && !incomesAsync.isLoading && !_tutorialLaunched) {
      final engine = ref.read(tutorialEngineProvider);
      if (!engine.hasSeenPhase1) {
        _tutorialLaunched = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Extra 200ms padding to let animations / layouts settle after data is populated
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              Phase1Onboarding.start(context, ref);
            }
          });
        });
      }
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          if (index == 2 && !canAccessFlightDeck) {
            _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Access Denied - Level 1 Required. Check Codex.')),
            );
            return;
          }
          setState(() => _currentIndex = index);
        },
        children: const [
          LogisticsPage(), // Page 0 - Left
          ReactorCorePage(), // Page 1 - Center (Default)
          FlightDeckPage(), // Page 2 - Right
        ],
      ),
    );
  }
}
