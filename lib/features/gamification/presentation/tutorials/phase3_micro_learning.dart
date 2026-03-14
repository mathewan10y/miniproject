import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/tutorial_keys.dart';
import '../../services/tutorial_engine_service.dart';
import '../widgets/tutorial_overlay_widget.dart';

class Phase3MicroLearning {
  static void startFlightDeck(BuildContext context, WidgetRef ref) {
    if (!context.mounted) return;

    final t1 = TargetFocus(
      identify: "AssetList",
      keyTarget: TutorialKeys.flightDeckAssetListKey,
      shape: ShapeLightFocus.RRect,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) {
            return TutorialOverlayWidget(
              dialogs: const [
                DialogNode(CharacterSpeaker.aura, "Welcome to the Flight Deck, Commander. This is the live market terminal."),
                DialogNode(CharacterSpeaker.aura, "Select an asset sector below to initialize telemetry."),
              ],
              onComplete: () => controller.next(),
            );
          },
        ),
      ],
    );

    final t2 = TargetFocus(
      identify: "TelemetryChart",
      keyTarget: TutorialKeys.stockChartKey,
      shape: ShapeLightFocus.RRect,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) {
            return TutorialOverlayWidget(
              dialogs: const [
                DialogNode(CharacterSpeaker.aura, "This panel displays the candlestick chart for the selected asset. Use it to identify macroscopic trends."),
              ],
              onComplete: () => controller.next(),
            );
          },
        ),
      ],
    );

    final t3 = TargetFocus(
      identify: "TradeQuantity",
      keyTarget: TutorialKeys.orderQuantityInputKey,
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
