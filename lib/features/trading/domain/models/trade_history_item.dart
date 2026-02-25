class TradeHistoryItem {
  final String id;
  final String assetId;
  final String assetSymbol;
  final String assetName;
  final double entryPrice;
  final double exitPrice;
  final double quantity;
  final bool isLong;
  final double realizedPnl;
  final DateTime openedAt;
  final DateTime closedAt;

  const TradeHistoryItem({
    required this.id,
    required this.assetId,
    required this.assetSymbol,
    required this.assetName,
    required this.entryPrice,
    required this.exitPrice,
    required this.quantity,
    required this.isLong,
    required this.realizedPnl,
    required this.openedAt,
    required this.closedAt,
  });
}

/// Tracks a change in fuel balance for the Balance History tab.
class BalanceEvent {
  final DateTime timestamp;
  final double balanceAfter;
  final double delta; // +/- change
  final String description; // e.g. "Opened LONG AAPL", "Closed BTC +₹500"

  const BalanceEvent({
    required this.timestamp,
    required this.balanceAfter,
    required this.delta,
    required this.description,
  });
}
