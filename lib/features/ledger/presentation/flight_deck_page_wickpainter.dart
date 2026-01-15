import 'package:flutter/material.dart';
import '../../trading/data/market_service.dart';

class CandleStickPainter extends CustomPainter {
  final List<MockCandle> candles;
  final double startX;
  final double endX;
  final double minPrice;
  final double maxPrice;

  CandleStickPainter({
    required this.candles,
    required this.startX,
    required this.endX,
    required this.minPrice,
    required this.maxPrice,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final double priceRange = maxPrice - minPrice;
    if (priceRange <= 0) return;
    final double pixelsPerPrice = size.height / priceRange;

    // Viewport width in data units
    final double visibleRange = endX - startX;
    if (visibleRange <= 0) return;

    // Width of one "slot" in pixels
    final double slotWidth = size.width / visibleRange;
    final double candleWidth = slotWidth * 0.7; // 70% of slot width

    final paint = Paint()..strokeWidth = 1.0;

    // Determine loop bounds
    final int loopStart = (startX - 1).floor(); // Draw 1 extra on edges to be safe
    final int loopEnd = (endX + 1).ceil();

    for (int i = loopStart; i < loopEnd; i++) {
        if (i < 0 || i >= candles.length) continue;
        
        final candle = candles[i];
        final isBullish = candle.close >= candle.open;
        paint.color = isBullish ? const Color(0xFF00E676) : const Color(0xFFFF5252);
        
        // Center X of the slot
        final double centerX = (i - startX) * slotWidth + (slotWidth / 2);

        // Y coordinates (0 is top)
        final double highY = (maxPrice - candle.high) * pixelsPerPrice;
        final double lowY = (maxPrice - candle.low) * pixelsPerPrice;
        final double openY = (maxPrice - candle.open) * pixelsPerPrice;
        final double closeY = (maxPrice - candle.close) * pixelsPerPrice;

        // Draw Wick
        canvas.drawLine(Offset(centerX, highY), Offset(centerX, lowY), paint);

        // Draw Body
        // Body Height must be at least 1 pixel
        double bodyTop = isBullish ? closeY : openY;
        double bodyBottom = isBullish ? openY : closeY;
        if ((bodyBottom - bodyTop).abs() < 1) {
           bodyBottom = bodyTop + 1;
        }

        final Rect bodyRect = Rect.fromCenter(
           center: Offset(centerX, (bodyTop + bodyBottom) / 2),
           width: candleWidth,
           height: bodyBottom - bodyTop
        );
        
        // Fill Body
        paint.style = PaintingStyle.fill;
        canvas.drawRect(bodyRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CandleStickPainter old) {
    return old.startX != startX || 
           old.endX != endX ||
           old.minPrice != minPrice ||
           old.maxPrice != maxPrice;
  }
}
