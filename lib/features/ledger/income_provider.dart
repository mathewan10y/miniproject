import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database.dart';
import '../../core/providers/refinery_provider.dart';

// The AsyncNotifier for our incomes
class IncomeNotifier extends AsyncNotifier<List<Income>> {
  late AppDatabase _db;

  @override
  Future<List<Income>> build() async {
    _db = AppDatabase();
    return await _db.getAllIncomes();
  }

  // Add a new income
  Future<void> addIncome(double amount, String category) async {
    final newIncome = Income(
      id: const Uuid().v4(),
      amount: amount,
      category: category,
      timestamp: DateTime.now(),
    );

    // Update the state to loading
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      // 1. Save to local DB
      await _db.addIncome(newIncome);

      // 2. Process income through RefinerySystem (convert savings to ore)
      final refineryNotifier = ref.read(refineryProvider.notifier);
      refineryNotifier.processIncome(amount);

      // 3. Return the updated list of incomes
      return await _db.getAllIncomes();
    });
  }

  // Delete an income
  Future<void> deleteIncome(String id) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _db.deleteIncome(id);
      return await _db.getAllIncomes();
    });
  }
}

// The provider for the IncomeNotifier
final incomeProvider = AsyncNotifierProvider<IncomeNotifier, List<Income>>(() {
  return IncomeNotifier();
});
