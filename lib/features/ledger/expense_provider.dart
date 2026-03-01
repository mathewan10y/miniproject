import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database.dart';
import '../../core/providers/refinery_provider.dart';

class ExpenseNotifier extends AsyncNotifier<List<Expense>> {
  late AppDatabase _db;

  @override
  Future<List<Expense>> build() async {
    _db = AppDatabase();
    return await _db.getAllExpenses();
  }

  /// Adds an expense, persists to Supabase, then appends directly to state —
  /// no full re-fetch so the UI responds instantly without a loading spinner.
  Future<void> addExpense(double amount, String category, bool isWant) async {
    final newExpense = Expense(
      id: const Uuid().v4(),
      amount: amount,
      category: category,
      isWant: isWant,
      timestamp: DateTime.now(),
    );

    // Persist to Supabase first (throws on network error)
    await _db.addExpense(newExpense);

    // Process through gamification (deduct from savings)
    ref.read(refineryProvider.notifier).processExpense(amount);

    // O(1) state update — prepend new item, no round-trip query needed
    final current = state.valueOrNull ?? [];
    state = AsyncData([newExpense, ...current]);
  }

  /// Deletes an expense from Supabase and removes it from state in-place.
  Future<void> deleteExpense(String id) async {
    await _db.deleteExpense(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((e) => e.id != id).toList());
  }
}

final expenseProvider = AsyncNotifierProvider<ExpenseNotifier, List<Expense>>(
  () {
    return ExpenseNotifier();
  },
);
