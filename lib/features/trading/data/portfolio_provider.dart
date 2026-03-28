import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/open_position.dart';
import '../domain/models/trade_history_item.dart';
import 'market_service.dart';
import '../../../core/providers/refinery_provider.dart';
import '../../../core/database/database.dart';

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

class PortfolioNotifier extends AsyncNotifier<PortfolioState> {
  final _db = AppDatabase();

  @override
  Future<PortfolioState> build() async {
    try {
      final positions = await _db.getAllOpenPositions();
      final history = await _db.getAllTradeHistory();
      return PortfolioState(
        positions: positions,
        history: history,
        balanceHistory: const [],
      );
    } catch (e) {
      // On fetch failure, start with empty state rather than crashing.
      print('[PortfolioNotifier] build() fetch failed: $e');
      return const PortfolioState();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns the current synced state, or empty if still loading.
  PortfolioState get _current => state.valueOrNull ?? const PortfolioState();

  /// Open a new long/short position (multiple positions per asset allowed).
  Future<void> openPosition(OpenPosition position,
      {double? balanceAfter}) async {
    try {
      await _db.addOpenPosition(position);
    } catch (e) {
      print('[PortfolioNotifier] openPosition Supabase insert failed: $e');
      // Proceed with local update even if remote fails (best-effort)
    }
    final current = _current;
    state = AsyncData(
      current.copyWith(
        positions: [...current.positions, position],
        balanceHistory: [
          ...current.balanceHistory,
          BalanceEvent(
            timestamp: DateTime.now(),
            balanceAfter: balanceAfter ?? 0,
            delta: -(position.totalCost),
            description:
                'Opened ${position.isLong ? "LONG" : "SHORT"} ${position.assetSymbol} x${position.quantity.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  /// Close a specific position by its unique [positionId].
  /// Returns realized P&L in INR, or null if not found.
  Future<double?> closePosition(String positionId, double currentPriceInr,
      {double? balanceAfter}) async {
    final current = _current;
    final index = current.positions.indexWhere((p) => p.id == positionId);
    if (index == -1) return null;

    final position = current.positions[index];
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

    // Persist to Supabase (best-effort)
    try {
      await Future.wait([
        _db.deleteOpenPosition(positionId),
        _db.addTradeHistory(historyItem),
      ]);
    } catch (e) {
      print('[PortfolioNotifier] closePosition Supabase ops failed: $e');
    }

    final updatedPositions = [...current.positions]..removeAt(index);
    state = AsyncData(
      current.copyWith(
        positions: updatedPositions,
        history: [...current.history, historyItem],
        balanceHistory: [
          ...current.balanceHistory,
          BalanceEvent(
            timestamp: DateTime.now(),
            balanceAfter: balanceAfter ?? 0,
            delta: position.totalCost + pnl,
            description:
                'Closed ${position.assetSymbol} · P&L: ${pnl >= 0 ? "+" : ""}₹${pnl.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
    return pnl;
  }

  /// Get all open positions for a given [assetId].
  List<OpenPosition> getPositionsForAsset(String assetId) {
    return _current.positions.where((p) => p.assetId == assetId).toList();
  }

  /// Get a single position by its unique [positionId].
  OpenPosition? getPositionById(String positionId) {
    try {
      return _current.positions.firstWhere((p) => p.id == positionId);
    } catch (_) {
      return null;
    }
  }

  /// Reset the entire portfolio (positions and history) locally and in DB.
  Future<void> resetPortfolio() async {
    try {
      await Future.wait([
        _db.clearAllOpenPositions(),
        _db.clearAllTradeHistory(),
      ]);
    } catch (e) {
      print('[PortfolioNotifier] resetPortfolio Supabase ops failed: $e');
    }

    state = const AsyncData(PortfolioState());
  }
}

final portfolioProvider =
    AsyncNotifierProvider<PortfolioNotifier, PortfolioState>(() {
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
      // Read positions from the async state's value
      final positions =
          ref.read(portfolioProvider).valueOrNull?.positions ?? [];

      for (final position in positions) {
        try {
          final asset = liveAssets.firstWhere((a) => a.id == position.assetId);
          final currentPrice = (asset.currentPrice as double);

          bool shouldClose = false;
          if (position.isLong) {
            if (position.stopLoss != null &&
                currentPrice <= position.stopLoss!) {
              shouldClose = true;
            }
            if (position.takeProfit != null &&
                currentPrice >= position.takeProfit!) {
              shouldClose = true;
            }
          } else {
            if (position.stopLoss != null &&
                currentPrice >= position.stopLoss!) {
              shouldClose = true;
            }
            if (position.takeProfit != null &&
                currentPrice <= position.takeProfit!) {
              shouldClose = true;
            }
          }

          if (shouldClose &&
              portfolioNotifier.getPositionById(position.id) != null) {
            final pnl = position.realizedPnl(currentPrice);
            ref.read(refineryProvider.notifier).addFuel(position.totalCost + pnl);
            final stats = ref.read(refineryProvider).valueOrNull;
            // closePosition is async — fire and forget (the Future will run
            // independently; Supabase ops are best-effort in the watcher).
            portfolioNotifier.closePosition(
              position.id,
              currentPrice,
              balanceAfter: stats?.refinedFuel ?? 0.0,
            );
          }
        } catch (_) {
          // Position asset not in the live list — skip
        }
      }
    },
  );
});
