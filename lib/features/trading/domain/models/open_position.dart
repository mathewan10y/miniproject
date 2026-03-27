class OpenPosition {
  final String id; // Unique position identifier
  final String assetId;
  final String assetSymbol;
  final String assetName;
  final double entryPrice; // Price in INR (already converted at buy time)
  final double quantity;
  final bool isLong; // true = BUY, false = SHORT
  final DateTime openedAt;
  final double? stopLoss;
  final double? takeProfit;

  OpenPosition({
    String? id,
    required this.assetId,
    required this.assetSymbol,
    required this.assetName,
    required this.entryPrice,
    required this.quantity,
    required this.isLong,
    required this.openedAt,
    this.stopLoss,
    this.takeProfit,
  }) : id = id ?? '${assetId}_${openedAt.microsecondsSinceEpoch}';

  /// Total capital locked (INR)
  double get totalCost => entryPrice * quantity;

  /// Live unrealized P&L against the current market price (INR)
  double unrealizedPnl(double currentPriceInr) {
    return (currentPriceInr - entryPrice) * (isLong ? 1 : -1) * quantity;
  }

  /// Realized P&L when closing at [closePriceInr]
  double realizedPnl(double closePriceInr) {
    return (closePriceInr - entryPrice) * (isLong ? 1 : -1) * quantity;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'asset_id': assetId,
    'asset_symbol': assetSymbol,
    'asset_name': assetName,
    'entry_price': entryPrice,
    'quantity': quantity,
    'is_long': isLong,
    'stop_loss': stopLoss,
    'take_profit': takeProfit,
    'opened_at': openedAt.toIso8601String(),
  };

  factory OpenPosition.fromJson(Map<String, dynamic> json) => OpenPosition(
    id: json['id'] as String,
    assetId: json['asset_id'] as String,
    assetSymbol: json['asset_symbol'] as String,
    assetName: json['asset_name'] as String,
    entryPrice: (json['entry_price'] as num).toDouble(),
    quantity: (json['quantity'] as num).toDouble(),
    isLong: json['is_long'] as bool,
    openedAt: DateTime.parse(json['opened_at'] as String),
    stopLoss: json['stop_loss'] != null
        ? (json['stop_loss'] as num).toDouble()
        : null,
    takeProfit: json['take_profit'] != null
        ? (json['take_profit'] as num).toDouble()
        : null,
  );
}
