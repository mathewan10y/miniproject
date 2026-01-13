enum AssetType {
  lifeSupport, // Low Risk (Commodities/Forex) - "Sector A"
  thruster,    // Medium Risk (Stocks) - "Sector B"
  fleet,       // Indices/ETFs - "Sector B"
  warpDrive,   // High Risk (Crypto) - "Sector C"
  derivatives, // Placeholder (Options/Futures)
}

class MarketAsset {
  final String id;
  final String symbol;
  final String name;
  final double currentPrice;
  final double percentChange24h;
  final AssetType type;
  final int minLevelRequired;

  MarketAsset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.percentChange24h,
    required this.type,
    required this.minLevelRequired,
  });

  bool isLocked(int userLevel) {
    // User requested to disable locking for testing
    return false; 
    // Original logic: return userLevel < minLevelRequired;
  }

  factory MarketAsset.fromJson(Map<String, dynamic> json) {
    return MarketAsset(
      id: json['id'] ?? '',
      symbol: (json['symbol'] ?? '').toString().toUpperCase(),
      name: json['name'] ?? '',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      percentChange24h: (json['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
      type: AssetType.warpDrive, // Default to High Risk for Crypto API
      minLevelRequired: 1, 
    );
  }
}
