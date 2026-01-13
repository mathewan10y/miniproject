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
  // Note: TabController logic moved to Dock

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

  // --- Modal Logic ---

  void _showSectorModal(BuildContext context, List<MarketAsset> allAssets, String sectorName, Color sectorColor, List<AssetSubType> allowedTypes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DataPadModal(
        assets: allAssets.where((a) => allowedTypes.contains(a.subType) || (sectorName == "SECTOR B" && (a.type == AssetType.thruster || a.type == AssetType.fleet))).toList(), // Loose filter for Sector B due to type mix
        sectorName: sectorName,
        sectorColor: sectorColor,
        allowedTypes: allowedTypes,
        onAssetSelected: (asset) {
          Navigator.pop(context);
          _onAssetSelected(asset);
        },
      ),
    );
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final system = ref.watch(refineryProvider);
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

          Column(
            children: [
              // ZONE 1: Telemetry Panel (Hero Chart) - Flex 8
              Expanded(
                flex: 8,
                child: _buildTelemetryPanel(),
              ),

              // ZONE 2, Part A: Fuel & Controls - Integrated into Telemetry or Dock?
              // User requested Dock at bottom. Let's put limited controls in Telemetry or a small bar.
              // Actually, user spec says: "Top (Flex 8): The Chart & Telemetry Display... Bottom (Flex 1): A custom 'Control Dock'"
              // "Control Dock" has 3 buttons for Sectors.
              // Where do BUY/SELL buttons go? 
              // Assumption: BUY/SELL controls should be Overlay or part of the Telemetry panel now to fit the "Chart Area".
              // Let's integrate simple BUY/SELL into the Chart Header for now to respect layout.

              // ZONE 3: Control Dock (The Nav) - Height ~80px (Flex 1ish)
              SizedBox(
                height: 80,
                child: assetsAsync.when(
                  data: (assets) => _buildControlDock(context, assets),
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ],
          ),
          
          // Particles Overlay
           ..._particles.map((p) => Positioned(
            left: p.position.dx + MediaQuery.of(context).size.width / 2, 
            top: p.position.dy + 100,
            child: _buildParticle(p),
          )),
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
                  "Select Sector to Initialize...",
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
         // Minimal Header for Context & Trade Controls
         Container(
           padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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
               Row(
                 children: [
                    _buildTradeButton("BUY", Colors.cyan),
                    const SizedBox(width: 8),
                    _buildTradeButton("SELL", Colors.pinkAccent),
                 ],
               )
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
         
         // Interval Selector at bottom of chart
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildIntervalSelector(),
          ),
      ],
    );
  }
  
  Widget _buildTradeButton(String label, Color color) {
    return GestureDetector(
      onTap: () {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label ${_selectedAsset!.symbol}...')));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
           color: color.withOpacity(0.2),
           border: Border.all(color: color),
           borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: GoogleFonts.orbitron(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildIntervalSelector() {
    final intervals = ['1H', '4H', '1D', '1W'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: intervals.map((interval) {
        final isSelected = _selectedInterval == interval;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedInterval = interval);
            if (_selectedAsset != null) _loadHistory(_selectedAsset!);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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


  // --- Zone 3: Control Dock ---

  Widget _buildControlDock(BuildContext context, List<MarketAsset> assets) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        border: const Border(top: BorderSide(color: Colors.white10)),
        boxShadow: [
          BoxShadow(color: Colors.cyan.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildDockButton(context, "SECTOR A", "LIFE SUPPORT", Colors.cyan, assets, [AssetSubType.bond, AssetSubType.economy, AssetSubType.fund, AssetSubType.forex])),
          const SizedBox(width: 8),
          Expanded(child: _buildDockButton(context, "SECTOR B", "THRUSTERS", Colors.amber, assets, [AssetSubType.stock, AssetSubType.marketIndex])),
          const SizedBox(width: 8),
          Expanded(child: _buildDockButton(context, "SECTOR C", "WARP DRIVE", Colors.redAccent, assets, [AssetSubType.crypto, AssetSubType.future, AssetSubType.option])),
        ],
      ),
    );
  }

  Widget _buildDockButton(BuildContext context, String label, String subLabel, Color color, List<MarketAsset> assets, List<AssetSubType> types) {
    return GestureDetector(
      onTap: () => _showSectorModal(context, assets, label, color, types),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, spreadRadius: 0)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: GoogleFonts.orbitron(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(subLabel, style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 8)),
          ],
        ),
      ),
    );
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

// --- Data Pad Modal ---

class _DataPadModal extends StatefulWidget {
  final List<MarketAsset> assets;
  final String sectorName;
  final Color sectorColor;
  final List<AssetSubType> allowedTypes;
  final Function(MarketAsset) onAssetSelected;

  const _DataPadModal({
    required this.assets, 
    required this.sectorName, 
    required this.sectorColor, 
    required this.allowedTypes, 
    required this.onAssetSelected
  });

  @override
  State<_DataPadModal> createState() => _DataPadModalState();
}

class _DataPadModalState extends State<_DataPadModal> {
  String _searchQuery = "";
  AssetSubType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    // Filter logic
    final filteredAssets = widget.assets.where((asset) {
      bool matchesSearch = asset.symbol.contains(_searchQuery.toUpperCase()) || asset.id.contains(_searchQuery.toLowerCase());
      bool matchesType = _selectedFilter == null || asset.subType == _selectedFilter;
      return matchesSearch && matchesType;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.95),
        border: Border(top: BorderSide(color: widget.sectorColor, width: 3)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.sectorName,
              style: GoogleFonts.orbitron(
                color: widget.sectorColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [BoxShadow(color: widget.sectorColor, blurRadius: 10)],
              ),
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.shareTechMono(color: Colors.white),
              decoration: InputDecoration(
                hintText: "SEARCH ASSET ID...",
                hintStyle: GoogleFonts.shareTechMono(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderSide: BorderSide(color: widget.sectorColor)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.sectorColor)),
                prefixIcon: Icon(Icons.search, color: widget.sectorColor),
              ),
            ),
          ),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: widget.allowedTypes.map((type) {
                final isSelected = _selectedFilter == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(type.name.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                         _selectedFilter = selected ? type : null;
                      });
                    },
                    backgroundColor: Colors.white10,
                    selectedColor: widget.sectorColor.withOpacity(0.3),
                    labelStyle: GoogleFonts.shareTechMono(
                      color: isSelected ? widget.sectorColor : Colors.white60,
                      fontWeight: FontWeight.bold
                    ),
                    side: BorderSide(color: isSelected ? widget.sectorColor : Colors.white10),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // List
          Expanded(
            child: ListView.builder(
              itemCount: filteredAssets.length,
              itemBuilder: (context, index) {
               final asset = filteredAssets[index];
               final isPositive = asset.percentChange24h >= 0;
               
               return ListTile(
                 onTap: () => widget.onAssetSelected(asset),
                 leading: Icon(_getAssetIcon(asset.type), color: widget.sectorColor),
                 title: Text(asset.symbol, style: GoogleFonts.orbitron(color: Colors.white)),
                 subtitle: Text(asset.name, style: GoogleFonts.shareTechMono(color: Colors.white54)),
                 trailing: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     Text('\$${asset.currentPrice.toStringAsFixed(2)}', style: GoogleFonts.shareTechMono(color: Colors.white)),
                     Text('${asset.percentChange24h.toStringAsFixed(2)}%', style: TextStyle(color: isPositive ? Colors.greenAccent : Colors.redAccent, fontSize: 12)),
                   ],
                 ),
               );
              },
            ),
          ),
        ],
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
