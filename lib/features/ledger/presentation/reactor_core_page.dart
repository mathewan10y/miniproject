import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../expense_provider.dart';
import '../income_provider.dart';
import '../../../widgets/reactor_gauge.dart';
import '../../../core/providers/refinery_provider.dart';

class ReactorCorePage extends ConsumerStatefulWidget {
  const ReactorCorePage({super.key});

  @override
  ConsumerState<ReactorCorePage> createState() => _ReactorCorePageState();
}

class _ReactorCorePageState extends ConsumerState<ReactorCorePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Refinery state
  Timer? _refineryTimer;
  bool _isRefining = false;
  bool _isCriticalHit = false;
  List<Particle> _particles = [];
  List<CriticalText> _criticalTexts = [];
  
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
  }

  @override
  void dispose() {
    _refineryTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseProvider);
    final incomesAsync = ref.watch(incomeProvider);
    final refineryState = ref.watch(refineryProvider);

    return expensesAsync.when(
      data: (expenses) {
        return incomesAsync.when(
          data: (incomes) {
            // Use RefinerySystem data instead of calculating from income/expenses
            final rawOre = refineryState.rawOre;
            final refinedFuel = refineryState.refinedFuel;
            final totalSavings = refineryState.totalSavings;
            
            // Calculate ore level for reactor gauge (0-1 based on raw ore)
            double oreLevel = (rawOre / 1000.0).clamp(0.0, 1.0); // Max 1000 ore for full reactor

            return Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                Image.asset('lib/assets/bg_center.jpg', fit: BoxFit.cover),
                // Dark overlay for readability
                Container(color: Colors.black.withOpacity(0.5)),
                // Main content - centered layout
                Center(
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
                              // Display raw ore value from RefinerySystem
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
                                  Text(
                                    'REFINERY EFFICIENCY: 80%',
                                    style: const TextStyle(
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
                        // Reactor core with pulse animation and responsive sizing
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Builder(
                            builder: (context) {
                              final screenWidth = MediaQuery.of(context).size.width;
                              final reactorWidth = screenWidth * 0.8;

                              return Container(
                                width: reactorWidth,
                                child: ReactorGauge(
                                  fillPercent: oreLevel,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                // Top label
                Positioned(
                  top: 40,
                  left: 30,
                  child: Text(
                    'REACTOR CORE',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      letterSpacing: 3,
                      fontSize: 20,
                    ),
                  ),
                ),
                // Particle effects overlay
                ..._particles.map((particle) => _buildParticle(particle)),
                // Critical hit texts
                ..._criticalTexts.map((text) => _buildCriticalText(text)),
                // Hold to refine button
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildRefineButton(),
                  ),
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
        color: Colors.black.withOpacity(0.4),
        border: Border.all(color: const Color(0xFF00D9FF), width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9FF).withOpacity(0.5),
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
  void _startRefining() {
    if (_refineryTimer != null) return;
    
    // STRICT HOLD: No immediate state change. Timer only.
    _refineryTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Update UI state on first tick
      if (!_isRefining) {
        setState(() {
          _isRefining = true;
        });
      }
      
      _processRefinementTick();
    });
  }

  void _stopRefining() {
    _refineryTimer?.cancel();
    _refineryTimer = null;
    
    if (mounted) {
      setState(() {
        _isRefining = false;
        _isCriticalHit = false;
      });
    }
  }

  void _processRefinementTick() {
    if (!mounted) return;

    final refineryNotifier = ref.read(refineryProvider.notifier);
    final refineryState = ref.read(refineryProvider);
    
    // Stop if no ore left
    if (refineryState.rawOre <= 0) {
      _stopRefining();
      return;
    }
    
    // Use the existing processRefinementTick method which consumes 10 ore
    final result = refineryNotifier.processRefinementTick();
    
    if (result.fuelAdded > 0) {
      // Trigger haptic feedback
      HapticFeedback.lightImpact(); // Lighter impact for rapid fire
      
      // Handle critical hit
      if (result.isCritical) {
        if (mounted) {
          setState(() {
            _isCriticalHit = true;
          });
        }
        
        // Flash effect
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _isCriticalHit = false;
            });
          }
        });
        
        // Add critical text
        _addCriticalText();
      }
      
      // Spawn particles
      _spawnParticles(result.isCritical);
    }
    
    // Clean up old particles and texts
    _cleanupParticles();
  }

  void _spawnParticles(bool isCritical) {
    if (!mounted) return;
    final screenSize = MediaQuery.of(context).size;
    final buttonPosition = Offset(screenSize.width / 2, screenSize.height - 100);
    
    // Spawn cyan/gold particles moving right
    for (int i = 0; i < 3; i++) {
      _particles.add(Particle(
        position: buttonPosition,
        velocity: Offset(200 + math.Random().nextDouble() * 100, -50 + math.Random().nextDouble() * 100),
        color: isCritical ? Colors.yellow : Colors.cyan,
        size: isCritical ? 8.0 : 6.0,
        lifetime: 2.0,
      ));
    }
    
    // Spawn waste smoke particles drifting down (only for non-critical)
    if (!isCritical) {
      for (int i = 0; i < 2; i++) {
        _particles.add(Particle(
          position: buttonPosition,
          velocity: Offset(-20 + math.Random().nextDouble() * 40, 50 + math.Random().nextDouble() * 50),
          color: Colors.grey.withOpacity(0.6), // Fixed opacity within bounds
          size: 10.0,
          lifetime: 3.0,
        ));
      }
    }
  }

  void _addCriticalText() {
    if (!mounted) return;
    final screenSize = MediaQuery.of(context).size;
    _criticalTexts.add(CriticalText(
      position: Offset(screenSize.width / 2, screenSize.height / 2),
      text: '+CRIT',
    ));
  }

  void _cleanupParticles() {
    if (!mounted) return;
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    _particles.removeWhere((particle) => 
      now - particle.createdAt > particle.lifetime
    );
    
    _criticalTexts.removeWhere((text) => 
      now - text.createdAt > 1.5
    );
    
    if (_particles.isNotEmpty || _criticalTexts.isNotEmpty) {
      setState(() {});
    }
  }

  Widget _buildRefineButton() {
    return GestureDetector(
      onTapDown: (_) => _startRefining(),
      onTapUp: (_) => _stopRefining(),
      onTapCancel: () => _stopRefining(),
      child: Container(
        width: 300, // Increased width from 280 to 300
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          image: const DecorationImage(
            image: AssetImage('lib/assets/button.png'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D9FF).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            _isRefining ? 'REFINING...' : 'HOLD TO REFINE',
            style: TextStyle(
              color: _isRefining 
                ? (_isCriticalHit ? Colors.yellow : Colors.white)
                : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
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
        opacity: 1.0 - progress,
        child: Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            color: particle.color,
            shape: BoxShape.circle,
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
        opacity: 1.0 - progress,
        child: Text(
          text.text,
          style: const TextStyle(
            color: Colors.yellow,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: Colors.yellow,
                blurRadius: 10,
              ),
            ],
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

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifetime,
  }) : createdAt = DateTime.now().millisecondsSinceEpoch / 1000.0;
}

class CriticalText {
  final Offset position;
  final String text;
  final double createdAt;

  CriticalText({
    required this.position,
    required this.text,
  }) : createdAt = DateTime.now().millisecondsSinceEpoch / 1000.0;
}
