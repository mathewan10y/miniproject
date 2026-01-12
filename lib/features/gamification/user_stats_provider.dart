import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_stats_model.dart';

class UserStatsNotifier extends Notifier<UserStatsModel> {
  @override
  UserStatsModel build() {
    // In a real app, you would load this from a database.
    // For now, we start with a default state.
    return UserStatsModel(userId: 'default_user');
  }

  void updateUserStats(UserStatsModel newStats) {
    state = newStats;
  }
}

final userStatsProvider = NotifierProvider<UserStatsNotifier, UserStatsModel>(() {
  return UserStatsNotifier();
});
