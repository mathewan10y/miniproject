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
          // This ensures the image is exactly the same size/position as the background
          // but revealed from left to right based on fillPercent.
          ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [fillPercent.clamp(0.0, 1.0), fillPercent.clamp(0.0, 1.0)],
                colors: const [Colors.white, Colors.transparent],
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
