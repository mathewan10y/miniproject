import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/refinery_system.dart';

// Provider for the RefinerySystem instance
final refineryProvider = StateNotifierProvider<RefineryNotifier, RefinerySystem>((ref) {
  return RefineryNotifier();
});

class RefineryNotifier extends StateNotifier<RefinerySystem> {
  RefineryNotifier() : super(RefinerySystem());

  // Wrapper method for processing income transactions
  void processIncome(double amount) {
    state.processIncomeTransaction(amount);
    // Update state to trigger rebuilds
    state = RefinerySystem()
      ..totalSavings = state.totalSavings
      ..rawOre = state.rawOre
      ..refinedFuel = state.refinedFuel;
  }

  // Wrapper method for processing expense transactions
  void processExpense(double amount) {
    state.processExpenseTransaction(amount);
    // Update state to trigger rebuilds
    state = RefinerySystem()
      ..totalSavings = state.totalSavings
      ..rawOre = state.rawOre
      ..refinedFuel = state.refinedFuel;
  }

  // Wrapper method for refinery ticks
  RefineryResult processRefinementTick() {
    final result = state.processRefinementTick();
    // Update state to trigger rebuilds
    state = RefinerySystem()
      ..totalSavings = state.totalSavings
      ..rawOre = state.rawOre
      ..refinedFuel = state.refinedFuel;
    return result;
  }

  // Wrapper method for custom amount refinement
  void processRefinementTickWithAmount(int oreConsumed, double fuelAdded) {
    state.processRefinementTickWithAmount(oreConsumed, fuelAdded);
    // Update state to trigger rebuilds
    state = RefinerySystem()
      ..totalSavings = state.totalSavings
      ..rawOre = state.rawOre
      ..refinedFuel = state.refinedFuel;
  }

  // Reset the system
  void reset() {
    state.reset();
    state = RefinerySystem();
  }

  // Get ore from income (for preview/calculations)
  int calculateOreFromIncome(double amount) {
    return state.calculateOreFromIncome(amount);
  }
}
