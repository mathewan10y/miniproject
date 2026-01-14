import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/refinery_provider.dart';
import '../../trading/data/market_service.dart';
import '../../trading/domain/models/market_asset.dart';
import 'flight_deck_page_wickpainter.dart';

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
  List<MockCandle> _candles = [];
  
  // Trade State
  TradeMode _tradeMode = TradeMode.none; 
  double? _entryPrice; // Fixed price where trade started/setup
  double? _slPrice;
  double? _tpPrice;
  
  // Drag State
  bool _isDraggingSL = false;
  bool _isDraggingTP = false;

  // Visuals
  Offset? _cursorPos; // Crosshair cursor position

  // Zoom/Pan State
  int _visibleCandleCount = 30;
  double _scrollOffset = 0.0; // Index based scroll
  final DraggableScrollableController _sheetController = DraggableScrollableController();


  bool _isLoadingHistory = false;
  String _selectedInterval = '1H';

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
          rotation: _particles[i].rotation + 0.1,
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
        rotation: random.nextDouble() * math.pi * 2,
        lifetime: 1.0,
      ));
    }
  }

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
          _candles = history;
          _isLoadingHistory = false;
          _resetTrade();
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
      _resetTrade();
    });
    _loadHistory(asset);
  }
  
  void _resetTrade() {
    _tradeMode = TradeMode.none;
    _entryPrice = null;
    _slPrice = null; 
    _tpPrice = null;
  }

  void _showSectorModal(BuildContext context, List<MarketAsset> allAssets, String sectorName, Color sectorColor, List<AssetSubType> allowedTypes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DataPadModal(
        assets: allAssets.where((a) => allowedTypes.contains(a.subType) || (sectorName == "SECTOR B" && (a.type == AssetType.thruster || a.type == AssetType.fleet))).toList(),
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

  @override
  Widget build(BuildContext context) {
    final system = ref.watch(refineryProvider);
    final assetsAsync = ref.watch(marketAssetsProvider);

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
          Positioned.fill(
            child: CustomPaint(
              painter: SciFiBackgroundPainter(),
            ),
          ),

          Column(
            children: [
              Expanded(
                flex: 8,
                child: _buildTelemetryPanel(),
              ),
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
          
           ..._particles.map((p) => Positioned(
            left: p.position.dx + MediaQuery.of(context).size.width / 2, 
            top: p.position.dy + 100,
            child: _buildParticle(p),
          )),
        ],
      ),
    );
  }

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
    if (_candles.isEmpty) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
         final int totalCandles = _candles.length;
         
         // 1. Zoom & Scroll Limits
         _visibleCandleCount = _visibleCandleCount.clamp(10, 150);
         final maxScroll = (totalCandles - _visibleCandleCount).toDouble();
         _scrollOffset = _scrollOffset.clamp(0.0, maxScroll >= 0 ? maxScroll : 0.0);
         
         // 2. Viewport Calculation (Indices)
         final double endX = totalCandles - _scrollOffset;
         final double startX = endX - _visibleCandleCount;
         
         // 3. Visible Data for Min/Max Calculation (still need subset for range)
         final int startIndex = math.max(0, startX.floor());
         final int endIndex = math.min(totalCandles, endX.ceil());
         final visibleData = _candles.sublist(startIndex, endIndex);
         
         if (visibleData.isEmpty) return const SizedBox();

         // 4. Price Window Calculation
         double minPrice = visibleData.map((c) => c.low).reduce(math.min);
         double maxPrice = visibleData.map((c) => c.high).reduce(math.max);
         final double range = maxPrice - minPrice;
         
         minPrice -= range * 0.1; 
         maxPrice += range * 0.1;
         
         // Ensure Trade Lines are visible
         if (_entryPrice != null) {
            minPrice = math.min(minPrice, _entryPrice! - range * 0.05);
            maxPrice = math.max(maxPrice, _entryPrice! + range * 0.05);
            if (_slPrice != null) minPrice = math.min(minPrice, _slPrice! - range * 0.05);
            if (_slPrice != null) maxPrice = math.max(maxPrice, _slPrice! + range * 0.05);
            if (_tpPrice != null) minPrice = math.min(minPrice, _tpPrice! - range * 0.05);
            if (_tpPrice != null) maxPrice = math.max(maxPrice, _tpPrice! + range * 0.05);
         }

         // 5. Layout Constants & Coordinate Mapping
         const double bottomTitleHeight = 30.0; 
         final double chartPlotHeight = constraints.maxHeight - bottomTitleHeight;
         final double priceRange = maxPrice - minPrice;
         final double pixelsPerPrice = chartPlotHeight / (priceRange == 0 ? 1 : priceRange);

         // Helper for Y position (from top)
         double getPriceY(double price) => (maxPrice - price) * pixelsPerPrice;

         return Stack(
           children: [
             Column(
               children: [
                 _buildChartHeader(),
                 Expanded(
                   child: MouseRegion(
                     onHover: (event) => setState(() => _cursorPos = event.localPosition),
                     onExit: (_) => setState(() => _cursorPos = null),
                     child: GestureDetector(
                       behavior: HitTestBehavior.translucent, 
                       onHorizontalDragUpdate: (details) {
                          setState(() {
                             _scrollOffset -= details.primaryDelta! * 0.2; 
                          });
                       },
                       onScaleUpdate: (details) {
                          setState(() {
                            // Zoom
                            if (details.scale != 1.0) {
                               _visibleCandleCount = (30 / details.scale).round().clamp(10, 150);
                            }
                          });
                       },
                       child: Stack(
                         clipBehavior: Clip.none,
                         children: [
                           // LAYER 1: Custom Wick Painter (Behind Body)
                           CustomPaint(
                             size: Size(constraints.maxWidth, chartPlotHeight),
                             painter: WickPainter(
                               candles: _candles,
                               startIndex: startIndex,
                               endIndex: endIndex,
                               minPrice: minPrice,
                               maxPrice: maxPrice,
                               visibleCount: _visibleCandleCount.toDouble(),
                               offset: _scrollOffset
                             ),
                           ),

                           // LAYER 2: BarChart (Candle Bodies)
                           Padding(
                             padding: const EdgeInsets.only(bottom: bottomTitleHeight), 
                             child: BarChart(
                               BarChartData(
                                 minY: minPrice,
                                 maxY: maxPrice,
                                 gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    checkToShowVerticalLine: (value) => value % math.max(1, (_visibleCandleCount / 5).floor()) == 0,
                                    getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10, strokeWidth: 1),
                                    getDrawingVerticalLine: (_) => FlLine(color: Colors.white10, strokeWidth: 1),
                                 ),
                                 titlesData: FlTitlesData(
                                   show: true,
                                   leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                   topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                   rightTitles: AxisTitles(
                                     sideTitles: SideTitles(
                                       showTitles: true,
                                       reservedSize: 50,
                                       getTitlesWidget: (value, meta) {
                                         if (value == minPrice || value == maxPrice) return const SizedBox();
                                         return Text(value.toStringAsFixed(2), style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 10));
                                       }
                                     )
                                   ),
                                   bottomTitles: AxisTitles(
                                     sideTitles: SideTitles(
                                       showTitles: true,
                                       reservedSize: bottomTitleHeight, 
                                       interval: math.max(1, _visibleCandleCount / 5),
                                       getTitlesWidget: (value, meta) {
                                           final int index = value.toInt();
                                           if (index < 0 || index >= totalCandles) return const SizedBox();
                                           final candle = _candles[index];
                                           final date = DateTime.fromMillisecondsSinceEpoch(candle.timestamp);
                                           String text = "${date.hour}:${date.minute.toString().padLeft(2,'0')}";
                                           return Padding(
                                             padding: const EdgeInsets.only(top: 8),
                                             child: Text(text, style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10)),
                                           );
                                       }
                                     )
                                   )
                                 ),
                                 borderData: FlBorderData(show: false),
                                 barTouchData: BarTouchData(enabled: false),
                                 
                                 // Draw Lines using ExtraLines for perfect Chart alignment
                                 extraLinesData: ExtraLinesData(
                                   horizontalLines: [
                                      if (_tradeMode != TradeMode.none && _entryPrice != null) ...[
                                         HorizontalLine(y: _entryPrice!, color: (_tradeMode == TradeMode.long ? Colors.cyan : Colors.pinkAccent).withOpacity(0.5), strokeWidth: 1, dashArray: [4, 4]),
                                         if (_slPrice != null) HorizontalLine(y: _slPrice!, color: Colors.redAccent.withOpacity(0.5), strokeWidth: 1, dashArray: [4, 4]),
                                         if (_tpPrice != null) HorizontalLine(y: _tpPrice!, color: const Color(0xFF00E676).withOpacity(0.5), strokeWidth: 1, dashArray: [4, 4]),
                                      ]
                                   ]
                                 ),

                                 barGroups: visibleData.map((candle) {
                                    final index = _candles.indexOf(candle);
                                    final isBullish = candle.close >= candle.open;
                                    final color = isBullish ? const Color(0xFF00E676) : const Color(0xFFFF5252);
                                    
                                    // Body Only - Wicks handled by Painter
                                    return BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: math.max(candle.open, candle.close),
                                          fromY: math.min(candle.open, candle.close),
                                          color: color,
                                          width: 6.0, 
                                          borderRadius: BorderRadius.circular(1),
                                        )
                                      ]
                                    );
                                 }).toList(),
                               )
                             ),
                           ), // End Bar Chart

                           // Layer 3: Crosshair
                           if (_cursorPos != null)
                             IgnorePointer(
                               child: CustomPaint(
                                 painter: _CrosshairPainter(position: _cursorPos!, lineColor: Colors.white24),
                                 size: Size.infinite,
                               ),
                             ),

                           // Layer 4: Interactive Controls
                           if (_tradeMode != TradeMode.none && _entryPrice != null) ...[
                              _buildEntryControls(_entryPrice!, _tradeMode == TradeMode.long ? Colors.cyan : Colors.pinkAccent, getPriceY(_entryPrice!), pixelsPerPrice),
                              if (_slPrice != null) _buildLineControls(_slPrice!, Colors.redAccent, "SL", getPriceY(_slPrice!), pixelsPerPrice, (v) => setState(() => _slPrice = v)),
                              if (_tpPrice != null) _buildLineControls(_tpPrice!, const Color(0xFF00E676), "TP", getPriceY(_tpPrice!), pixelsPerPrice, (v) => setState(() => _tpPrice = v)),
                           ]
                         ],
                       ),
                     ),
                   ),
                 ),
                 Padding(padding: const EdgeInsets.all(8.0), child: _buildIntervalSelector()),
               ],
             ),
             _buildTradeManagerPanel(),
           ],
         );
      }
    );
  }

  Widget _buildChartHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(_selectedAsset!.symbol, style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
               Text('\$${_selectedAsset!.currentPrice.toStringAsFixed(2)}', 
                 style: GoogleFonts.shareTechMono(color: _selectedAsset!.percentChange24h >= 0 ? Colors.tealAccent : Colors.pinkAccent, fontSize: 14, fontWeight: FontWeight.bold)
               ),
            ],
          ),
          if (_tradeMode == TradeMode.none)
             Row(children: [
               _buildTradeButton("BUY", Colors.cyan),
               const SizedBox(width: 8),
               _buildTradeButton("SELL", Colors.pinkAccent),
             ])
          else
             _buildActiveTradeHeader(),
        ],
      ),
    );
  }

  Widget _buildEntryControls(double price, Color color, double topY, double pixelsPerPrice) {
    if (topY < 0 || topY > 1000) return const SizedBox(); // Clip
    
    // PnL calc
    final isLong = _tradeMode == TradeMode.long;
    final currentPrice = _selectedAsset!.currentPrice;
    final pnl = (currentPrice - price) * (isLong ? 1 : -1) * 1000; // Simulated PnL
    final isProfitable = pnl >= 0;

    return Positioned(
       top: topY - 15, 
       right: 50, // Align with Chart Axis edge (Right 0 covers axis)
       child: Stack(
         clipBehavior: Clip.none,
         alignment: Alignment.center,
         children: [
            // Controls Cluster
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                   color: const Color(0xFF131722),
                   border: Border.all(color: color),
                   borderRadius: BorderRadius.circular(4),
                   boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)]
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     // 1. Swap
                     _buildControlItem(
                       onTap: _reversePosition, 
                       child: Icon(Icons.swap_vert, color: color, size: 16),
                       borderColor: Colors.white10
                     ),

                     // 2. TP Docked Button (Only if NOT active)
                     if (_tpPrice == null)
                       GestureDetector(
                          onVerticalDragUpdate: (d) {
                             // "Extract" TP line
                             setState(() {
                               _tpPrice = price - (d.primaryDelta! / pixelsPerPrice);
                             });
                          },
                          child: _buildControlItem(
                             child: Text("TP", style: GoogleFonts.orbitron(color: const Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 10)),
                             borderColor: Colors.white10
                          ),
                       ),
                     
                     // 3. SL Docked Button (Only if NOT active)
                     if (_slPrice == null)
                       GestureDetector(
                          onVerticalDragUpdate: (d) {
                             // "Extract" SL line
                             setState(() {
                               _slPrice = price - (d.primaryDelta! / pixelsPerPrice);
                             });
                          },
                          child: _buildControlItem(
                             child: Text("SL", style: GoogleFonts.orbitron(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                             borderColor: Colors.white10
                          ),
                       ),

                     // 4. Price
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8),
                       alignment: Alignment.center,
                       decoration: const BoxDecoration(
                          border: Border(right: BorderSide(color: Colors.white10))
                       ),
                       child: Text(price.toStringAsFixed(2), style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12)),
                     ),

                     // 5. PnL
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8),
                       alignment: Alignment.center,
                       color: isProfitable ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                       child: Text(
                         "${pnl >= 0 ? '+' : ''}${pnl.abs().toStringAsFixed(2)}", 
                         style: GoogleFonts.shareTechMono(color: isProfitable ? Colors.green : Colors.red, fontSize: 12)
                       ),
                     ),

                     // 6. Close (Entire Trade)
                     _buildControlItem(
                       onTap: _resetTrade, 
                       child: const Icon(Icons.close, color: Colors.white, size: 16),
                       borderColor: Colors.transparent
                     ),
                  ],
                ),
              ),
            )
         ],
       ),
    );
  }

  Widget _buildLineControls(double price, Color color, String label, double topY, double pixelsPerPrice, Function(double) onUpdate) {
     if (topY < 0 || topY > 1000) return const SizedBox();
     
     // Close Handler for specific line
     void closeLine() {
        setState(() {
           if (label == "SL") _slPrice = null;
           if (label == "TP") _tpPrice = null;
        });
     }

     return Positioned(
       top: topY - 15,
       right: 50, // Align with Chart Axis edge
       child: GestureDetector(
         behavior: HitTestBehavior.translucent, // Catch drags everywhere on this strip
         onVerticalDragUpdate: (d) {
            // Sensitivity Factor: 1.0 (Direct tracking)
            onUpdate(price - (d.primaryDelta! / pixelsPerPrice));
         },
         child: Container(
           height: 30,
           alignment: Alignment.centerRight,
           color: Colors.transparent, // Ensure Hit Test works on full width if needed
           // padding: const EdgeInsets.only(right: 60), // Removed double padding
           child: Container(
              height: 30,
              decoration: BoxDecoration(
                 color: const Color(0xFF131722),
                 border: Border.all(color: color),
                 borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // Label
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8),
                     decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.white10))),
                     child: Text(label, style: GoogleFonts.orbitron(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                   ),
                   // Price
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8),
                     decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.white10))),
                     child: Text(price.toStringAsFixed(2), style: GoogleFonts.shareTechMono(fontSize: 12, color: Colors.white)),
                   ),
                   // Close (Specific)
                   _buildControlItem(
                      onTap: closeLine,
                      child: const Icon(Icons.close, color: Colors.white54, size: 14),
                      borderColor: Colors.transparent
                   ),
                ],
              ),
           ),
         ),
       ),
     );
  }

  Widget _buildTradeManagerPanel() {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.1,
      minChildSize: 0.05, // Collapsed
      maxChildSize: 0.5,
      builder: (context, scrollController) {
         return Container(
            decoration: BoxDecoration(
               color: const Color(0xFF0A0A0A),
               border: const Border(top: BorderSide(color: Colors.white24)),
               borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
               boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]
            ),
            child: ListView(
               controller: scrollController,
               padding: const EdgeInsets.all(16),
               children: [
                  Center(child: Container(width: 40, height: 4, color: Colors.white24)),
                  const SizedBox(height: 8),
                  // Expand Arrow
                  Center(
                    child: GestureDetector(
                      onTap: () {
                         final needsExpand = _sheetController.size < 0.2;
                         _sheetController.animateTo(
                           needsExpand ? 0.4 : 0.05,
                           duration: const Duration(milliseconds: 300), 
                           curve: Curves.easeOut
                         );
                      },
                      child: const Icon(Icons.keyboard_arrow_up, color: Colors.white24, size: 24)
                    )
                  ),
                  const SizedBox(height: 8),
                  Text("ACTIVE POSITIONS", style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_tradeMode != TradeMode.none)
                    Container(
                       padding: const EdgeInsets.all(12),
                       color: Colors.white.withOpacity(0.05),
                       child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Row(children: [
                                Icon(_selectedAsset!.type == AssetType.warpDrive ? Icons.bolt : Icons.show_chart, color: Colors.cyan, size: 16),
                                const SizedBox(width: 8),
                                Text(_selectedAsset!.symbol, style: GoogleFonts.shareTechMono(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(_tradeMode == TradeMode.long ? "LONG" : "SHORT", style: GoogleFonts.orbitron(fontSize: 10, color: _tradeMode == TradeMode.long ? Colors.cyan : Colors.pinkAccent, fontWeight: FontWeight.bold)),
                                ),
                             ]),
                             Text("\$${((_selectedAsset!.currentPrice - _entryPrice!) * (_tradeMode == TradeMode.long ? 1 : -1) * 1000).toStringAsFixed(2)}", 
                               style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14)
                             )
                          ],
                       ),
                     ),
                ],
             ),
          );
       }
     );
  }

  Widget _buildActiveTradeHeader() {
    final pnl = (_selectedAsset!.currentPrice - _entryPrice!) * (_tradeMode == TradeMode.long ? 1 : -1) * 1000;
    final isProfitable = pnl >= 0;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("PNL", style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10)),
            Text("${isProfitable ? '+' : ''}${pnl.toStringAsFixed(2)}", style: GoogleFonts.shareTechMono(color: isProfitable ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _resetTrade,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white24)
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        )
      ],
    );
  }

  void _reversePosition() {
    if (_tradeMode == TradeMode.none || _entryPrice == null) return;
    setState(() {
      _tradeMode = _tradeMode == TradeMode.long ? TradeMode.short : TradeMode.long;
      // Mirror SL/TP distances
      if (_slPrice != null) {
        double dist = (_entryPrice! - _slPrice!).abs();
        _slPrice = _tradeMode == TradeMode.long ? _entryPrice! - dist : _entryPrice! + dist;
      }
      if (_tpPrice != null) {
        double dist = (_entryPrice! - _tpPrice!).abs();
        _tpPrice = _tradeMode == TradeMode.long ? _entryPrice! + dist : _entryPrice! - dist;
      }
    });
  }

  Widget _buildTradeButton(String label, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _tradeMode = label == "BUY" ? TradeMode.long : TradeMode.short;
          _entryPrice = _selectedAsset!.currentPrice;
          _slPrice = null; // Don't auto-set, let user drag
          _tpPrice = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: GoogleFonts.orbitron(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildIntervalSelector() {
    final intervals = ['1H', '4H', '1D', '1W'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: intervals.map((interval) {
          final isSelected = _selectedInterval == interval;
          return GestureDetector(
            onTap: () {
              if (isSelected) return;
              setState(() => _selectedInterval = interval);
              if (_selectedAsset != null) _loadHistory(_selectedAsset!);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.cyan.withOpacity(0.2) : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(interval, style: GoogleFonts.shareTechMono(color: isSelected ? Colors.cyan : Colors.white54, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildControlDock(BuildContext context, List<MarketAsset> assets) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: GoogleFonts.orbitron(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(subLabel, style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildControlItem({VoidCallback? onTap, required Widget child, Color? borderColor, bool isDashed = false}) {
     return GestureDetector(
       onTap: onTap,
       child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 8),
         decoration: BoxDecoration(
           border: Border(right: BorderSide(color: borderColor ?? Colors.transparent)),
         ),
         child: Center(child: child),
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
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: p.color, blurRadius: 4)],
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
  final double rotation;
  final double lifetime;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.rotation,
    required this.lifetime,
  });
}

class SciFiBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Basic grid
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
      
    const double gridSize = 40;
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum TradeMode { none, long, short }

class _CrosshairPainter extends CustomPainter {
  final Offset position;
  final Color lineColor;

  _CrosshairPainter({required this.position, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dashWidth = 4;
    final dashSpace = 4;

    // Vertical line
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(position.dx, startY), Offset(position.dx, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }

    // Horizontal line
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, position.dy), Offset(startX + dashWidth, position.dy), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter oldDelegate) => oldDelegate.position != position;
}

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
    required this.onAssetSelected,
  });

  @override
  State<_DataPadModal> createState() => _DataPadModalState();
}

class _DataPadModalState extends State<_DataPadModal> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredAssets = widget.assets.where((a) => a.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) || a.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            border: Border(top: BorderSide(color: widget.sectorColor, width: 2)),
          ),
          child: Column(
            children: [
               Padding(
                 padding: const EdgeInsets.all(16),
                 child: Row(
                   children: [
                      Icon(Icons.hub, color: widget.sectorColor),
                      const SizedBox(width: 8),
                      Text(widget.sectorName, style: GoogleFonts.orbitron(color: widget.sectorColor, fontSize: 18, fontWeight: FontWeight.bold)),
                   ],
                 ),
               ),
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                 child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.shareTechMono(color: Colors.white),
                    decoration: InputDecoration(
                       hintText: "SEARCH DATABASE...",
                       hintStyle: GoogleFonts.shareTechMono(color: Colors.white24),
                       filled: true,
                       fillColor: Colors.white.withOpacity(0.05),
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                       prefixIcon: const Icon(Icons.search, color: Colors.white24),
                    ),
                 ),
               ),
               Expanded(
                 child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredAssets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                       final asset = filteredAssets[index];
                       return ListTile(
                          onTap: () => widget.onAssetSelected(asset),
                          tileColor: Colors.white.withOpacity(0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          leading: CircleAvatar(
                             backgroundColor: widget.sectorColor.withOpacity(0.2),
                             child: Icon(Icons.token, color: widget.sectorColor, size: 16),
                          ),
                          title: Text(asset.symbol, style: GoogleFonts.orbitron(color: Colors.white)),
                          subtitle: Text(asset.name, style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10)),
                          trailing: Text("\$${asset.currentPrice.toStringAsFixed(2)}", style: GoogleFonts.shareTechMono(color: Colors.white)),
                       );
                    },
                 ),
               ),
            ],
          ),
        );
      },
    );
  }
}

