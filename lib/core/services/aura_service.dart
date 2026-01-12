import '../models/user_stats_model.dart';

class AuraService {
  // Returns helpful encouragement based on the user's stats.
  String getEncouragement(UserStatsModel stats) {
    if (stats.tradingCredits > 50) {
      return "Your Trading Power is growing. Every credit earned is a step towards financial freedom.";
    }
    return "Every small step counts. Keep tracking your expenses and building good habits!";
  }
}
