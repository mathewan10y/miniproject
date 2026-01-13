import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_chart/interactive_chart.dart';
import '../../trading/data/market_service.dart';
import '../../trading/domain/models/market_asset.dart';

class TradingPage extends ConsumerStatefulWidget {
  final MarketAsset asset;

  const TradingPage({super.key, required this.asset});

  @override
  ConsumerState<TradingPage> createState() => _TradingPageState();
}

class _TradingPageState extends ConsumerState<TradingPage> {
  String _selectedInterval = '1H';
  List<CandleData> _candles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(marketServiceProvider);
      final history = await service.getAssetHistory(widget.asset.id, _selectedInterval);
      
      setState(() {
        _candles = history.map((h) => CandleData(
          timestamp: h.timestamp,
          open: h.open,
          close: h.close,
          high: h.high,
          low: h.low,
          volume: h.volume,
        )).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14), // Deep trading background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E14),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.asset.symbol,
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 16
              ),
            ),
            Text(
              '\$${widget.asset.currentPrice.toStringAsFixed(2)}',
              style: TextStyle(
                color: widget.asset.percentChange24h >= 0 ? Colors.greenAccent : Colors.redAccent,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          _buildIntervalSelector(),
        ],
      ),
      body: Column(
        children: [
          // Main Chart Area
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D9FF)))
                : InteractiveChart(
                    candles: _candles,
                    style: ChartStyle(
                      priceGainColor: Colors.greenAccent,
                      priceLossColor: Colors.redAccent,
                      volumeColor: Colors.white.withOpacity(0.2),
                      priceGridLineColor: Colors.white10,
                      timeLabelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
                      priceLabelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
                      overlayBackgroundColor: Colors.black.withOpacity(0.8),
                    ),
                  ),
          ),
          
          // Trading Controls
          _buildTradePanel(),
        ],
      ),
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
            _loadHistory();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00D9FF).withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? const Color(0xFF00D9FF) : Colors.transparent
              ),
            ),
            child: Text(
              interval,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00D9FF) : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTradePanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF151A21),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'BUY',
                  color: Colors.green,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  label: 'SELL',
                  color: Colors.red,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Available Balance: 1,500.00 FUEL',
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
