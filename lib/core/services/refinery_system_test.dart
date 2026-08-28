import '../services/refinery_system.dart';
import 'package:flutter/foundation.dart';

void main() {
  final refinery = RefinerySystem();

  debugPrint('=== Refinery System Test ===\n');

  // Test 1: Tiered Mining Algorithm
  debugPrint('Test 1: Tiered Mining Algorithm');
  debugPrint('Saving \$500 should give 500 ore: ${refinery.calculateOreFromIncome(500)}');
  debugPrint('Saving \$2500 should give 1500 ore: ${refinery.calculateOreFromIncome(2500)}');
  debugPrint('Saving \$3000 should give 1550 ore: ${refinery.calculateOreFromIncome(3000)}');
  debugPrint('Saving \$10000 should give 1800 ore: ${refinery.calculateOreFromIncome(10000)}');
  debugPrint('');

  // Test 2: Income Processing
  debugPrint('Test 2: Income Processing');
  refinery.processIncomeTransaction(3000);
  debugPrint('After \$3000 income:');
  debugPrint('  Total Savings: \$${refinery.totalSavings}');
  debugPrint('  Raw Ore: ${refinery.rawOre}');
  debugPrint('  Refined Fuel: ${refinery.refinedFuel}');
  debugPrint('');

  // Test 3: Refinery Process
  debugPrint('Test 3: Refinery Process (multiple ticks)');
  int ticks = 0;
  int criticalHits = 0;
  
  while (refinery.rawOre >= 10 && ticks < 10) {
    final result = refinery.processRefinementTick();
    ticks++;
    if (result.isCritical) criticalHits++;
    
    debugPrint('Tick $ticks: +${result.fuelAdded.toStringAsFixed(1)} fuel '
          '${result.isCritical ? '(CRITICAL!)' : '(waste: ${result.waste})'}');
  }
  
  debugPrint('');
  debugPrint('Final State:');
  debugPrint('  Total Savings: \$${refinery.totalSavings}');
  debugPrint('  Raw Ore: ${refinery.rawOre}');
  debugPrint('  Refined Fuel: ${refinery.refinedFuel.toStringAsFixed(1)}');
  debugPrint('  Critical Hits: $criticalHits out of $ticks ticks');
}
