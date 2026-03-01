import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database.dart';
import '../../core/providers/refinery_provider.dart';

class IncomeNotifier extends AsyncNotifier<List<Income>> {
  late AppDatabase _db;

  @override
  Future<List<Income>> build() async {
    _db = AppDatabase();
    return await _db.getAllIncomes();
  }

  /// Adds an income, persists to Supabase, then prepends directly to state —
  /// no full re-fetch so the UI responds instantly without a loading spinner.
  Future<void> addIncome(double amount, String category) async {
    final newIncome = Income(
      id: const Uuid().v4(),
      amount: amount,
      category: category,
      timestamp: DateTime.now(),
    );

    // Persist to Supabase first (throws on network error)
    await _db.addIncome(newIncome);

    // Process through gamification (convert savings to ore)
    ref.read(refineryProvider.notifier).processIncome(amount);

    // O(1) state update — prepend new item, no round-trip query needed
    final current = state.valueOrNull ?? [];
    state = AsyncData([newIncome, ...current]);
  }

  /// Deletes an income from Supabase and removes it from state in-place.
  Future<void> deleteIncome(String id) async {
    await _db.deleteIncome(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((i) => i.id != id).toList());
  }
}

final incomeProvider = AsyncNotifierProvider<IncomeNotifier, List<Income>>(() {
  return IncomeNotifier();
});
