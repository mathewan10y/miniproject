import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:async';
import '../../../core/providers/refinery_provider.dart';

class FlightDeckPage extends ConsumerStatefulWidget {
  const FlightDeckPage({super.key});

  @override
  ConsumerState<FlightDeckPage> createState() => _FlightDeckPageState();
}

class _FlightDeckPageState extends ConsumerState<FlightDeckPage>
    with TickerProviderStateMixin {
  late AnimationController _fuelAnimationController;
  late Animation<double> _fuelAnimation;
  double _previousFuelAmount = 0.0;
  bool _shouldAnimate = false;

  // Particle System
  final List<Particle> _particles = [];
  Timer? _particleTimer;

  @override
  void initState() {
    super.initState();
    _fuelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fuelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fuelAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Start particle loop
    _particleTimer = Timer.periodic(const Duration(milliseconds: 32), (_) {
      _updateParticles();
    });
  }

  @override
  void dispose() {
    _fuelAnimationController.dispose();
    _particleTimer?.cancel();
    super.dispose();
  }
  
  void _updateParticles() {
    if (!mounted || _particles.isEmpty) return;
    
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    setState(() {
      _particles.removeWhere((p) => now - p.createdAt > p.lifetime);
    });
  }

  void _spawnIncomingParticles() {
    // Spawn particles from left edge flowing to center
    for (int i = 0; i < 15; i++) {
       final startY = 150.0 + (math.Random().nextDouble() - 0.5) * 100; // Near Trading Power card height
       _particles.add(Particle(
         position: Offset(-20, startY), // Start off-screen left
         velocity: Offset(400 + math.Random().nextDouble() * 200, (math.Random().nextDouble() - 0.5) * 50),
         color: Colors.cyan.withOpacity(0.8),
         size: 8.0 + math.Random().nextDouble() * 8.0,
         lifetime: 1.5,
       ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final refineryState = ref.watch(refineryProvider);
    final currentFuel = refineryState.refinedFuel;
    
    // Check if fuel amount increased (user just finished refining)
    if (currentFuel > _previousFuelAmount && _previousFuelAmount > 0) {
      _shouldAnimate = true;
      _fuelAnimationController.forward(from: 0.0);
      _spawnIncomingParticles(); // Trigger particles
    } else if (currentFuel > 0 && _previousFuelAmount == 0) {
       // Initial load with fuel - show effect too
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted && _particles.isEmpty) {
            _spawnIncomingParticles();
         }
       });
    }
    
    // Update previous amount after checking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _previousFuelAmount = currentFuel;
    });
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.asset('lib/assets/bg_right.jpg', fit: BoxFit.cover),
        // Dark overlay
        Container(color: Colors.black.withOpacity(0.5)),
        // Particles Layer (behind content)
        ..._particles.map((p) => _buildParticle(p)),
        // Main content
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'FLIGHT DECK',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    letterSpacing: 2,
                  ),
                ),
              ),
              // Trading Power Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildGlassmorphContainer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'TRADING POWER',
                        style: TextStyle(
                          color: Color(0xFF00D9FF),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Animated fuel display
                      AnimatedBuilder(
                        animation: _fuelAnimation,
                        builder: (context, child) {
                          double displayFuel = currentFuel;
                          
                          // Apply animation if fuel just increased
                          if (_shouldAnimate) {
                            final fuelDifference = currentFuel - _previousFuelAmount;
                            displayFuel = _previousFuelAmount + (fuelDifference * _fuelAnimation.value);
                            
                            // Reset animation flag when complete
                            if (_fuelAnimation.isCompleted) {
                              _shouldAnimate = false;
                            }
                          }
                          
                          return Column(
                            children: [
                              Text(
                                _formatFuelAmount(displayFuel),
                                style: TextStyle(
                                  color: _shouldAnimate 
                                    ? Colors.yellow 
                                    : Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              if (_shouldAnimate)
                                Text(
                                  'FUEL ADDED',
                                  style: TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              label: 'BUY',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Buy feature coming soon'),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              label: 'SELL',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sell feature coming soon'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Stock Market Interface Placeholder
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MARKET OVERVIEW',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00D9FF),
                          letterSpacing: 2,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildGlassmorphContainer(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // Placeholder graph
                                Expanded(
                                  child: Center(
                                    child: CustomPaint(
                                      size: const Size(
                                        double.infinity,
                                        double.infinity,
                                      ),
                                      painter: _StockChartPainter(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Stock list placeholder
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStockTicker(
                                      symbol: 'TECH',
                                      price: '\$1,234.50',
                                      change: '+2.5%',
                                      changePositive: true,
                                    ),
                                    _buildStockTicker(
                                      symbol: 'FINX',
                                      price: '\$856.30',
                                      change: '-1.2%',
                                      changePositive: false,
                                    ),
                                    _buildStockTicker(
                                      symbol: 'COIN',
                                      price: '\$45,678.00',
                                      change: '+5.8%',
                                      changePositive: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassmorphContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF00D9FF), width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF00D9FF),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockTicker({
    required String symbol,
    required String price,
    required String change,
    required bool changePositive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          symbol,
          style: const TextStyle(
            color: Color(0xFFBBDEFF),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          price,
          style: const TextStyle(
            color: Color(0xFFE0FFFF),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          change,
          style: TextStyle(
            color: changePositive ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Format fuel amount with proper thousands separators and "FUEL" suffix
  String _formatFuelAmount(double amount) {
    final buffer = StringBuffer();
    final String amountStr = amount.toStringAsFixed(2);
    final parts = amountStr.split('.');
    
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';
    
    // Add commas to integer part
    int len = integerPart.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
    }
    
    buffer.write(decimalPart);
    buffer.write(' FUEL');
    return buffer.toString();
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
          angle: particle.rotation * age,
          child: Container(
            width: particle.size,
            height: particle.size,
            decoration: BoxDecoration(
              color: particle.color,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(2),
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
}

class _StockChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF00D9FF).withOpacity(0.6)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    // Draw a simple wavy line to represent stock chart
    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double x = 0; x <= size.width; x += 20) {
      final y =
          size.height * 0.5 +
          (40 * (x / size.width - 0.5) * (x / size.width - 0.5) - 10);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Draw grid
    final gridPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..strokeWidth = 0.5;

    // Vertical grid lines
    for (double x = 0; x <= size.width; x += size.width / 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Horizontal grid lines
    for (double y = 0; y <= size.height; y += size.height / 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_StockChartPainter oldDelegate) => false;
}

// Reuse Particle class definition
// (We could move this to a shared file, but for now duplicate to keep file self-contained as requested by previous patterns)
class Particle {
  final Offset position;
  final Offset velocity;
  final Color color;
  final double size;
  final double lifetime;
  final double createdAt;
  final double rotation;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifetime,
  }) : createdAt = DateTime.now().millisecondsSinceEpoch / 1000.0,
       rotation = (math.Random().nextDouble() - 0.5) * 5;
}
