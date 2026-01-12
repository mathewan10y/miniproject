import 'package:flutter/material.dart';

class CreditVault extends StatelessWidget {
  final double tradingPower;

  const CreditVault({super.key, required this.tradingPower});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.colorScheme.secondary, width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TRADING POWER',
            style: TextStyle(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${tradingPower.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: theme.colorScheme.primary.withOpacity(0.7),
                  blurRadius: 15,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
