import 'package:flutter/material.dart';

class ReactorGauge extends StatelessWidget {
  final double fillPercent; // Value between 0.0 and 1.0

  const ReactorGauge({
    Key? key,
    required this.fillPercent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Layer 1: Empty Background
          Image.asset('lib/assets/reactorempty.png', fit: BoxFit.contain),

          // Layer 2: Filling Foreground with ShaderMask
          // Masks out the caps (approx 21% each side) so they don't fill.
          ShaderMask(
            shaderCallback: (rect) {
              const double startOffset = 0.26; // Adjusted to match blue plasma start
              const double endOffset = 0.26;   // Adjusted to match blue plasma end
              
              // Calculate where the fill should stop in the 0.0-1.0 range
              // It starts at startOffset and covers the remaining space (1 - start - end)
              final double currentStop = startOffset + 
                  (fillPercent.clamp(0.0, 1.0) * (1.0 - startOffset - endOffset));

              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                // Transparent before startOffset (Left Cap hidden)
                // White from startOffset to currentStop (Tube revealed)
                // Transparent from currentStop to end (Empty space + Right Cap hidden)
                stops: [
                  0.0, 
                  startOffset, 
                  startOffset, 
                  currentStop, 
                  currentStop, 
                  1.0
                ],
                colors: const [
                  Colors.transparent, 
                  Colors.transparent, 
                  Colors.white, 
                  Colors.white, 
                  Colors.transparent, 
                  Colors.transparent
                ],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: Image.asset('lib/assets/reactor_full.png', fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}
