import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/tutorial_keys.dart';
import '../../services/tutorial_engine_service.dart';
import '../widgets/tutorial_overlay_widget.dart';

class Phase1Onboarding {
  static void start(BuildContext context, WidgetRef ref) {
    // Start step 1: The Awakening
    // Highlight the center of the reactor core
    
    final t1 = TargetFocus(
      identify: "Awakening",
      keyTarget: TutorialKeys.reactorCenterKey,
      shape: ShapeLightFocus.Circle,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) {
            return TutorialOverlayWidget(
              dialogs: const [
                DialogNode(CharacterSpeaker.aura, "Commander, awaken. I am Aura, your tactical financial officer. We are adrift. Your Life Support reactor has 0 FUEL."),
                DialogNode(CharacterSpeaker.crash, "Let's take out a million credit loan and gamble it on Doge-Asteroids! We're going to the moon!"),
                DialogNode(CharacterSpeaker.aura, "Mute him. He is a corrupted algorithm. To survive, you must first generate power."),
              ],
              onComplete: () {
                controller.next();
              },
            );
          },
        ),
      ],
    );

    final t2 = TargetFocus(
      identify: "PowerGeneration",
      keyTarget: TutorialKeys.addIncomeBtnKey,
      shape: ShapeLightFocus.RRect,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) {
            return TutorialOverlayWidget(
              dialogs: const [
                DialogNode(CharacterSpeaker.aura, "Tap the 'Add Income' button below to log your monthly salary. This is your active thruster."),
              ],
              onComplete: () {}, // Let the user actually tap the highlighted area to proceed.
            );
          },
        ),
      ],
    );

    final t3 = TargetFocus(
      identify: "HullLeaks",
      keyTarget: TutorialKeys.addExpenseBtnKey,
      shape: ShapeLightFocus.RRect,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) {
            return TutorialOverlayWidget(
              dialogs: const [
                DialogNode(CharacterSpeaker.aura, "Power restored. However, the ship is leaking. Every time you spend money, you must log it."),
                DialogNode(CharacterSpeaker.crash, "Yeah! Spend it all! Buy a solid gold spacesuit! YOLO!"),
                DialogNode(CharacterSpeaker.aura, "Tap the 'Add Expense' button. Notice that you must categorize every expense as a 'Need' (Life Support) or a 'Want' (Luxury)."),
              ],
              onComplete: () {},
            );
          },
        ),
      ],
    );

    final t4 = TargetFocus(
      identify: "CoreMechanic",
      keyTarget: TutorialKeys.reactorGaugeKey,
      shape: ShapeLightFocus.Circle,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) {
            return TutorialOverlayWidget(
              dialogs: const [
                DialogNode(CharacterSpeaker.aura, "This is your Reactor Core. It tracks the 50/30/20 rule. If your 'Needs' cross 50% of your power, or your 'Wants' cross 30%, the ship will stall."),
                DialogNode(CharacterSpeaker.crash, "Boring! When do we get to the Flight Deck to trade options?!"),
              ],
              onComplete: () {
                controller.next();
              },
            );
          },
        ),
      ],
    );

    final t5 = TargetFocus(
      identify: "TheGoal",
      keyTarget: TutorialKeys.reactorCenterKey,
      shape: ShapeLightFocus.Circle,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) {
            return TutorialOverlayWidget(
              dialogs: const [
                DialogNode(CharacterSpeaker.aura, "The Logistics panel is to your left (SWIPE RIGHT). The Flight Deck is to your right (SWIPE LEFT)."),
                DialogNode(CharacterSpeaker.aura, "However, the Flight Deck is currently locked. You cannot trade until you learn how to survive."),
              ],
              onComplete: () { controller.next(); }, 
            );
          },
        ),
      ],
    );

    final t6 = TargetFocus(
      identify: "TheAcademy",
      keyTarget: TutorialKeys.codexBtnKey,
      shape: ShapeLightFocus.RRect,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) {
            return TutorialOverlayWidget(
              dialogs: const [
                DialogNode(CharacterSpeaker.aura, "To unlock the Flight Deck, you must study the Stardust Codex and pass the Boss Fight."),
                DialogNode(CharacterSpeaker.crash, "Reading is for nerds! Just press buttons until we get rich!"),
                DialogNode(CharacterSpeaker.aura, "Tap the Codex icon to read the Level 0 survival manual. Your training begins now, Commander."),
              ],
              onComplete: () {},
            );
          },
        ),
      ],
    );

    TutorialCoachMark(
      targets: [t1, t2, t3, t4, t5, t6],
      colorShadow: const Color(0xAA0B0E14),
      textSkip: "SKIP TUTORIAL [DEV]",
      paddingFocus: 10,
      opacityShadow: 0.9,
      onFinish: () {
        ref.read(tutorialEngineProvider).markPhase1Seen();
      },
      onClickTarget: (target) {
        // We let them through.
        // Wait, for step 2 & 3 & 6, the user tapping the button triggers the bottom sheet / dialog.
        // The TutorialCoachMark will automatically proceed to the next step, which might immediately overshadow the bottom sheet!
        // We need custom logic to PAUSE the tutorial and wait for them to close it, OR we just let the tutorial end or proceed differently?
        // Actually, if they tap the target, CoachMark moves to the next target instantly.
        // To prevent this clashing, we can just let coach mark run through, OR we make the tutorial just text-based.
        // Let's rely on standard tutorial_coach_mark behavior for now.
      },
      onSkip: () {
        ref.read(tutorialEngineProvider).markPhase1Seen();
        return true;
      },
    ).show(context: context);
  }
}
