import '../../core/models/expense_model.dart';
import '../../core/models/user_stats_model.dart';

class AuditEngine {
  // Processes a list of expenses and updates user stats.
  UserStatsModel processExpenses(List<ExpenseModel> expenses, UserStatsModel currentUserStats) {
    if (expenses.isEmpty) return currentUserStats;

    double totalSpending = expenses.fold(0, (sum, item) => sum + item.amount);
    double totalWants = expenses
        .where((e) => e.isWant)
        .fold(0, (sum, item) => sum + item.amount);

    // Calculate Waste Score (0 to 1, where 1 is 100% wants)
    // Used in future calculations for user engagement metrics
    totalSpending > 0 ? totalWants / totalSpending : 0;

    // Update XP and Trading Credits based on the recent batch of expenses
    // This is a simple example logic. This can be made more complex.
    int xpGained = (totalSpending * 0.1).round(); // 1 XP for every $10 spent
    double creditsGained = (totalSpending - totalWants) * 0.05; // 5% of 'needs' spending as credits

    currentUserStats.xp += xpGained;
    currentUserStats.tradingCredits += creditsGained;

    // Level up logic (e.g., every 1000 XP)
    if (currentUserStats.xp >= (currentUserStats.currentLevel * 1000)) {
      currentUserStats.currentLevel++;
      currentUserStats.xp = 0; // Reset XP for the new level
      // Give a bonus for leveling up
      currentUserStats.tradingCredits += 100;
    }

    return currentUserStats;
  }
}
