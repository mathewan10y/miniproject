import '../models/user_stats_model.dart';

class AuraService {

  // Returns helpful encouragement based on the user's stats.
  String getEncouragement(UserStatsModel stats) {
    if (stats.tradingCredits > 50) {
      return "Your Trading Power is growing. Every credit earned is a step towards financial freedom.";
    }
    return "Every small step counts. Keep tracking your expenses and building good habits!";
  }

  String getVarsityBriefing() {
    return """Report. We have analyzed the Zerodha archives. The path to victory is clear, but the ascent is steep.

The Doctrine:

Level 1 (Recruit): Basic Training. You will learn what a stock is before you dare to buy one.

Level 2 (Scout): Vision. You will learn to read the charts. If you cannot see the enemy (trends), you cannot fight.

Level 3 (Strategist): Intelligence. Charts lie; numbers do not. You will learn to dissect a balance sheet.

Level 4 (Operator): Warfare. Derivatives. Options. This is where the undisciplined go to die. You will master the Greeks, or you will be liquidated.

Proceed to Level 1. Do not fail me.""";
  }
}
