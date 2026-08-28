import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/refinery_provider.dart';

class IncomeNotifier extends AsyncNotifier<List<Income>> {
  late AppDatabase _db;

  @override
  Future<List<Income>> build() async {
    _db = AppDatabase();

    // 1. Watch auth state changes so this provider automatically rebuilds when the user logs in / session restores.
    final authStateAsync = ref.watch(authStateChangesProvider);

    // 2. Resolve user from auth stream event or directly from Supabase client
    final session = authStateAsync.valueOrNull?.session ?? Supabase.instance.client.auth.currentSession;
    final user = session?.user ?? Supabase.instance.client.auth.currentUser;

    // 3. If user is null (session not yet resolved or logged out), return an empty list without querying Supabase.
    if (user == null) {
      debugPrint('[IncomeNotifier] User is null / session not ready. Returning empty list.');
      return const [];
    }

    // 4. Safely query Supabase with confirmed user session.
    try {
      return await _db.getAllIncomes();
    } catch (e) {
      debugPrint('[IncomeNotifier] Error fetching incomes: $e');
      return const [];
    }
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
    await ref.read(refineryProvider.notifier).processIncome(amount);

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
