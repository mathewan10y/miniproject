import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/user_stats_model.dart';

const _kTradeCreditsKey = 'user_trading_credits';
const _kXpKey = 'user_xp';
const _kLevelKey = 'user_level';
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
    final xp = prefs.getInt(_kXpKey) ?? 0;
    final level = prefs.getInt(_kLevelKey) ?? 1;
    return UserStatsModel(
      userId: 'default_user', 
      tradingCredits: credits,
      xp: xp,
      currentLevel: level,
    );
  }

  Future<void> _save(UserStatsModel s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTradeCreditsKey, s.tradingCredits);
    await prefs.setInt(_kXpKey, s.xp);
    await prefs.setInt(_kLevelKey, s.currentLevel);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  void updateUserStats(UserStatsModel newStats) {
    state = AsyncData(newStats);
    _save(newStats);
  }

  void addExperience(int amount) {
    final current = state.valueOrNull;
    if (current == null) return;
    updateUserStats(current.copyWith(xp: current.xp + amount));
  }

  Future<void> levelUp() async {
    final prefs = await SharedPreferences.getInstance();
    final currentLevel = prefs.getInt(_kLevelKey) ?? 1;
    final newLevel = currentLevel + 1;
    await prefs.setInt(_kLevelKey, newLevel);
    state = AsyncData(UserStatsModel(
      userId: 'default_user',
      tradingCredits: state.valueOrNull?.tradingCredits ?? 0,
      xp: state.valueOrNull?.xp ?? 0,
      currentLevel: newLevel,
    ));
  }

  // ── Reset Methods ────────────────────────────────────────────────────────────

  Future<void> resetUserProgress() async {
    final resetStats = UserStatsModel(
      userId: 'default_user',
      tradingCredits: _kDefaultCredits,
      xp: 0,
      currentLevel: 1,
    );
    
    state = AsyncData(resetStats);
    await _save(resetStats);
  }

  Future<void> setLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLevelKey, level);
    state = AsyncData(UserStatsModel(
      userId: 'default_user',
      tradingCredits: state.value?.tradingCredits ?? 0,
      xp: state.value?.xp ?? 0,
      currentLevel: level,
    ));
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

/// When true, all levels are unlocked regardless of userStats.currentLevel.
final devModeProvider = StateProvider<bool>((ref) => false);
