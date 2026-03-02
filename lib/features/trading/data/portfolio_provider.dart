import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/open_position.dart';
import '../domain/models/trade_history_item.dart';
import 'market_service.dart';
import '../../gamification/user_stats_provider.dart';

/// Holds active positions, closed-trade history, and balance events.
class PortfolioState {
  final List<OpenPosition> positions;
  final List<TradeHistoryItem> history;
  final List<BalanceEvent> balanceHistory;

  const PortfolioState({
    this.positions = const [],
    this.history = const [],
    this.balanceHistory = const [],
  });

  PortfolioState copyWith({
    List<OpenPosition>? positions,
    List<TradeHistoryItem>? history,
    List<BalanceEvent>? balanceHistory,
  }) {
    return PortfolioState(
      positions: positions ?? this.positions,
      history: history ?? this.history,
      balanceHistory: balanceHistory ?? this.balanceHistory,
    );
  }

  /// Total unrealized P&L across all positions given a price lookup.
  double totalUnrealizedPnl(double Function(String assetId) currentPriceFn) {
    return positions.fold(
        0.0, (sum, p) => sum + p.unrealizedPnl(currentPriceFn(p.assetId)));
  }

  /// Sum of all realized P&L from history.
  double get totalRealizedPnl =>
      history.fold(0.0, (sum, h) => sum + h.realizedPnl);
}

class PortfolioNotifier extends Notifier<PortfolioState> {
  @override
  PortfolioState build() => const PortfolioState();

  /// Open a new long/short position (multiple positions per asset allowed).
  void openPosition(OpenPosition position, {double? balanceAfter}) {
    state = state.copyWith(
      positions: [...state.positions, position],
      balanceHistory: [
        ...state.balanceHistory,
        BalanceEvent(
          timestamp: DateTime.now(),
          balanceAfter: balanceAfter ?? 0,
          delta: -(position.totalCost),
          description:
              'Opened ${position.isLong ? "LONG" : "SHORT"} ${position.assetSymbol} x${position.quantity.toStringAsFixed(2)}',
        ),
      ],
    );
  }

  /// Close a specific position by its unique [positionId].
  /// Returns realized P&L in INR, or null if not found.
  double? closePosition(String positionId, double currentPriceInr,
      {double? balanceAfter}) {
    final index = state.positions.indexWhere((p) => p.id == positionId);
    if (index == -1) return null;

    final position = state.positions[index];
    final pnl = position.realizedPnl(currentPriceInr);

    final historyItem = TradeHistoryItem(
      id: position.id,
      assetId: position.assetId,
      assetSymbol: position.assetSymbol,
      assetName: position.assetName,
      entryPrice: position.entryPrice,
      exitPrice: currentPriceInr,
      quantity: position.quantity,
      isLong: position.isLong,
      realizedPnl: pnl,
      openedAt: position.openedAt,
      closedAt: DateTime.now(),
    );

    final updatedPositions = [...state.positions]..removeAt(index);
    state = state.copyWith(
      positions: updatedPositions,
      history: [...state.history, historyItem],
      balanceHistory: [
        ...state.balanceHistory,
        BalanceEvent(
          timestamp: DateTime.now(),
          balanceAfter: balanceAfter ?? 0,
          delta: position.totalCost + pnl,
          description:
              'Closed ${position.assetSymbol} · P&L: ${pnl >= 0 ? "+" : ""}₹${pnl.toStringAsFixed(2)}',
        ),
      ],
    );
    return pnl;
  }

  /// Get all open positions for a given [assetId].
  List<OpenPosition> getPositionsForAsset(String assetId) {
    return state.positions.where((p) => p.assetId == assetId).toList();
  }

  /// Get a single position by its unique [positionId].
  OpenPosition? getPositionById(String positionId) {
    try {
      return state.positions.firstWhere((p) => p.id == positionId);
    } catch (_) {
      return null;
    }
  }
}

final portfolioProvider =
    NotifierProvider<PortfolioNotifier, PortfolioState>(() {
  return PortfolioNotifier();
});

/// Watches live prices via [liveMarketAssetsProvider] and auto-closes any
/// position whose [stopLoss] or [takeProfit] price level has been breached.
///
/// Use [ref.watch(autoTradeWatcherProvider)] inside any widget's build method
/// to keep this listener alive and active.
final autoTradeWatcherProvider = Provider<void>((ref) {
  // ref.listen is safe here — it defers mutations to after the current build.
  ref.listen<AsyncValue<List<dynamic>>>(
    liveMarketAssetsProvider,
    (_, next) {
      final liveAssets = next.valueOrNull;
      if (liveAssets == null) return;

      final portfolioNotifier = ref.read(portfolioProvider.notifier);
      final positions = ref.read(portfolioProvider).positions;

      for (final position in positions) {
        try {
          final asset = liveAssets.firstWhere((a) => a.id == position.assetId);
          final currentPrice = (asset.currentPrice as double);

          bool shouldClose = false;
          if (position.isLong) {
            if (position.stopLoss != null && currentPrice <= position.stopLoss!) {
              shouldClose = true;
            }
            if (position.takeProfit != null && currentPrice >= position.takeProfit!) {
              shouldClose = true;
            }
          } else {
            if (position.stopLoss != null && currentPrice >= position.stopLoss!) {
              shouldClose = true;
            }
            if (position.takeProfit != null && currentPrice <= position.takeProfit!) {
              shouldClose = true;
            }
          }

          if (shouldClose && portfolioNotifier.getPositionById(position.id) != null) {
            final pnl = position.realizedPnl(currentPrice);
            ref.read(userStatsProvider.notifier).addFuel(position.totalCost + pnl);
            final stats = ref.read(userStatsProvider).valueOrNull;
            portfolioNotifier.closePosition(
              position.id,
              currentPrice,
              balanceAfter: stats?.tradingCredits ?? 0.0,
            );
          }
        } catch (_) {
          // Position asset not in the live list — skip
        }
      }
    },
  );
});

