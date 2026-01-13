import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_chart/interactive_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/refinery_provider.dart';
import '../../trading/data/market_service.dart';
import '../../trading/domain/models/market_asset.dart';

class FlightDeckPage extends ConsumerStatefulWidget {
  const FlightDeckPage({super.key});

  @override
  ConsumerState<FlightDeckPage> createState() => _FlightDeckPageState();
}

class _FlightDeckPageState extends ConsumerState<FlightDeckPage>
    with TickerProviderStateMixin {
  late final AnimationController _fuelAnimationController;
  late final AnimationController _radarController;
  final List<Particle> _particles = [];
  Timer? _particleTimer;

  // Selection & Chart State
  MarketAsset? _selectedAsset;
  List<CandleData> _candles = [];
  bool _isLoadingHistory = false;
  String _selectedInterval = '1H';
  bool _isChartMaximized = false;

  @override
  void initState() {
    super.initState();
    _fuelAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _radarController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    // Particle system loop
    _particleTimer = Timer.periodic(const Duration(milliseconds: 32), (timer) {
      _updateParticles();
    });
  }

  @override
  void dispose() {
    _fuelAnimationController.dispose();
    _radarController.dispose();
    _particleTimer?.cancel();
    super.dispose();
  }

  void _updateParticles() {
    setState(() {
      for (int i = 0; i < _particles.length; i++) {
        _particles[i] = Particle(
          position: _particles[i].position + _particles[i].velocity,
          velocity: _particles[i].velocity, 
          color: _particles[i].color.withOpacity(math.max(0, _particles[i].lifetime - 0.05)),
          size: _particles[i].size,
          lifetime: _particles[i].lifetime - 0.05,
        );
      }
      _particles.removeWhere((p) => p.lifetime <= 0);
    });
  }

  void _spawnIncomingParticles() {
    final random = math.Random();
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(
        position: const Offset(150, 0),
        velocity: Offset((random.nextDouble() - 0.5) * 5, 2 + random.nextDouble() * 5),
        color: Colors.cyanAccent,
        size: 3 + random.nextDouble() * 3,
        lifetime: 1.0,
      ));
    }
  }

  // --- Selection Logic ---

  Future<void> _loadHistory(MarketAsset asset) async {
    setState(() {
      _isLoadingHistory = true;
      _candles = [];
    });
    try {
      final service = ref.read(marketServiceProvider);
      final history = await service.getAssetHistory(asset.id, _selectedInterval);
      if (mounted) {
         setState(() {
          _candles = history.map((h) => CandleData(
            timestamp: h.timestamp,
            open: h.open,
            close: h.close,
            high: h.high,
            low: h.low,
            volume: h.volume,
          )).toList();
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
       if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _onAssetSelected(MarketAsset asset) {
    if (_selectedAsset?.id == asset.id) return;
    setState(() {
      _selectedAsset = asset;
    });
    _loadHistory(asset);
  }

  // --- Build ---

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
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          // Background Grid Painter
          Positioned.fill(
            child: CustomPaint(
              painter: SciFiBackgroundPainter(),
            ),
          ),

          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // ZONE 1: Telemetry Panel (Windshield) - Flex 5
                Expanded(
                  flex: 5,
                  child: _buildTelemetryPanel(),
                ),

                // ZONE 2: Control Panel - Flex 2
                Expanded(
                  flex: 2,
                  child: _buildControlPanel(refinedFuel),
                ),

                // ZONE 3: Cargo Bay (Asset List) - Flex 4
                if (!_isChartMaximized)
                  Expanded(
                    flex: 4,
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
            left: p.position.dx + MediaQuery.of(context).size.width / 2, 
            top: p.position.dy + 100,
            child: _buildParticle(p),
          )),

          // Maximize Button (Top Right of Screen)
          Positioned(
            top: 40, // Below status bar
            right: 16,
            child: IconButton(
              icon: Icon(_isChartMaximized ? Icons.fullscreen_exit : Icons.fullscreen),
              color: Colors.cyanAccent,
              onPressed: () {
                setState(() {
                  _isChartMaximized = !_isChartMaximized;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Zone 1: Telemetry Panel ---

  Widget _buildTelemetryPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.cyan.withOpacity(0.1), Colors.black.withOpacity(0.8)],
        ),
      ),
      child: Stack(
        children: [
          // Tech Decorations
          Positioned(
            top: 8, left: 8,
            child: Text("SYS.MONITOR // ONLINE", style: GoogleFonts.shareTechMono(color: Colors.cyan.withOpacity(0.5), fontSize: 10)),
          ),
          Positioned(
            bottom: 8, right: 8,
            child: Text("DATA.STREAM // ACTIVE", style: GoogleFonts.shareTechMono(color: Colors.cyan.withOpacity(0.5), fontSize: 10)),
          ),

          if (_selectedAsset == null)
            _buildEmptyState()
          else
            _buildChartState(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar Animation
          AnimatedBuilder(
            animation: _radarController,
            builder: (context, child) {
              return Container(
                width: 100 + _radarController.value * 200,
                height: 100 + _radarController.value * 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.cyan.withOpacity((1.0 - _radarController.value) * 0.5), 
                    width: 2
                  ),
                ),
              );
            },
          ),
          // Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.radar, color: Colors.cyan, size: 32),
                const SizedBox(height: 8),
                Text(
                  "ACTIVE ASSET TELEMETRY",
                  style: GoogleFonts.orbitron(
                    color: Colors.cyan,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  "Scanning for signal...",
                  style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartState() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyan));
    }

    // Chart
    return Column(
      children: [
         // Minimal Header for Context
         Container(
           padding: const EdgeInsets.fromLTRB(16, 24, 48, 8),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     _selectedAsset!.symbol, 
                     style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                   ),
                   Text(
                      '\$${_selectedAsset!.currentPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.shareTechMono(
                        color: _selectedAsset!.percentChange24h >= 0 ? Colors.tealAccent : Colors.pinkAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                   ),
                 ],
               ),
               _buildIntervalSelector(),
             ],
           ),
         ),
         
         Expanded(
           child: InteractiveChart(
            candles: _candles,
            style: ChartStyle(
              priceGainColor: Colors.tealAccent,
              priceLossColor: Colors.pinkAccent,
              volumeColor: Colors.cyan.withOpacity(0.1),
              priceGridLineColor: Colors.white10,
              timeLabelStyle: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10),
              priceLabelStyle: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10),
              overlayBackgroundColor: Colors.black.withOpacity(0.8),
            ),
          ),
         ),
      ],
    );
  }

  Widget _buildIntervalSelector() {
    final intervals = ['1H', '4H', '1D', '1W'];
    return Row(
      children: intervals.map((interval) {
        final isSelected = _selectedInterval == interval;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedInterval = interval);
            if (_selectedAsset != null) _loadHistory(_selectedAsset!);
          },
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.cyan.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? Colors.cyan : Colors.white10
              ),
            ),
            child: Text(
              interval,
              style: GoogleFonts.shareTechMono(
                color: isSelected ? Colors.cyan : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }


  // --- Zone 2: Control Panel ---

  Widget _buildControlPanel(double fuel) {
    bool hasSelection = _selectedAsset != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Fuel Display
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("FUEL RESERVES", style: GoogleFonts.shareTechMono(color: Colors.cyan.withOpacity(0.7), fontSize: 10, letterSpacing: 1)),
                Text(
                  fuel.toStringAsFixed(2),
                  style: GoogleFonts.orbitron(
                    color: Colors.cyanAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [BoxShadow(color: Colors.cyan.withOpacity(0.5), blurRadius: 10)],
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
                  child: CyberButton(
                    label: hasSelection ? "BUY" : "IDLE",
                    subLabel: hasSelection ? _selectedAsset!.symbol : "--",
                    color: Colors.cyan,
                    isEnabled: hasSelection,
                    onTap: () {
                      if (hasSelection) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Buying ${_selectedAsset!.symbol}...')));
                      }
                    }
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CyberButton(
                    label: hasSelection ? "SELL" : "WAIT",
                    subLabel: hasSelection ? _selectedAsset!.symbol : "--",
                    color: Colors.pinkAccent, // Cyberpunk Red
                    isEnabled: hasSelection,
                    onTap: () {
                       if (hasSelection) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selling ${_selectedAsset!.symbol}...')));
                      }
                    }
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Zone 3: Cargo Bay ---

  Widget _buildCargoBay(List<MarketAsset> assets) {
    // Tab 1: Life Support
    final sectorA = assets.where((a) => a.type == AssetType.lifeSupport).toList();
    // Tab 2: Fleets & Thrusters
    final sectorB = assets.where((a) => a.type == AssetType.thruster || a.type == AssetType.fleet).toList();
    // Tab 3: Warp Drive
    final sectorC = assets.where((a) => a.type == AssetType.warpDrive).toList();

    return Column(
      children: [
        Container(
          color: Colors.black.withOpacity(0.5),
          child: TabBar(
            indicatorColor: Colors.cyan,
            labelColor: Colors.cyanAccent,
            unselectedLabelColor: Colors.white38,
            labelStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 10),
            tabs: const [
              Tab(text: "SECTOR A\n(Life Support)"),
              Tab(text: "SECTOR B\n(Thrusters/Fleet)"),
              Tab(text: "SECTOR C\n(Warp Drive)"),
            ],
          ),
        ),
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
    final isLocked = asset.isLocked(1); 
    final isPositive = asset.percentChange24h >= 0;
    final isSelected = _selectedAsset?.id == asset.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: isLocked ? null : () {
          _onAssetSelected(asset);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? themeColor.withOpacity(0.15) : Colors.black26,
            borderRadius: BorderRadius.circular(4), // More angular for sci-fi
            border: Border.all(
              color: isLocked ? Colors.grey : (isSelected ? themeColor : themeColor.withOpacity(0.2)),
              width: isSelected ? 2 : 1
            ),
          ),
          child: Row(
            children: [
             Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isLocked ? Colors.white10 : themeColor.withOpacity(0.1),
                  // shape: BoxShape.circle, // Changing to angled square
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isLocked ? Icons.lock : _getAssetIcon(asset.type),
                  color: isLocked ? Colors.grey : themeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.symbol, style: GoogleFonts.orbitron(color: isLocked ? Colors.grey : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(asset.name, style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              if (isLocked)
                Text("RESTRICTED", style: GoogleFonts.shareTechMono(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${asset.currentPrice.toStringAsFixed(asset.currentPrice < 1 ? 4 : 2)}', style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${asset.percentChange24h.abs().toStringAsFixed(2)}%', style: GoogleFonts.shareTechMono(color: isPositive ? Colors.tealAccent : Colors.pinkAccent, fontSize: 12)),
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
      case AssetType.fleet: return Icons.group_work;
      case AssetType.lifeSupport: return Icons.favorite;
      case AssetType.derivatives: return Icons.account_tree;
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
          shape: BoxShape.rectangle,
        ),
      ),
    );
  }
}

// --- Sci-Fi Painters & Widgets ---

class SciFiBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.1)
      ..strokeWidth = 1;

    // Grid
    double step = 40.0;
    
    // Vertical lines
    for(double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Horizontal lines (with fading opacity)
    for(double y = 0; y <= size.height; y += step) {
      double opacity = 0.05 + (y / size.height) * 0.1; // Darker at top, slightly brighter at bottom? Or reverse
      paint.color = Colors.cyan.withOpacity(opacity);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CyberButton extends StatelessWidget {
  final String label;
  final String subLabel;
  final Color color;
  final bool isEnabled;
  final VoidCallback onTap;

  const CyberButton({
    super.key,
    required this.label,
    required this.subLabel,
    required this.color,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: ClipPath(
        clipper: CutCornerClipper(),
        child: Container(
          height: 60,
          color: isEnabled ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.05),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: isEnabled ? color : Colors.white10, width: 2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.orbitron(
                    color: isEnabled ? color : Colors.white24,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    shadows: isEnabled ? [BoxShadow(color: color, blurRadius: 8)] : [],
                  ),
                ),
                Text(
                  subLabel,
                  style: GoogleFonts.shareTechMono(
                    color: isEnabled ? Colors.white70 : Colors.white12,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CutCornerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    double cut = 12.0;

    path.moveTo(cut, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - cut);
    path.lineTo(size.width - cut, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, cut);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

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
