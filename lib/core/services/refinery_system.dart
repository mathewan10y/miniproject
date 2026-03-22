import 'dart:math' as math;
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
  int efficiencyLevel = 1;
  int capacityLevel = 1;
  int autoInjectorLevel = 0; // Max level 5
  int lastAutoInjectTimeMs = 0;
  
  // Static progression tables for non-linear upgrades
  static const List<double> _efficiencyMap = [
    0.70, 0.75, 0.80, 0.82, 0.84, 0.86, 0.88, 0.90, 0.92, 0.94
  ];
  
  static const List<int> _capacityMap = [
    10000, 12000, 14000, 16000, 18000, 20000, 25000, 30000, 40000, 50000
  ];
  
  // Dynamic getters for current values
  double get currentEfficiency => _efficiencyMap[efficiencyLevel - 1];
  int get maxCapacity => _capacityMap[capacityLevel - 1];
  bool get canUnlockAutoInjector => efficiencyLevel >= 6 && capacityLevel >= 6;
  
  // Dynamic cost calculations
  int get nextEfficiencyCost => efficiencyLevel >= 10 ? 0 : efficiencyLevel * 5000;
  int get nextCapacityCost => capacityLevel >= 10 ? 0 : capacityLevel * 4000;
  int get autoInjectorCost => 30000; // Flat cost per level
  
  // Auto-injection logic
  int checkAndApplyAutoInjection() {
    if (autoInjectorLevel == 0) return 0;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeDiff = now - lastAutoInjectTimeMs;
    
    // A 10-hour cycle is 36,000,000 ms
    const cycleMs = 36000000;
    final cyclesPassed = (timeDiff / cycleMs).floor();
    
    if (cyclesPassed > 0) {
      final oreToAdd = cyclesPassed * (1000 * autoInjectorLevel);
      final actualOreToAdd = math.min(oreToAdd, maxCapacity - rawOre); // Don't exceed max capacity
      rawOre += actualOreToAdd;
      lastAutoInjectTimeMs += (cyclesPassed * cycleMs);
      return actualOreToAdd;
    }
    
    return 0;
  }
  
  // Purchase methods
  bool purchaseEfficiencyUpgrade(int availableFuel) {
    if (efficiencyLevel >= 10) return false;
    efficiencyLevel++;
    return true;
  }
  
  bool purchaseCapacityUpgrade(int availableFuel) {
    if (capacityLevel >= 10) return false;
    capacityLevel++;
    return true;
  }
  
  bool purchaseAutoInjector(int availableFuel) {
    if (autoInjectorLevel >= 5) return false;
    autoInjectorLevel++;
    lastAutoInjectTimeMs = DateTime.now().millisecondsSinceEpoch; // Reset timer on purchase
    return true;
  }
  
  // Legacy methods for compatibility
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
    final actualOreToAdd = math.min(oreGenerated, maxCapacity - rawOre); // Don't exceed max capacity
    rawOre += actualOreToAdd;
    // Safety check: ensure we never exceed max capacity
    rawOre = rawOre.clamp(0, maxCapacity);
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
    print('DEBUG: Processing Expense: $amount. Reducing Ore by: $oreToReduce. Current Ore: $rawOre');
    rawOre = (rawOre - oreToReduce).clamp(0, rawOre); // Don't go negative
  }

  // New method for processing refinement with custom amounts
  void processRefinementTickWithAmount(int oreConsumed, double fuelAdded) {
    if (rawOre >= oreConsumed) {
      rawOre -= oreConsumed;
      refinedFuel += fuelAdded;
    }
  }

  // Trading: safely deduct fuel (returns false if insufficient)
  bool deductFuel(double amount) {
    if (refinedFuel >= amount) {
      refinedFuel -= amount;
      return true;
    }
    return false;
  }

  // Trading: add fuel back (e.g. on position close); clamps to 0 if negative
  void addFuel(double amount) {
    refinedFuel += amount;
    if (refinedFuel < 0) {
      refinedFuel = 0.0;
    }
  }

  // Get current state
  Map<String, dynamic> getState() {
    return {
      'efficiencyLevel': efficiencyLevel,
      'capacityLevel': capacityLevel,
      'autoInjectorLevel': autoInjectorLevel,
      'lastAutoInjectTimeMs': lastAutoInjectTimeMs,
      'totalSavings': totalSavings,
      'rawOre': rawOre,
      'refinedFuel': refinedFuel,
    };
  }

  // Reset system (for testing)
  void reset() {
    efficiencyLevel = 1;
    capacityLevel = 1;
    autoInjectorLevel = 0;
    lastAutoInjectTimeMs = 0;
    totalSavings = 0.0;
    rawOre = 0;
    refinedFuel = 0.0;
  }
}
