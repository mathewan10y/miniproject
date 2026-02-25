import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:interactive_chart/interactive_chart.dart';
import '../../trading/data/market_service.dart';
import '../../trading/data/portfolio_provider.dart';
import '../../trading/domain/models/market_asset.dart';
import '../../trading/domain/models/open_position.dart';
import '../../trading/domain/models/trade_history_item.dart';
import '../../gamification/user_stats_provider.dart';

class TradingPage extends ConsumerStatefulWidget {
  final MarketAsset asset;

  const TradingPage({super.key, required this.asset});

  @override
  ConsumerState<TradingPage> createState() => _TradingPageState();
}

class _TradingPageState extends ConsumerState<TradingPage>
    with SingleTickerProviderStateMixin {
  String _selectedInterval = '1H';
  List<CandleData> _candles = [];
  bool _isLoading = true;

  final _quantityController = TextEditingController(text: '1');
  double _quantity = 1.0;

  late final TabController _tabController;
  final _journalController = TextEditingController();

  static const _panelBg = Color(0xFF131722);
  static const _panelBorder = Color(0xFF1E222D);
  static const _darkBg = Color(0xFF0B0E14);
  static const _cyan = Color(0xFF2962FF);
  static const _green = Color(0xFF26A69A);
  static const _red = Color(0xFFEF5350);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _tabController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(marketServiceProvider);
      final history =
          await service.getAssetHistory(widget.asset.id, _selectedInterval);
      setState(() {
        _candles = history
            .map((h) => CandleData(
                  timestamp: h.timestamp,
                  open: h.open,
                  close: h.close,
                  high: h.high,
                  low: h.low,
                  volume: h.volume,
                ))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ─── Order Execution ──────────────────────────────────────────────────────

  void _onBuy() {
    final qty = double.tryParse(_quantityController.text.trim()) ?? 0;
    if (qty <= 0) {
      _showSnack('Enter a valid quantity', Colors.orange);
      return;
    }
    final price = widget.asset.currentPrice;
    final cost = price * qty;

    final statsNotifier = ref.read(userStatsProvider.notifier);
    final success = statsNotifier.deductFuel(cost);

    if (!success) {
      final balance = ref.read(userStatsProvider).tradingCredits;
      _showSnack(
        'Insufficient FUEL — need ₹${cost.toStringAsFixed(2)}, have ₹${balance.toStringAsFixed(2)}',
        _red,
      );
      return;
    }

    final balanceAfter = ref.read(userStatsProvider).tradingCredits;
    ref.read(portfolioProvider.notifier).openPosition(
          OpenPosition(
            assetId: widget.asset.id,
            assetSymbol: widget.asset.symbol,
            assetName: widget.asset.name,
            entryPrice: price,
            quantity: qty,
            isLong: true,
            openedAt: DateTime.now(),
          ),
          balanceAfter: balanceAfter,
        );

    _showSnack(
      'LONG ${qty.toStringAsFixed(2)} ${widget.asset.symbol} @ ₹${price.toStringAsFixed(2)}',
      _green,
    );
  }

  void _onSell() {
    final qty = double.tryParse(_quantityController.text.trim()) ?? 0;
    if (qty <= 0) {
      _showSnack('Enter a valid quantity', Colors.orange);
      return;
    }
    final price = widget.asset.currentPrice;
    final cost = price * qty;

    final statsNotifier = ref.read(userStatsProvider.notifier);
    final success = statsNotifier.deductFuel(cost);

    if (!success) {
      final balance = ref.read(userStatsProvider).tradingCredits;
      _showSnack(
        'Insufficient FUEL — need ₹${cost.toStringAsFixed(2)}, have ₹${balance.toStringAsFixed(2)}',
        _red,
      );
      return;
    }

    final balanceAfter = ref.read(userStatsProvider).tradingCredits;
    ref.read(portfolioProvider.notifier).openPosition(
          OpenPosition(
            assetId: widget.asset.id,
            assetSymbol: widget.asset.symbol,
            assetName: widget.asset.name,
            entryPrice: price,
            quantity: qty,
            isLong: false,
            openedAt: DateTime.now(),
          ),
          balanceAfter: balanceAfter,
        );

    _showSnack(
      'SHORT ${qty.toStringAsFixed(2)} ${widget.asset.symbol} @ ₹${price.toStringAsFixed(2)}',
      _red,
    );
  }

  /// Close a specific position by its unique ID.
  void _closePositionById(String positionId) {
    final portfolio = ref.read(portfolioProvider.notifier);
    final existing = portfolio.getPositionById(positionId);
    if (existing == null) return;

    final currentPrice = widget.asset.currentPrice;
    // Return capital + P&L first
    final pnl = existing.realizedPnl(currentPrice);
    ref.read(userStatsProvider.notifier).addFuel(existing.totalCost + pnl);

    final balanceAfter = ref.read(userStatsProvider).tradingCredits;
    portfolio.closePosition(positionId, currentPrice,
        balanceAfter: balanceAfter);

    final pnlSign = pnl >= 0 ? '+' : '';
    final pnlColor = pnl >= 0 ? _green : _red;
    _showSnack(
      'Closed ${existing.assetSymbol} — P&L: $pnlSign₹${pnl.toStringAsFixed(2)}',
      pnlColor,
    );
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style:
                GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13)),
        backgroundColor: color.withAlpha(220),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(userStatsProvider);
    final portfolioState = ref.watch(portfolioProvider);

    // Compute account stats
    final balance = stats.tradingCredits;
    final unrealizedPnl = portfolioState.positions.fold(0.0,
        (sum, p) => sum + p.unrealizedPnl(widget.asset.currentPrice));
    final realizedPnl = portfolioState.totalRealizedPnl;
    final equity = balance + unrealizedPnl;

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _panelBg,
        elevation: 0,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.asset.symbol,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                Text(
                  '₹${widget.asset.currentPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    color: widget.asset.percentChange24h >= 0 ? _green : _red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (widget.asset.percentChange24h >= 0 ? _green : _red)
                    .withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${widget.asset.percentChange24h >= 0 ? "+" : ""}${widget.asset.percentChange24h.toStringAsFixed(2)}%',
                style: GoogleFonts.inter(
                  color:
                      widget.asset.percentChange24h >= 0 ? _green : _red,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [_buildIntervalSelector()],
      ),
      body: Stack(
        children: [
          // ── Chart fills background ──
          Positioned.fill(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _cyan, strokeWidth: 2))
                : _candles.isEmpty
                    ? Center(
                        child: Text('No chart data available',
                            style: GoogleFonts.inter(
                                color: Colors.white38, fontSize: 14)))
                    : InteractiveChart(
                        candles: _candles,
                        style: ChartStyle(
                          priceGainColor: _green,
                          priceLossColor: _red,
                          volumeColor: Colors.white.withAlpha(25),
                          priceGridLineColor: Colors.white.withAlpha(8),
                          timeLabelStyle:
                              GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                          priceLabelStyle:
                              GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                          overlayBackgroundColor: Colors.black.withAlpha(200),
                        ),
                      ),
          ),

          // ── Trading Terminal (DraggableScrollableSheet) ──
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.08,
            maxChildSize: 0.80,
            snap: true,
            snapSizes: const [0.08, 0.38, 0.80],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: _panelBg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(
                      top: BorderSide(color: _panelBorder, width: 1)),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black54,
                        blurRadius: 20,
                        offset: Offset(0, -4)),
                  ],
                ),
                child: Column(
                  children: [
                    // ── Drag handle ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    // ── Order entry + Account summary ──
                    _buildOrderAndAccountRow(
                        balance, equity, realizedPnl, unrealizedPnl),

                    Container(height: 1, color: _panelBorder),

                    // ── TabBar ──
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: _cyan,
                      indicatorWeight: 2,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      labelStyle: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w500),
                      unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Positions'),
                        Tab(text: 'Orders'),
                        Tab(text: 'Order History'),
                        Tab(text: 'Balance History'),
                        Tab(text: 'Trading Journal'),
                      ],
                    ),

                    Container(height: 1, color: _panelBorder),

                    // ── TabBarView ──
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPositionsTab(
                              portfolioState.positions, scrollController),
                          _buildOrdersTab(scrollController),
                          _buildOrderHistoryTab(
                              portfolioState.history, scrollController),
                          _buildBalanceHistoryTab(
                              portfolioState.balanceHistory, scrollController),
                          _buildJournalTab(scrollController),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Order Entry + Account Summary ─────────────────────────────────────────

  Widget _buildOrderAndAccountRow(
      double balance, double equity, double realizedPnl, double unrealizedPnl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          // Account summary bar
          Row(
            children: [
              _accountStat('Account Balance', '₹${balance.toStringAsFixed(2)}'),
              _accountStat('Equity', '₹${equity.toStringAsFixed(2)}'),
              _accountStat(
                  'Realized P&L',
                  '${realizedPnl >= 0 ? "+" : ""}₹${realizedPnl.toStringAsFixed(2)}',
                  realizedPnl >= 0 ? _green : _red),
              _accountStat(
                  'Unrealized P&L',
                  '${unrealizedPnl >= 0 ? "+" : ""}₹${unrealizedPnl.toStringAsFixed(2)}',
                  unrealizedPnl >= 0 ? _green : _red),
            ],
          ),
          const SizedBox(height: 6),
          // Order entry row
          Row(
            children: [
              Text('QTY',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
              const SizedBox(width: 6),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                  ],
                  style:
                      GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    filled: true,
                    fillColor: const Color(0xFF1E222D),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: _panelBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: _panelBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: _cyan),
                    ),
                    hintText: '0.00',
                    hintStyle:
                        GoogleFonts.inter(color: Colors.white24, fontSize: 12),
                  ),
                  onChanged: (v) =>
                      setState(() => _quantity = double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '≈₹${(widget.asset.currentPrice * _quantity).toStringAsFixed(0)}',
                style: GoogleFonts.inter(color: Colors.white30, fontSize: 10),
              ),
              const Spacer(),
              _orderButton('BUY / LONG', _green, _onBuy),
              const SizedBox(width: 6),
              _orderButton('SELL / SHORT', _red, _onSell),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accountStat(String label, String value, [Color? valueColor]) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 9)),
          Text(value,
              style: GoogleFonts.inter(
                  color: valueColor ?? Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _orderButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          elevation: 0,
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, fontSize: 11)),
      ),
    );
  }

  // ─── 1. Positions Tab ─────────────────────────────────────────────────────

  Widget _buildPositionsTab(
      List<OpenPosition> positions, ScrollController scrollController) {
    if (positions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, color: Colors.white12, size: 40),
            const SizedBox(height: 8),
            Text('No open positions',
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.zero,
      itemCount: positions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _positionsHeader();
        final pos = positions[index - 1];
        final pnl = pos.unrealizedPnl(widget.asset.currentPrice);
        final pnlPct = pos.entryPrice > 0
            ? (pnl / (pos.entryPrice * pos.quantity)) * 100
            : 0.0;
        final pnlColor = pnl >= 0 ? _green : _red;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _panelBorder)),
          ),
          child: Row(
            children: [
              // Symbol
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: (pos.isLong ? _green : _red).withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        pos.isLong ? Icons.trending_up : Icons.trending_down,
                        color: pos.isLong ? _green : _red,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pos.assetSymbol,
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        Text(pos.assetName,
                            style: GoogleFonts.inter(
                                color: Colors.white30, fontSize: 9),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ],
                ),
              ),
              // Side
              Expanded(
                flex: 1,
                child: Text(
                  pos.isLong ? 'Buy' : 'Sell',
                  style: GoogleFonts.inter(
                    color: pos.isLong ? _green : _red,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Qty
              Expanded(
                flex: 1,
                child: Text(pos.quantity.toStringAsFixed(2),
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 11)),
              ),
              // Avg Fill
              Expanded(
                flex: 2,
                child: Text(
                  '₹${pos.entryPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                      color: Colors.white70, fontSize: 11),
                ),
              ),
              // Unrealized P&L
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pnl >= 0 ? "+" : ""}₹${pnl.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                          color: pnlColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${pnlPct >= 0 ? "+" : ""}${pnlPct.toStringAsFixed(2)}%',
                      style: GoogleFonts.inter(
                          color: pnlColor, fontSize: 9),
                    ),
                  ],
                ),
              ),
              // Close button
              SizedBox(
                height: 26,
                child: TextButton(
                  onPressed: () => _closePositionById(pos.id),
                  style: TextButton.styleFrom(
                    backgroundColor: _red.withAlpha(20),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: _red.withAlpha(80)),
                    ),
                  ),
                  child: Text('Close',
                      style: GoogleFonts.inter(
                          color: _red,
                          fontSize: 10,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _positionsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      color: const Color(0xFF1E222D),
      child: Row(
        children: [
          _headerCell('Symbol', 3),
          _headerCell('Side', 1),
          _headerCell('Qty', 1),
          _headerCell('Avg Fill Price', 2),
          _headerCell('Unrealized P&L', 2),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  // ─── 2. Orders Tab (placeholder) ──────────────────────────────────────────

  Widget _buildOrdersTab(ScrollController scrollController) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, color: Colors.white12, size: 40),
          const SizedBox(height: 8),
          Text('No pending orders',
              style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
          const SizedBox(height: 4),
          Text('All orders are filled instantly (market orders)',
              style: GoogleFonts.inter(color: Colors.white12, fontSize: 11)),
        ],
      ),
    );
  }

  // ─── 3. Order History Tab ─────────────────────────────────────────────────

  Widget _buildOrderHistoryTab(
      List<TradeHistoryItem> historyItems, ScrollController scrollController) {
    if (historyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_outlined, color: Colors.white12, size: 40),
            const SizedBox(height: 8),
            Text('No closed trades yet',
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.zero,
      itemCount: historyItems.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _orderHistoryHeader();
        final item = historyItems[historyItems.length - index]; // newest first
        final pnlColor = item.realizedPnl >= 0 ? _green : _red;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _panelBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(item.assetSymbol,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  item.isLong ? 'Buy' : 'Sell',
                  style: GoogleFonts.inter(
                      color: item.isLong ? _green : _red, fontSize: 11),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(item.quantity.toStringAsFixed(2),
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 11)),
              ),
              Expanded(
                flex: 2,
                child: Text('₹${item.entryPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 11)),
              ),
              Expanded(
                flex: 2,
                child: Text('₹${item.exitPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 11)),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${item.realizedPnl >= 0 ? "+" : ""}₹${item.realizedPnl.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                      color: pnlColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _orderHistoryHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      color: const Color(0xFF1E222D),
      child: Row(
        children: [
          _headerCell('Symbol', 2),
          _headerCell('Side', 1),
          _headerCell('Qty', 1),
          _headerCell('Entry Price', 2),
          _headerCell('Exit Price', 2),
          _headerCell('Realized P&L', 2),
        ],
      ),
    );
  }

  // ─── 4. Balance History Tab ───────────────────────────────────────────────

  Widget _buildBalanceHistoryTab(
      List<BalanceEvent> events, ScrollController scrollController) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                color: Colors.white12, size: 40),
            const SizedBox(height: 8),
            Text('No balance changes yet',
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.zero,
      itemCount: events.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _balanceHistoryHeader();
        final event = events[events.length - index]; // newest first
        final isPositive = event.delta >= 0;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _panelBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  _formatTime(event.timestamp),
                  style: GoogleFonts.inter(
                      color: Colors.white54, fontSize: 11),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(event.description,
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${isPositive ? "+" : ""}₹${event.delta.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    color: isPositive ? _green : _red,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '₹${event.balanceAfter.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _balanceHistoryHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      color: const Color(0xFF1E222D),
      child: Row(
        children: [
          _headerCell('Time', 2),
          _headerCell('Description', 3),
          _headerCell('Change', 2),
          _headerCell('Balance', 2),
        ],
      ),
    );
  }

  // ─── 5. Trading Journal Tab ───────────────────────────────────────────────

  Widget _buildJournalTab(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: Colors.white38, size: 18),
              const SizedBox(width: 6),
              Text(
                'Trade Notes — ${widget.asset.symbol}',
                style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _journalController,
            maxLines: 12,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            decoration: InputDecoration(
              hintText:
                  'Why did I enter this trade? What was the thesis?\nRisk:Reward ratio, setup quality, lessons learned...',
              hintStyle: GoogleFonts.inter(
                  color: Colors.white12, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF1E222D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _panelBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _panelBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _cyan),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared Helpers ───────────────────────────────────────────────────────

  Widget _headerCell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w500)),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$d/$mo $h:$m';
  }

  Widget _buildIntervalSelector() {
    final intervals = ['1H', '4H', '1D', '1W'];
    return Row(
      children: intervals.map((interval) {
        final isSelected = _selectedInterval == interval;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedInterval = interval);
            _loadHistory();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? _cyan.withAlpha(30)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? _cyan : Colors.transparent,
              ),
            ),
            child: Text(
              interval,
              style: GoogleFonts.inter(
                color: isSelected ? _cyan : Colors.white54,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
