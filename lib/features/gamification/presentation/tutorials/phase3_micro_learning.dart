import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/tutorial_keys.dart';
import '../../services/tutorial_engine_service.dart';
import '../widgets/tutorial_overlay_widget.dart';

class Phase3MicroLearning {
  static void startFlightDeck(BuildContext context, WidgetRef ref) {
    if (!context.mounted) return;

    final t1 = TargetFocus(
      identify: "AssetList",
      keyTarget: TutorialKeys.flightDeckAssetListKey(),
      shape: ShapeLightFocus.RRect,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "ASSET MANIFEST",
                style: GoogleFonts.orbitron(
                  color: Colors.cyanAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "These are your available tradable assets.\nEach represents a different sector of the digital economy.",
                style: GoogleFonts.shareTechMono(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );

    final t2 = TargetFocus(
      identify: "TelemetryChart",
      keyTarget: TutorialKeys.stockChartKey(),
      shape: ShapeLightFocus.RRect,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "PRICE TELEMETRY",
                style: GoogleFonts.orbitron(
                  color: Colors.cyanAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Real-time price data visualization.\nMonitor market trends and patterns.",
                style: GoogleFonts.shareTechMono(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );

    final t3 = TargetFocus(
      identify: "TradeQuantity",
      keyTarget: TutorialKeys.orderQuantityInputKey(),
      shape: ShapeLightFocus.Circle,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) {
            return TutorialOverlayWidget(
              dialogs: const [
                DialogNode(CharacterSpeaker.aura, "Tap here to adjust your order quantity before executing a BUY or SELL order. Use your FUEL reserves wisely."),
                DialogNode(CharacterSpeaker.crash, "Execute max leverage long! Double or nothing!"),
              ],
              onComplete: () => controller.next(),
            );
          },
        ),
      ],
    );

    final allTargets = [t1, t2, t3];
    final validTargets = allTargets.where((t) {
      if (t.keyTarget != null) {
        return t.keyTarget!.currentContext != null;
      }
      return true;
    }).toList();

    if (validTargets.isEmpty) return;

    TutorialCoachMark(
      targets: validTargets,
      colorShadow: const Color(0xAA0B0E14),
      textSkip: "SKIP TUTORIAL [DEV]",
      paddingFocus: 10,
      opacityShadow: 0.9,
      onFinish: () {
        ref.read(tutorialEngineProvider).markLevel1AppliedSeen();
      },
      onSkip: () {
        ref.read(tutorialEngineProvider).markLevel1AppliedSeen();
        return true;
      },
    ).show(context: context);
  }
}
