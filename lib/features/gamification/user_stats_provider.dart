import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/user_stats_model.dart';

const _kTradeCreditsKey = 'user_trading_credits';
const _kDefaultCredits = 5000.0;

class UserStatsNotifier extends AsyncNotifier<UserStatsModel> {
  @override
  Future<UserStatsModel> build() async {
    return await _load();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<UserStatsModel> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final credits = prefs.getDouble(_kTradeCreditsKey) ?? _kDefaultCredits;
    return UserStatsModel(userId: 'default_user', tradingCredits: credits);
  }

  Future<void> _save(UserStatsModel s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTradeCreditsKey, s.tradingCredits);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  void updateUserStats(UserStatsModel newStats) {
    state = AsyncData(newStats);
    _save(newStats);
  }

  /// Deduct [amount] of FUEL (INR) from trading credits.
  /// Returns true if successful, false if insufficient funds.
  bool deductFuel(double amount) {
    final current = state.valueOrNull;
    if (current == null || current.tradingCredits < amount) return false;
    final next = current.copyWith(
      tradingCredits: current.tradingCredits - amount,
    );
    state = AsyncData(next);
    _save(next);
    return true;
  }

  /// Add [amount] of FUEL (INR) back to trading credits (on sell / close).
  void addFuel(double amount) {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = current.copyWith(
      tradingCredits: current.tradingCredits + amount,
    );
    state = AsyncData(next);
    _save(next);
  }

  /// Sync FUEL with the refinery's refinedFuel (called when refinery produces fuel).
  void addRefineryFuel(double fuelAdded) {
    // 1 Refined Fuel = 10 INR of trading credits
    const double fuelToInrRate = 10.0;
    final current = state.valueOrNull;
    if (current == null) return;
    final next = current.copyWith(
      tradingCredits: current.tradingCredits + (fuelAdded * fuelToInrRate),
    );
    state = AsyncData(next);
    _save(next);
  }
}

final userStatsProvider =
    AsyncNotifierProvider<UserStatsNotifier, UserStatsModel>(
      UserStatsNotifier.new,
    );
