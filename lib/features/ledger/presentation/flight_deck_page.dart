import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/refinery_provider.dart';
import '../../trading/data/market_service.dart';
import '../../trading/domain/models/market_asset.dart';
import '../../trading/presentation/trading_page.dart';

class FlightDeckPage extends ConsumerStatefulWidget {
  const FlightDeckPage({super.key});

  @override
  ConsumerState<FlightDeckPage> createState() => _FlightDeckPageState();
}

class _FlightDeckPageState extends ConsumerState<FlightDeckPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fuelAnimationController;
  final List<Particle> _particles = [];
  Timer? _particleTimer;

  // For the TabBar
  // No need for explicit tab controller if we use DefaultTabController in build

  @override
  void initState() {
    super.initState();
    _fuelAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Particle system loop
    _particleTimer = Timer.periodic(const Duration(milliseconds: 32), (timer) {
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
    setState(() {
      for (int i = 0; i < _particles.length; i++) {
        _particles[i] = Particle(
          position: _particles[i].position + _particles[i].velocity,
          velocity: _particles[i].velocity, // Constant velocity for now
          color: _particles[i].color.withOpacity(math.max(0, _particles[i].lifetime - 0.05)),
          size: _particles[i].size,
          lifetime: _particles[i].lifetime - 0.05,
        );
      }
      _particles.removeWhere((p) => p.lifetime <= 0);
    });
  }

  void _spawnIncomingParticles() {
    // Spawn simple effect for fuel
    final random = math.Random();
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(
        position: const Offset(150, 0), // Topish center
        velocity: Offset((random.nextDouble() - 0.5) * 5, 2 + random.nextDouble() * 5),
        color: Colors.cyanAccent,
        size: 3 + random.nextDouble() * 3,
        lifetime: 1.0,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final system = ref.watch(refineryProvider);
    final refinedFuel = system.refinedFuel;
    final assetsAsync = ref.watch(marketAssetsProvider);

    // Listen to fuel changes for animation
    ref.listen(refineryProvider, (previous, next) {
      if (next.refinedFuel > (previous?.refinedFuel ?? 0)) {
        _spawnIncomingParticles();
        _fuelAnimationController.forward(from: 0.0);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black, // Space
      body: Stack(
        children: [
          // Background Elements? (Stars etc could go here)
          
          // Main Cockpit Layout
          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // ZONE 1: The Windshield (35%)
                Expanded(
                  flex: 35,
                  child: _buildWindshield(),
                ),

                // ZONE 2: Control Panel (15%)
                Expanded(
                  flex: 15,
                  child: _buildControlPanel(refinedFuel),
                ),

                // ZONE 3: Cargo Bay (50%)
                Expanded(
                  flex: 50,
                  child: assetsAsync.when(
                    data: (assets) => _buildCargoBay(assets),
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
                    error: (err, stack) => Center(child: Text('Telemetry Error: $err', style: const TextStyle(color: Colors.red))),
                  ),
                ),
              ],
            ),
          ),
          
          // Particles Overlay
           ..._particles.map((p) => Positioned(
            left: p.position.dx + MediaQuery.of(context).size.width / 2, // Center offset
            top: p.position.dy + 100,
            child: _buildParticle(p),
          )),
        ],
      ),
    );
  }

  Widget _buildWindshield() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(bottom: BorderSide(color: Colors.white24, width: 2)),
      ),
      child: Stack(
        children: [
          // Simulated Grid/HUD
          CustomPaint(
            painter: _GridPainter(),
            child: Container(),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyan.withOpacity(0.5)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monitor_heart_outlined, color: Colors.cyan, size: 48),
                  SizedBox(height: 8),
                  Text(
                    "ACTIVE ASSET TELEMETRY",
                    style: TextStyle(
                      color: Colors.cyan,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Waiting for selection...",
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(double fuel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(top: BorderSide(color: Colors.white10), bottom: BorderSide(color: Colors.white10)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          // Fuel Display
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("FUEL RESERVES", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                Text(
                  fuel.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ],
            ),
          ),
          
          // BUY / SELL Buttons
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: _buildPanelButton("BUY", Colors.cyan, () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processing Buy Order...')));
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPanelButton("SELL", Colors.orange, () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processing Sell Order...')));
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCargoBay(List<MarketAsset> assets) {
    // Filter assets for tabs
    // Tab 1: Life Support (Commodities/Forex)
    final sectorA = assets.where((a) => a.type == AssetType.lifeSupport).toList();
    
    // Tab 2: Fleets (Indices) & Thrusters (Stocks)
    final sectorB = assets.where((a) => a.type == AssetType.thruster || a.type == AssetType.fleet).toList();
    
    // Tab 3: Warp Drive (Crypto)
    final sectorC = assets.where((a) => a.type == AssetType.warpDrive).toList();

    return Column(
      children: [
        // Tab Bar
        Container(
          color: Colors.black,
          child: const TabBar(
            indicatorColor: Colors.cyan,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 10), // Reduced font size slightly to fit
            tabs: [
              Tab(text: "SECTOR A\n(Life Support)"),
              Tab(text: "SECTOR B\n(Thrusters/Fleet)"),
              Tab(text: "SECTOR C\n(Warp Drive)"),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            children: [
              _buildAssetList(sectorA, Colors.cyan),
              _buildAssetList(sectorB, Colors.amber),
              _buildAssetList(sectorC, Colors.redAccent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssetList(List<MarketAsset> assets, Color themeColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        return _buildAssetTile(asset, themeColor);
      },
    );
  }

  Widget _buildAssetTile(MarketAsset asset, Color themeColor) {
    final isLocked = asset.isLocked(1); // Should be false now per user request
    final isPositive = asset.percentChange24h >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: isLocked ? null : () {
          // Navigate to Trading Chart
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => TradingPage(asset: asset)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLocked ? Colors.grey : themeColor.withOpacity(0.5),
              width: 1
            ),
            boxShadow: [
              if (!isLocked)
                BoxShadow(
                  color: themeColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40, 
                height: 40,
                decoration: BoxDecoration(
                  color: isLocked ? Colors.white10 : themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLocked ? Icons.lock : _getAssetIcon(asset.type),
                  color: isLocked ? Colors.grey : themeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              
              // Name & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.symbol,
                      style: TextStyle(
                        color: isLocked ? Colors.grey : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      asset.name,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              // Price or Lock Status
              if (isLocked)
                const Text(
                  "RESTRICTED",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${asset.currentPrice.toStringAsFixed(asset.currentPrice < 1 ? 4 : 2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'RobotoMono',
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Icon(
                          isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: isPositive ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        Text(
                          '${asset.percentChange24h.abs().toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAssetIcon(AssetType type) {
    switch (type) {
      case AssetType.warpDrive: return Icons.rocket_launch;
      case AssetType.thruster: return Icons.speed;
      case AssetType.fleet: return Icons.group_work; // Icon for Indices
      case AssetType.lifeSupport: return Icons.favorite;
      case AssetType.derivatives: return Icons.account_tree; // Placeholder
    }
  }

  Widget _buildParticle(Particle p) {
    return Transform.rotate(
      angle: p.rotation,
       child: Container(
        width: p.size,
        height: p.size,
        decoration: BoxDecoration(
          color: p.color,
          shape: BoxShape.rectangle, // Digital look
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.1)
      ..strokeWidth = 1;
      
    // Draw simple grid
    for(double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for(double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper class for Particles (kept local for now)
class Particle {
  final Offset position;
  final Offset velocity;
  final Color color;
  final double size;
  final double lifetime;
  final double rotation;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifetime,
  }) : rotation = (math.Random().nextDouble() - 0.5) * 2;
}
