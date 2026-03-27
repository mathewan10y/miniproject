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

  Map<String, dynamic> toJson() => {
    'id': id,
    'asset_id': assetId,
    'asset_symbol': assetSymbol,
    'asset_name': assetName,
    'entry_price': entryPrice,
    'exit_price': exitPrice,
    'quantity': quantity,
    'is_long': isLong,
    'realized_pnl': realizedPnl,
    'opened_at': openedAt.toIso8601String(),
    'closed_at': closedAt.toIso8601String(),
  };

  factory TradeHistoryItem.fromJson(Map<String, dynamic> json) =>
      TradeHistoryItem(
        id: json['id'] as String,
        assetId: json['asset_id'] as String,
        assetSymbol: json['asset_symbol'] as String,
        assetName: json['asset_name'] as String,
        entryPrice: (json['entry_price'] as num).toDouble(),
        exitPrice: (json['exit_price'] as num).toDouble(),
        quantity: (json['quantity'] as num).toDouble(),
        isLong: json['is_long'] as bool,
        realizedPnl: (json['realized_pnl'] as num).toDouble(),
        openedAt: DateTime.parse(json['opened_at'] as String),
        closedAt: DateTime.parse(json['closed_at'] as String),
      );
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
