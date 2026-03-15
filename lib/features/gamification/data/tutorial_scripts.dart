import '../presentation/widgets/tutorial_overlay_widget.dart';

class TutorialScripts {
  static List<DialogNode> getCodexScript(int level) {
    switch (level) {
      case 0:
        return const [
          DialogNode(CharacterSpeaker.aura, "Level 0: The Academy. This manual contains the core survival protocols. Read it carefully."),
          DialogNode(CharacterSpeaker.crash, "Skip the manual! Let's just guess the answers and fight the boss!"),
          DialogNode(CharacterSpeaker.aura, "Incorrect answers will result in failure. Study the sub-levels to prepare for the anomaly."),
        ];
      case 1:
        return const [
          DialogNode(CharacterSpeaker.aura, "Level 1: Ground School. Here we discuss the difference between investing in the whole galaxy versus a single asteroid."),
          DialogNode(CharacterSpeaker.crash, "I put my entire life savings into a meme-asteroid once! I lost everything, but it was hilarious!"),
          DialogNode(CharacterSpeaker.aura, "Do not emulate him, Commander. Focus on diversification through Index Funds."),
        ];
      case 2:
        return const [
          DialogNode(CharacterSpeaker.aura, "Level 2: Navigation. You will learn to read Candlestick charts, the universal language of market movement."),
          DialogNode(CharacterSpeaker.crash, "Green means moon! Red means buy the dip! That's all you need to know!"),
          DialogNode(CharacterSpeaker.aura, "Charts reflect human psychology and institutional flow. Read the manual to understand the true mechanics."),
        ];
      case 3:
        return const [
          DialogNode(CharacterSpeaker.aura, "Level 3: Engineering. We will analyze the fundamentals of a company to see if its hull is breached or solid."),
          DialogNode(CharacterSpeaker.crash, "Who cares about debts or revenue? If the CEO tweets a rocket emoji, I'm buying!"),
          DialogNode(CharacterSpeaker.aura, "A high P/E ratio and massive debt is a recipe for catastrophic failure. Learn to read the diagnostics."),
        ];
      case 4:
        return const [
          DialogNode(CharacterSpeaker.crash, "Level 4: HYPERDRIVE! Leverage and Margin! Finally, we can borrow millions of credits to gamble!"),
          DialogNode(CharacterSpeaker.aura, "Warning. Leverage amplifies both gains and losses. It is the leading cause of ship destruction in the sector."),
          DialogNode(CharacterSpeaker.crash, "No risk, no reward! 100x leverage on dog coin! Let's go!"),
          DialogNode(CharacterSpeaker.aura, "Commander, proceed with extreme caution. Read the manual thoroughly."),
        ];
      case 5:
        return const [
          DialogNode(CharacterSpeaker.aura, "Level 5: Crisis Management. You will learn how to deploy Stop-Loss fields and manage your risk."),
          DialogNode(CharacterSpeaker.crash, "Stop-losses are for cowards! Real traders hold until zero! Diamond hands!"),
          DialogNode(CharacterSpeaker.aura, "Holding a failing asset is mathematically unsound. You must pre-define your exit coordinates before taking a position."),
        ];
      case 6:
        return const [
          DialogNode(CharacterSpeaker.aura, "Level 6: The Outer Rim. Crypto, Web3, and the dangers of unregulated space."),
          DialogNode(CharacterSpeaker.crash, "The wild west! Anonymous founders, zero regulations, infinite rug pulls! I love it here!"),
          DialogNode(CharacterSpeaker.aura, "The risks are astronomical, and The Empire still demands taxes on your profits. Study the protocols carefully."),
        ];
      default:
        return const [];
    }
  }

  // Phase 3 Micro-Learning applied feature scripts
  static List<DialogNode> getAppliedFeatureScript(String featureId) {
    switch (featureId) {
      case 'flight_deck_entry':
        return const [
          DialogNode(CharacterSpeaker.aura, "Welcome to the Flight Deck, Commander. This is the live market terminal."),
          DialogNode(CharacterSpeaker.aura, "Here you can scan for assets and execute trades using your fuel reserves."),
        ];
      case 'asset_chart':
        return const [
          DialogNode(CharacterSpeaker.aura, "This is the live telemetry chart. Use it to identify macroscopic trends before allocating capital."),
        ];
      case 'fundamentals_tab':
        return const [
          DialogNode(CharacterSpeaker.aura, "Diagnostic scan complete. These are the company's fundamentals. Check the P/E ratio and Debt levels before buying."),
        ];
      default:
        return const [];
    }
  }
}
