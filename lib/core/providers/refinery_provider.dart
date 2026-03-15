import 'dart:async';
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
  // Completer that resolves once build() has finished loading from SharedPreferences.
  // Every mutation method awaits this so it can never run on stale/zero state.
  late final Future<void> _initialLoad;

  @override
  Future<RefinerySystem> build() async {
    print('REFINERY: Loading saved state...');
    final completer = Completer<void>();
    _initialLoad = completer.future;

    final result = await _load();

    completer.complete(); // signal that load is done
    print('REFINERY: Loaded ore=${result.rawOre} fuel=${result.refinedFuel}');
    return result;
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
    print('REFINERY: Saved ore=${s.rawOre} fuel=${s.refinedFuel}');
  }

  // ── Helpers to snapshot state immutably ──────────────────────────────────

  RefinerySystem _snapshot(RefinerySystem src) =>
      RefinerySystem()
        ..totalSavings = src.totalSavings
        ..rawOre = src.rawOre
        ..refinedFuel = src.refinedFuel;

  // Returns the live state. Must only be called AFTER _initialLoad has resolved
  // (i.e., inside methods that already await _initialLoad).
  RefinerySystem get _current => state.requireValue;

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> processIncome(double amount) async {
    print('REFINERY: processIncome called with $amount');
    await _initialLoad; // wait for SharedPreferences load to finish
    print('REFINERY: load completed, modifying state for income');

    final s = _current;
    s.processIncomeTransaction(amount);
    final next = _snapshot(s);
    state = AsyncData(next);
    await _save(next);
  }

  Future<void> processExpense(double amount) async {
    print('REFINERY: processExpense called with $amount');
    await _initialLoad; // wait for SharedPreferences load to finish

    final s = _current;
    s.processExpenseTransaction(amount);
    final next = _snapshot(s);
    state = AsyncData(next);
    await _save(next);
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

  /// Deducts [amount] from refinedFuel. Returns true on success, false if
  /// insufficient balance. State is persisted on success.
  bool deductFuel(double amount) {
    final s = _current;
    final success = s.deductFuel(amount);
    if (success) {
      final next = _snapshot(s);
      state = AsyncData(next);
      _save(next);
    }
    return success;
  }

  /// Adds [amount] to refinedFuel (e.g. margin return + P&L on close).
  /// Negative balance is clamped to 0. State is always persisted.
  void addFuel(double amount) {
    final s = _current;
    s.addFuel(amount);
    final next = _snapshot(s);
    state = AsyncData(next);
    _save(next);
  }

  int calculateOreFromIncome(double amount) =>
      _current.calculateOreFromIncome(amount);
}
