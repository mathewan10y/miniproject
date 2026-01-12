import 'dart:math';

class RefineryResult {
  final double fuelAdded;
  final bool isCritical;
  final double waste;

  const RefineryResult({
    required this.fuelAdded,
    required this.isCritical,
    required this.waste,
  });

  @override
  String toString() {
    return 'RefineryResult(fuelAdded: $fuelAdded, isCritical: $isCritical, waste: $waste)';
  }
}

class RefinerySystem {
  double totalSavings = 0.0;
  int rawOre = 0;
  double refinedFuel = 0.0;

  // The Mining Algorithm (Savings -> Ore)
  int calculateOreFromIncome(double amount) {
    if (amount <= 0) return 0;

    int totalOre = 0;
    double remainingAmount = amount;

    // Tier 1: First $500 at 1.0x rate
    if (remainingAmount > 0) {
      final tier1Amount = min(remainingAmount, 500.0);
      totalOre += (tier1Amount * 1.0).round();
      remainingAmount -= tier1Amount;
    }

    // Tier 2: Next $2000 (up to $2500 total) at 0.5x rate
    if (remainingAmount > 0) {
      final tier2Amount = min(remainingAmount, 2000.0);
      totalOre += (tier2Amount * 0.5).round();
      remainingAmount -= tier2Amount;
    }

    // Tier 3: Anything above $2500 at 0.1x rate
    if (remainingAmount > 0) {
      totalOre += (remainingAmount * 0.1).round();
    }

    return totalOre;
  }

  // The Refinery Algorithm (Ore -> Fuel)
  RefineryResult processRefinementTick() {
    if (rawOre < 10) {
      return const RefineryResult(
        fuelAdded: 0.0,
        isCritical: false,
        waste: 0.0,
      );
    }

    // Consume 10 Ore
    rawOre -= 10;

    // Check for critical hit (5% chance)
    final random = Random();
    final isCritical = random.nextDouble() < 0.05;

    // Calculate fuel production
    double fuelAdded;
    double waste;

    if (isCritical) {
      // Critical: 1.5x multiplier (10 Ore -> 12 Fuel)
      fuelAdded = 12.0;
      waste = 0.0;
    } else {
      // Base efficiency: 80% conversion rate (10 Ore -> 8 Fuel)
      fuelAdded = 8.0;
      waste = 2.0; // 20% waste
    }

    refinedFuel += fuelAdded;

    return RefineryResult(
      fuelAdded: fuelAdded,
      isCritical: isCritical,
      waste: waste,
    );
  }

  // Integration method for income transactions
  void processIncomeTransaction(double amount) {
    totalSavings += amount;
    final oreGenerated = calculateOreFromIncome(amount);
    rawOre += oreGenerated;
  }

  // Integration method for expense transactions
  void processExpenseTransaction(double amount) {
    totalSavings -= amount;
    // Ensure totalSavings doesn't go negative
    if (totalSavings < 0) {
      totalSavings = 0;
    }
    
    // Reduce ore based on expense amount (reverse of income calculation)
    // NOTE: This uses the exact same algorithm as income (calculateOreFromIncome) 
    // to ensure symmetry, as requested.
    final oreToReduce = calculateOreFromIncome(amount);
    print('DEBUG: Procesing Expense: $amount. Reducing Ore by: $oreToReduce. Current Ore: $rawOre');
    rawOre = (rawOre - oreToReduce).clamp(0, rawOre); // Don't go negative
  }

  // New method for processing refinement with custom amounts
  void processRefinementTickWithAmount(int oreConsumed, double fuelAdded) {
    if (rawOre >= oreConsumed) {
      rawOre -= oreConsumed;
      refinedFuel += fuelAdded;
    }
  }

  // Get current state
  Map<String, dynamic> getState() {
    return {
      'totalSavings': totalSavings,
      'rawOre': rawOre,
      'refinedFuel': refinedFuel,
    };
  }

  // Reset system (for testing)
  void reset() {
    totalSavings = 0.0;
    rawOre = 0;
    refinedFuel = 0.0;
  }
}
