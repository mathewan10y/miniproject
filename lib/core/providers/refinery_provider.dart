import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/refinery_system.dart';

const _kRefineryKey = 'refinery_state';

// ─── Provider ────────────────────────────────────────────────────────────────

/// AsyncNotifier so we can await SharedPreferences in build().
final refineryProvider =
    AsyncNotifierProvider<RefineryNotifier, RefinerySystem>(
      RefineryNotifier.new,
    );

// ─── Notifier ────────────────────────────────────────────────────────────────

class RefineryNotifier extends AsyncNotifier<RefinerySystem> {
  @override
  Future<RefinerySystem> build() async {
    return await _load();
  }

  // ── Persistence helpers ───────────────────────────────────────────────────

  /// Load saved state from SharedPreferences. Returns defaults on first run.
  Future<RefinerySystem> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRefineryKey);
    if (raw == null) return RefinerySystem();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return RefinerySystem()
        ..totalSavings = (map['totalSavings'] as num?)?.toDouble() ?? 0.0
        ..rawOre = (map['rawOre'] as int?) ?? 0
        ..refinedFuel = (map['refinedFuel'] as num?)?.toDouble() ?? 0.0;
    } catch (_) {
      return RefinerySystem();
    }
  }

  /// Persist the current RefinerySystem state to SharedPreferences.
  Future<void> _save(RefinerySystem s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kRefineryKey,
      jsonEncode({
        'totalSavings': s.totalSavings,
        'rawOre': s.rawOre,
        'refinedFuel': s.refinedFuel,
      }),
    );
  }

  // ── Helpers to snapshot state immutably ──────────────────────────────────

  RefinerySystem _snapshot(RefinerySystem src) =>
      RefinerySystem()
        ..totalSavings = src.totalSavings
        ..rawOre = src.rawOre
        ..refinedFuel = src.refinedFuel;

  RefinerySystem get _current => state.valueOrNull ?? RefinerySystem();

  // ── Public API ────────────────────────────────────────────────────────────

  void processIncome(double amount) {
    final s = _current;
    s.processIncomeTransaction(amount);
    final next = _snapshot(s);
    state = AsyncData(next);
    _save(next);
  }

  void processExpense(double amount) {
    final s = _current;
    s.processExpenseTransaction(amount);
    final next = _snapshot(s);
    state = AsyncData(next);
    _save(next);
  }

  RefineryResult processRefinementTick() {
    final s = _current;
    final result = s.processRefinementTick();
    final next = _snapshot(s);
    state = AsyncData(next);
    _save(next);
    return result;
  }

  void processRefinementTickWithAmount(int oreConsumed, double fuelAdded) {
    final s = _current;
    s.processRefinementTickWithAmount(oreConsumed, fuelAdded);
    final next = _snapshot(s);
    state = AsyncData(next);
    _save(next);
  }

  void reset() {
    final next = RefinerySystem();
    state = AsyncData(next);
    _save(next);
  }

  int calculateOreFromIncome(double amount) =>
      _current.calculateOreFromIncome(amount);
}
