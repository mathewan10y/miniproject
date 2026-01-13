enum AssetType {
  lifeSupport, // Low Risk (Commodities/Forex) - "Sector A"
  thruster,    // Medium Risk (Stocks) - "Sector B"
  fleet,       // Indices/ETFs - "Sector B"
  warpDrive,   // High Risk (Crypto) - "Sector C"
  derivatives, // Placeholder (Options/Futures)
}

enum AssetSubType {
  bond,
  economy,
  fund,
  forex,
  stock,
  marketIndex, // Renamed from 'index' to avoid conflict with Enum.index
  crypto,
  future,
  option,
  none, // Default fallback
}

class MarketAsset {
  final String id;
  final String symbol;
  final String name;
  final double currentPrice;
  final double percentChange24h;
  final AssetType type;
  final AssetSubType subType;
  final int minLevelRequired;

  MarketAsset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.percentChange24h,
    required this.type,
    required this.subType,
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
      subType: AssetSubType.crypto, // API returns crypto
      minLevelRequired: 1, 
    );
  }
}
