import '../services/refinery_system.dart';

void main() {
  final refinery = RefinerySystem();

  print('=== Refinery System Test ===\n');

  // Test 1: Tiered Mining Algorithm
  print('Test 1: Tiered Mining Algorithm');
  print('Saving \$500 should give 500 ore: ${refinery.calculateOreFromIncome(500)}');
  print('Saving \$2500 should give 1500 ore: ${refinery.calculateOreFromIncome(2500)}');
  print('Saving \$3000 should give 1550 ore: ${refinery.calculateOreFromIncome(3000)}');
  print('Saving \$10000 should give 1800 ore: ${refinery.calculateOreFromIncome(10000)}');
  print('');

  // Test 2: Income Processing
  print('Test 2: Income Processing');
  refinery.processIncomeTransaction(3000);
  print('After \$3000 income:');
  print('  Total Savings: \$${refinery.totalSavings}');
  print('  Raw Ore: ${refinery.rawOre}');
  print('  Refined Fuel: ${refinery.refinedFuel}');
  print('');

  // Test 3: Refinery Process
  print('Test 3: Refinery Process (multiple ticks)');
  int ticks = 0;
  int criticalHits = 0;
  
  while (refinery.rawOre >= 10 && ticks < 10) {
    final result = refinery.processRefinementTick();
    ticks++;
    if (result.isCritical) criticalHits++;
    
    print('Tick $ticks: +${result.fuelAdded.toStringAsFixed(1)} fuel '
          '${result.isCritical ? '(CRITICAL!)' : '(waste: ${result.waste})'}');
  }
  
  print('');
  print('Final State:');
  print('  Total Savings: \$${refinery.totalSavings}');
  print('  Raw Ore: ${refinery.rawOre}');
  print('  Refined Fuel: ${refinery.refinedFuel.toStringAsFixed(1)}');
  print('  Critical Hits: $criticalHits out of $ticks ticks');
}
