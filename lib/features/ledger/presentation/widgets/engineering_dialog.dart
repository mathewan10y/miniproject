import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/refinery_provider.dart';
import '../../../../core/services/refinery_system.dart';
import '../../../gamification/user_stats_provider.dart';

class RefineryResult {
  final double fuelAdded;
  final bool isCritical;
  final double waste;

  const RefineryResult({
    required this.fuelAdded,
    required this.isCritical,
    required this.waste,
  });
}

class EngineeringDialog extends ConsumerWidget {
  const EngineeringDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devMode = ref.watch(devModeProvider);
    final refineryState = ref.watch(refineryProvider).valueOrNull;
    
    // If no refinery state, show loading
    if (refineryState == null) {
      return const Dialog(
        backgroundColor: Colors.black,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
          ),
        ),
      );
    }
    
    final currentFuel = refineryState.refinedFuel;
    
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF00D9FF), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and fuel
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REACTOR ENGINEERING',
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFF00D9FF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fuel: ${currentFuel.toInt()}',
                  style: GoogleFonts.shareTechMono(
                    color: Colors.greenAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Upgrade cards
            _buildUpgradeCard(
              context,
              ref,
              'EFFICIENCY',
              refineryState.efficiencyLevel,
              refineryState.currentEfficiency * 100,
              refineryState.nextEfficiencyCost,
              () async {
                final success = await ref.read(refineryProvider.notifier).purchaseEfficiencyUpgrade();
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('INSUFFICIENT FUEL'),
                      backgroundColor: Colors.redAccent,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('EFFICIENCY UPGRADED!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              currentFuel,
            ),
            
            const SizedBox(height: 16),
            
            _buildUpgradeCard(
              context,
              ref,
              'CAPACITY',
              refineryState.capacityLevel,
              refineryState.maxCapacity,
              refineryState.nextCapacityCost,
              () async {
                final success = await ref.read(refineryProvider.notifier).purchaseCapacityUpgrade();
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('INSUFFICIENT FUEL'),
                      backgroundColor: Colors.redAccent,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('CAPACITY UPGRADED!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              currentFuel,
            ),
            
            const SizedBox(height: 16),
            
            _buildAutoInjectorCard(
              context,
              ref,
              refineryState,
              currentFuel,
              devMode,
            ),
            
            const SizedBox(height: 24),
            
            // Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'CLOSE',
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFF00D9FF),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard(
    BuildContext context,
    WidgetRef ref,
    String title,
    int currentLevel,
    dynamic currentValue,
    int cost,
    VoidCallback onPressed,
    double currentFuel,
  ) {
    final isMaxLevel = currentLevel >= 10;
    final canAfford = currentFuel >= cost;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B121C),
        border: Border.all(
          color: isMaxLevel ? Colors.green : (canAfford ? const Color(0xFF00D9FF) : Colors.grey),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'LEVEL $currentLevel / 10',
                style: GoogleFonts.shareTechMono(
                  color: isMaxLevel ? Colors.greenAccent : Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Current: ${currentValue is double ? (currentValue * 100).toInt() : currentValue}',
            style: GoogleFonts.shareTechMono(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMaxLevel ? 'MAX LEVEL' : 'Cost: ${cost.toString()} Fuel',
            style: GoogleFonts.shareTechMono(
              color: isMaxLevel ? Colors.greenAccent : Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isMaxLevel || !canAfford) ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isMaxLevel 
                    ? Colors.green 
                    : (canAfford ? const Color(0xFF00D9FF) : Colors.grey),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(
                isMaxLevel ? 'MAXED' : 'UPGRADE',
                style: GoogleFonts.orbitron(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoInjectorCard(
    BuildContext context,
    WidgetRef ref,
    RefinerySystem refineryState,
    double currentFuel,
    bool devMode,
  ) {
    final canUnlock = devMode || refineryState.canUnlockAutoInjector;
    final isMaxLevel = refineryState.autoInjectorLevel >= 5;
    final canAfford = currentFuel >= refineryState.autoInjectorCost;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B121C),
        border: Border.all(
          color: isMaxLevel 
              ? Colors.green 
              : (canUnlock ? (canAfford ? const Color(0xFF00D9FF) : Colors.orange) : Colors.red),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AUTO-INJECTOR',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'LEVEL ${refineryState.autoInjectorLevel} / 5',
                style: GoogleFonts.shareTechMono(
                  color: isMaxLevel ? Colors.greenAccent : Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Generates ${refineryState.autoInjectorLevel == 0 ? 0 : (1000 * refineryState.autoInjectorLevel)} Ore every 10 hours',
            style: GoogleFonts.shareTechMono(
              color: isMaxLevel ? Colors.greenAccent : Colors.white70,
              fontSize: 12,
            ),
          ),
          if (!canUnlock && !devMode) ...[
            const SizedBox(height: 8),
            Text(
              'REQUIRES EFFICIENCY 6 & CAPACITY 6',
              style: GoogleFonts.shareTechMono(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (devMode && !refineryState.canUnlockAutoInjector) ...[
            const SizedBox(height: 8),
            Text(
              'DEV MODE: REQUIREMENTS OVERRIDDEN',
              style: GoogleFonts.shareTechMono(
                color: Colors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isMaxLevel || !canUnlock || !canAfford) ? null : () async {
                final success = await ref.read(refineryProvider.notifier).purchaseAutoInjector();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('AUTO-INJECTOR UNLOCKED!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('INSUFFICIENT FUEL'),
                      backgroundColor: Colors.redAccent,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isMaxLevel 
                    ? Colors.green 
                    : (canUnlock && canAfford ? const Color(0xFF00D9FF) : Colors.grey),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(
                isMaxLevel ? 'MAXED' : 'UNLOCK (${refineryState.autoInjectorCost} Fuel)',
                style: GoogleFonts.orbitron(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
