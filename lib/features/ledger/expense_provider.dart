import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/refinery_provider.dart';

class ExpenseNotifier extends AsyncNotifier<List<Expense>> {
  late AppDatabase _db;

  @override
  Future<List<Expense>> build() async {
    _db = AppDatabase();

    // 1. Watch auth state changes so this provider automatically rebuilds when the user logs in / session restores.
    final authStateAsync = ref.watch(authStateChangesProvider);

    // 2. Resolve user from auth stream event or directly from Supabase client
    final session = authStateAsync.valueOrNull?.session ?? Supabase.instance.client.auth.currentSession;
    final user = session?.user ?? Supabase.instance.client.auth.currentUser;

    // 3. If user is null (session not yet resolved or logged out), return an empty list without querying Supabase.
    if (user == null) {
      debugPrint('[ExpenseNotifier] User is null / session not ready. Returning empty list.');
      return const [];
    }

    // 4. Safely query Supabase with confirmed user session.
    try {
      return await _db.getAllExpenses();
    } catch (e) {
      debugPrint('[ExpenseNotifier] Error fetching expenses: $e');
      return const [];
    }
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
