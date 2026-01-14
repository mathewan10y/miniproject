import 'package:flutter/material.dart';
import '../../trading/data/market_service.dart';

class WickPainter extends CustomPainter {
  final List<MockCandle> candles;
  final int startIndex;
  final int endIndex;
  final double minPrice;
  final double maxPrice;
  final double visibleCount;
  final double offset;

  WickPainter({
    required this.candles,
    required this.startIndex,
    required this.endIndex,
    required this.minPrice,
    required this.maxPrice,
    required this.visibleCount,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final double priceRange = maxPrice - minPrice;
    if (priceRange <= 0) return;
    final double pixelsPerPrice = size.height / priceRange;

    // We can assume BarChart groups are evenly spaced 0, 1, 2...
    // The chart view displays indices [total - offset - visible, total - offset]
    // Width of one "slot" in pixels
    final double candleWidth = size.width / visibleCount;

    // Logic: Iterate visible candles and draw wick lines
    // X Coordinate:
    // BarChart uses x-indices from startX to endX.
    final total = candles.length;
    final double endX = total - offset;
    final double startX = endX - visibleCount;

    final paint = Paint()..strokeWidth = 1.0;

    for (int i = startIndex; i < endIndex; i++) {
        final candle = candles[i];
        final isBullish = candle.close >= candle.open;
        paint.color = isBullish ? const Color(0xFF00E676) : const Color(0xFFFF5252);
        
        // Map abstract index `i` to pixel X
        // X = (i - startX) * candleWidth + (candleWidth / 2)
        // Center of the slot
        final double x = (i - startX) * candleWidth + (candleWidth / 2);

        final double highY = (maxPrice - candle.high) * pixelsPerPrice;
        final double lowY = (maxPrice - candle.low) * pixelsPerPrice;
        
        canvas.drawLine(Offset(x, highY), Offset(x, lowY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WickPainter old) {
    return old.startIndex != startIndex || 
           old.endIndex != endIndex ||
           old.offset != offset ||
           old.visibleCount != visibleCount;
  }
}
