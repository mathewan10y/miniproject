import 'package:flutter/material.dart';
import 'reactor_core_page.dart';
import 'logistics_page.dart';
import 'flight_deck_page.dart';
// tutorial_keys only used by Phase1Onboarding internally
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../gamification/user_stats_provider.dart';
import '../../gamification/services/tutorial_engine_service.dart';
import '../../gamification/data/tutorial_scripts.dart';
import '../../gamification/presentation/widgets/tutorial_overlay_widget.dart';
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
  // _currentIndex removed — not needed, PageView is the source of truth

  bool _tutorialLaunched = false;

  void _checkAndShowTutorial(int pageIndex) {
    // Add a small delay to allow the swipe animation to visually settle
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      final engine = ref.read(tutorialEngineProvider);
      List<DialogNode>? script;
      VoidCallback? onCompleteAction;

      // Page indices: 0=Logistics, 1=ReactorCore, 2=FlightDeck
      if (pageIndex == 1 && !engine.hasSeenReactorTutorial) {
        script = TutorialScripts.reactorCoreIntro;
        onCompleteAction = () => engine.markReactorTutorialSeen();
      } else if (pageIndex == 2 && !engine.hasSeenFlightDeckTutorial) {
        script = TutorialScripts.flightDeckIntro;
        onCompleteAction = () => engine.markFlightDeckTutorialSeen();
      } else if (pageIndex == 0 && !engine.hasSeenLogisticsTutorial) {
        script = TutorialScripts.logisticsIntro;
        onCompleteAction = () => engine.markLogisticsTutorialSeen();
      }

      if (script != null && onCompleteAction != null) {
        showGeneralDialog(
          context: context,
          barrierColor: const Color(0x44000000), // More transparent dark tint (26% opacity), NO BLUR
          barrierDismissible: false,
          pageBuilder: (ctx, anim1, anim2) => Scaffold(
            backgroundColor: Colors.transparent,
            body: TutorialOverlayWidget(
              dialogs: script!,
              onComplete: () {
                if (ctx.mounted) Navigator.of(ctx).pop();
                onCompleteAction!();
              },
            ),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize with page 1 (center/reactor core)
    _pageController = PageController(initialPage: 1);
    
    // Trigger tutorial for initial page after data loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _checkAndShowTutorial(1); // Reactor Core (page 1)
      });
    });
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
        // Tutorial temporarily disabled to prevent rendering crash
        /*
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Capture context before async gap to avoid use_build_context_synchronously
            final ctx = context;
            // Extra 200ms padding to let animations / layouts settle after data is populated
            Future.delayed(const Duration(milliseconds: 200), () {
              if (!mounted) return;
              Phase1Onboarding.start(ctx, ref);
            });
        });
        */
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
          setState(() {/* page changed */});
          _checkAndShowTutorial(index); // Check for tutorial after successful page change
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
