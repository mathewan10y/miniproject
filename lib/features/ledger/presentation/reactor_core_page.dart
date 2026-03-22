import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../expense_provider.dart';
import '../income_provider.dart';
import '../../../widgets/reactor_gauge.dart';
import '../../../core/providers/refinery_provider.dart';
import '../../gamification/presentation/widgets/top_bar.dart';
import '../../gamification/presentation/widgets/levels_panel.dart';
import '../../gamification/services/tutorial_keys.dart';

class ReactorCorePage extends ConsumerStatefulWidget {
  const ReactorCorePage({super.key});

  @override
  ConsumerState<ReactorCorePage> createState() => _ReactorCorePageState();
}

class _ReactorCorePageState extends ConsumerState<ReactorCorePage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _refineController;
  late Animation<double> _refineAnimation;

  // Refinery state
  Timer? _refineryTimer;
  Timer? _fuelConversionTimer;
  bool _isRefining = false;
  bool _isCriticalHit = false;
  bool _isDisposed = false;
  List<Particle> _particles = [];
  List<CriticalText> _criticalTexts = [];
  
  // Animation state
  double _pendingFuel = 0.0;
  double _convertedFuel = 0.0;
  double _visualOreLevel = 0.0; // For smooth reactor core draining animation

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _refineController = AnimationController(
      duration: const Duration(milliseconds: 1400), // 1.4 seconds to drain 10% from reactor core
      vsync: this,
    );
    
    _refineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refineController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _refineryTimer?.cancel();
    _fuelConversionTimer?.cancel();
    _pulseController.dispose();
    _refineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseProvider);
    final incomesAsync = ref.watch(incomeProvider);
    // Unwrap AsyncValue — shows persisted values or zero defaults while loading
    final refineryState = ref.watch(refineryProvider).valueOrNull;

    return expensesAsync.when(
      data: (expenses) {
        return incomesAsync.when(
          data: (incomes) {
            final rawOre = refineryState?.rawOre ?? 0;

            // Calculate ore level for reactor gauge (0-1 based on raw ore)
            // Use visual ore level during animation for smooth draining effect
            double displayOre = _isRefining ? _visualOreLevel : rawOre.toDouble();
            double oreLevel = (displayOre / 10000.0).clamp(
              0.0,
              1.0,
            ); // Max 10000 ore for full reactor

            return Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                Image.asset('lib/assets/bg_center.jpg', fit: BoxFit.cover),
                // Dark overlay for readability
                Container(color: Colors.black.withOpacity(0.5)),
                // Main content - centered layout with SafeArea to prevent overflow
                SafeArea(
                  child: Column(
                    children: [
                      const TopBar(title: "REACTOR CORE", showCodex: true),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Reactor size: 70% of available height, but never wider than 85% of width
                            final reactorSize = (constraints.maxHeight * 0.70)
                                .clamp(180.0, constraints.maxWidth * 0.85);
                            return Center(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // UNREFINED ORE display (above reactor)
                                    _buildHolographicContainer(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'RAW ORE',
                                            style: TextStyle(
                                              color: Color(0xFF00D9FF),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Column(
                                            children: [
                                              Text(
                                                '$rawOre',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'REFINERY EFFICIENCY: 80%',
                                                style: TextStyle(
                                                  color: Color(0xFF00B8D4),
                                                  fontSize: 12,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Reactor core with pulse animation
                                    ScaleTransition(
                                      scale: _pulseAnimation,
                                      child: SizedBox(
                                        width: reactorSize,
                                        height: reactorSize,
                                        child: Container(
                                          key: TutorialKeys.reactorCenterKey(),
                                          child: ReactorGauge(
                                            key: TutorialKeys.reactorGaugeKey(),
                                            fillPercent: oreLevel,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Space for the refine button below
                                    const SizedBox(height: 120),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Particle effects overlay
                ..._particles.map((particle) => _buildParticle(particle)),
                // Critical hit texts
                ..._criticalTexts.map((text) => _buildCriticalText(text)),
                // Hold to refine button
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(child: _buildRefineButton()),
                ),

                // Chat Overlay
                const BotChatPanel(),

                // Levels Panel — top-most overlay so it floats over all content
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: LevelsPanel(),
                ),
              ],
            );
          },
          loading: () => _buildLoadingScreen(),
          error: (err, stack) => _buildErrorScreen(err.toString()),
        );
      },
      loading: () => _buildLoadingScreen(),
      error: (err, stack) => _buildErrorScreen(err.toString()),
    );
  }

  Widget _buildHolographicContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.4 * 255).toInt()),
        border: Border.all(color: const Color(0xFF00D9FF), width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9FF).withAlpha((0.1 * 255).toInt()),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLoadingScreen() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('lib/assets/bg_center.jpg', fit: BoxFit.cover),
        Container(color: Colors.black.withOpacity(0.5)),
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorScreen(String error) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('lib/assets/bg_center.jpg', fit: BoxFit.cover),
        Container(color: Colors.black.withOpacity(0.5)),
        Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  // Refinery Methods
  void _processSingleTap() {
    if (_isRefining) return; // Brief debounce to prevent animation clipping

    final refineryNotifier = ref.read(refineryProvider.notifier);
    final refineryState = ref.read(refineryProvider).valueOrNull;
    final currentOre = refineryState?.rawOre ?? 0;

    if (currentOre <= 0) return; // Nothing to refine

    // Process up to 1000 ore per tap (10% of max capacity)
    final int oreToConsume = math.min(currentOre, 1000);
    final double fuelAdded = oreToConsume * 0.8; // 80% Efficiency

    setState(() {
      _isRefining = true;
      _pendingFuel = fuelAdded;
      _convertedFuel = 0.0;
      _visualOreLevel = currentOre.toDouble(); // Store starting ore level for animation
    });

    // Start the reactor core draining animation
    _refineController.reset();
    _refineController.forward();
    
    // Cancel any existing conversion timer
    _fuelConversionTimer?.cancel();
    
    // Handle gamification (20% chance for critical hit visuals)
    final bool isCritical = math.Random().nextDouble() < 0.20;
    
    if (isCritical) {
      setState(() => _isCriticalHit = true);
      _addCriticalText();
    }
    
    // Create smooth draining effect over 1.4 seconds with 10 frames
    _fuelConversionTimer = Timer.periodic(const Duration(milliseconds: 140), (timer) {
      if (!mounted || _refineController.isDismissed) {
        timer.cancel();
        return;
      }
      
      final animationProgress = _refineAnimation.value;
      final oreToDrain = oreToConsume / 10.0; // Divide 10% into 10 equal frames
      
      if (oreToDrain > 0.1) { // Only drain if there's a meaningful amount
        // Actually consume the ore in real-time for each frame
        refineryNotifier.processRefinementTickWithAmount(oreToDrain.toInt(), 0.0);
        
        // Update visual ore level to match actual state
        final currentState = ref.read(refineryProvider).valueOrNull;
        setState(() {
          _visualOreLevel = currentState?.rawOre?.toDouble() ?? _visualOreLevel;
        });
        
        // Spawn particles at each frame for continuous visual feedback
        _spawnParticles(isCritical);
      }
      
      // When animation is complete, add the fuel and stop particles
      if (animationProgress >= 1.0) {
        timer.cancel();
        
        // Add the fuel after all ore is consumed
        refineryNotifier.processRefinementTickWithAmount(0, fuelAdded);
        
        setState(() {
          _convertedFuel = fuelAdded;
        });
        
        // Immediately clear all particles when refinement completes
        setState(() {
          _particles.clear();
          _criticalTexts.clear();
        });
        
        HapticFeedback.heavyImpact();
      } else {
        // Light haptic feedback during animation
        HapticFeedback.selectionClick();
      }
    });

    HapticFeedback.mediumImpact(); 

    // Reset after animation completes
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _isRefining = false;
          _isCriticalHit = false;
          _pendingFuel = 0.0;
          _convertedFuel = 0.0;
          _visualOreLevel = 0.0;
        });
        _cleanupParticles();
      }
    });
  }

  void _spawnParticles(bool isCritical) {
    if (!mounted) return;
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate exact reactor position based on layout
    // Reactor is centered in the available space (below TopBar, above button)
    final topBarHeight = 75.0; // TopBar height
    final buttonAreaHeight = 120.0; // Space for refine button
    final availableHeight = screenSize.height - topBarHeight - buttonAreaHeight;
    final reactorY = topBarHeight + (availableHeight / 2) + 80.0; // Move down 80px from exact center
    final reactorX = screenSize.width / 2; // Center horizontally
    
    final reactorPosition = Offset(reactorX, reactorY);

    // Spawn cyan/gold particles flowing to the right side tab
    for (int i = 0; i < 4; i++) {
      // Increased count slightly
      // Strong positive X velocity (300 to 600) to ensure they fly off screen
      final velocityX = 300 + math.Random().nextDouble() * 300;
      // Spread vertical velocity (-100 to 100)
      final velocityY = (math.Random().nextDouble() - 0.5) * 200;

      _particles.add(
        Particle(
          position: reactorPosition,
          velocity: Offset(velocityX, velocityY),
          color: isCritical ? Colors.yellow : Colors.cyan.withOpacity(0.8),
          size:
              isCritical
                  ? 12.0
                  : 8.0 +
                      math.Random().nextDouble() * 8.0, // Bigger size (8-16)
          lifetime: 1.5, // Reduced lifetime to prevent persistence after refinement
        ),
      );
    }

    // Spawn waste smoke particles drifting down/right (only for non-critical)
    if (!isCritical) {
      for (int i = 0; i < 2; i++) {
        final velocityX = 50 + math.Random().nextDouble() * 50;
        final velocityY = 50 + math.Random().nextDouble() * 50;

        _particles.add(
          Particle(
            position: reactorPosition,
            velocity: Offset(velocityX, velocityY),
            color: Colors.grey.withOpacity(0.4),
            size: 15.0, // Bigger smoke
            lifetime: 2.0, // Reduced lifetime for smoke particles
          ),
        );
      }
    }
  }

  void _addCriticalText() {
    if (!mounted) return;
    final screenSize = MediaQuery.of(context).size;
    _criticalTexts.add(
      CriticalText(
        position: Offset(screenSize.width / 2, screenSize.height / 2),
        text: '+CRIT',
      ),
    );
  }

  void _cleanupParticles() {
    if (!mounted) return;
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;

    // Only cleanup if not actively refining (particles are cleared immediately on completion)
    if (!_isRefining) {
      _particles.removeWhere(
        (particle) => now - particle.createdAt > particle.lifetime * 0.8, // Remove at 80% of lifetime
      );

      _criticalTexts.removeWhere((text) => now - text.createdAt > 1.0); // Remove critical texts sooner
    }

    if (_particles.isNotEmpty || _criticalTexts.isNotEmpty) {
      setState(() {});
    }
  }

  Widget _buildRefineButton() {
    // Colors shift between idle (cyan) and active refining (amber/orange)
    final idleGradient = const LinearGradient(
      colors: [Color(0xFF006064), Color(0xFF00E5FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final activeGradient = LinearGradient(
      colors:
          _isCriticalHit
              ? [const Color(0xFF7A2800), Colors.yellow]
              : [const Color(0xFF7A4000), const Color(0xFFFF9800)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final activeColor =
        _isCriticalHit ? Colors.yellow : const Color(0xFFFF9800);
    final idleColor = const Color(0xFF00D9FF);
    final borderColor = _isRefining ? activeColor : idleColor;
    final glowColor = borderColor.withOpacity(0.35);

    return GestureDetector(
      onTap: _processSingleTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.5,
          minWidth: 160,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              // Match logistics button padding
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:
                    _isRefining
                        ? activeColor.withOpacity(0.15)
                        : idleColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: borderColor.withOpacity(0.45),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.22),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Gradient icon circle (44x44 matches logistics page)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _isRefining ? activeGradient : idleGradient,
                        boxShadow: [
                          BoxShadow(
                            color: borderColor.withOpacity(0.50),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRefining
                            ? Icons.flash_on_rounded
                            : Icons.science_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Labels
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _isRefining ? 'REFINING...' : 'REFINE',
                            key: ValueKey(_isRefining ? 'active' : 'idle'),
                            style: TextStyle(
                              color:
                                  _isRefining
                                      ? activeColor
                                      : idleColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        Text(
                          '1000 Ore per tap',
                          style: TextStyle(
                            color: borderColor.withOpacity(0.6),
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticle(Particle particle) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final age = now - particle.createdAt;
    final progress = age / particle.lifetime;

    final currentPosition = Offset(
      particle.position.dx + particle.velocity.dx * age,
      particle.position.dy + particle.velocity.dy * age,
    );

    return Positioned(
      left: currentPosition.dx,
      top: currentPosition.dy,
      child: Opacity(
        opacity: (1.0 - progress).clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: particle.rotation * age, // Rotate over time
          child: Container(
            width: particle.size,
            height: particle.size,
            decoration: BoxDecoration(
              color: particle.color,
              shape: BoxShape.rectangle, // Flaky look (square)
              borderRadius: BorderRadius.circular(
                2,
              ), // Slightly rounded corners
              boxShadow: [
                BoxShadow(
                  color: particle.color,
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCriticalText(CriticalText text) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final age = now - text.createdAt;
    final progress = age / 1.5;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      left: text.position.dx - 40,
      top: text.position.dy - (age * 100),
      child: Opacity(
        opacity: (1.0 - progress).clamp(0.0, 1.0),
        child: Text(
          text.text,
          style: const TextStyle(
            color: Colors.yellow,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [Shadow(color: Colors.yellow, blurRadius: 10)],
          ),
        ),
      ),
    );
  }
}

class Particle {
  final Offset position;
  final Offset velocity;
  final Color color;
  final double size;
  final double lifetime;
  final double createdAt;
  final double rotation; // Added rotation speed

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifetime,
  }) : createdAt = DateTime.now().millisecondsSinceEpoch / 1000.0,
       rotation =
           (math.Random().nextDouble() - 0.5) * 5; // Random rotation speed
}

class CriticalText {
  final Offset position;
  final String text;
  final double createdAt;

  CriticalText({required this.position, required this.text})
    : createdAt = DateTime.now().millisecondsSinceEpoch / 1000.0;
}
