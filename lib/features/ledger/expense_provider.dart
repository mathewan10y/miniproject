import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database.dart';
import '../../core/providers/refinery_provider.dart';

// The AsyncNotifier for our expenses
class ExpenseNotifier extends AsyncNotifier<List<Expense>> {
  late AppDatabase _db;

  @override
  Future<List<Expense>> build() async {
    _db = AppDatabase();
    return await _db.getAllExpenses();
  }

  // Add a new expense
  Future<void> addExpense(double amount, String category, bool isWant) async {
    final newExpense = Expense(
      id: const Uuid().v4(),
      amount: amount,
      category: category,
      isWant: isWant,
      timestamp: DateTime.now(),
    );

    // Update the state to loading
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      // 1. Save to local DB
      await _db.addExpense(newExpense);

      // 2. Process expense through RefinerySystem (deduct from savings)
      final refineryNotifier = ref.read(refineryProvider.notifier);
      refineryNotifier.processExpense(amount);

      // 3. Return the updated list of expenses
      return await _db.getAllExpenses();
    });
  }

  // Delete an expense
  Future<void> deleteExpense(String id) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _db.deleteExpense(id);
      return await _db.getAllExpenses();
    });
  }
}

// The provider for the ExpenseNotifier
final expenseProvider = AsyncNotifierProvider<ExpenseNotifier, List<Expense>>(() {
  return ExpenseNotifier();
});
