import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../domain/models/market_asset.dart';

// Provider definition
final marketServiceProvider = Provider<MarketRepository>((ref) {
  return MixedMarketService();
});

// FutureProvider for fetching assets
final marketAssetsProvider = FutureProvider<List<MarketAsset>>((ref) async {
  final service = ref.watch(marketServiceProvider);
  return service.fetchAssets();
});

abstract class MarketRepository {
  Future<List<MarketAsset>> fetchAssets();
  Future<List<MockCandle>> getAssetHistory(String assetId, String interval);
}

class MixedMarketService implements MarketRepository {
  final http.Client _client = http.Client();

  // CoinGecko API for Crypto
  final String _cryptoApiUrl = 
      'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=bitcoin,ethereum,dogecoin&order=market_cap_desc&per_page=10&page=1&sparkline=false';

  @override
  Future<List<MarketAsset>> fetchAssets() async {
    List<MarketAsset> assets = [];

    // 1. Fetch Crypto (API)
    try {
      final response = await _client.get(Uri.parse(_cryptoApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        assets.addAll(data.map((json) {
          final asset = MarketAsset.fromJson(json);
          // Customize levels for Crypto
          int level = 1;
          if (asset.symbol.toUpperCase() == 'BTC') level = 5; // Bitcoin is high level
          if (asset.symbol.toUpperCase() == 'ETH') level = 3;
          if (asset.symbol.toUpperCase() == 'DOGE') level = 1;

          return MarketAsset(
            id: asset.id,
            symbol: asset.symbol.toUpperCase(),
            name: asset.name,
            currentPrice: asset.currentPrice,
            percentChange24h: asset.percentChange24h,
            type: AssetType.warpDrive, // Crypto is Warp Drive (High Risk)
            minLevelRequired: level,
          );
        }));
      } else {
        // Fallback mock if API fails
        assets.addAll(_getMockSectorC());
      }
    } catch (e) {
      // Fallback mock if network error
      assets.addAll(_getMockSectorC());
    }

    // 2. Add Sector B (Stocks -> Thrusters + Fleets)
    assets.addAll(_getMockSectorB_Thrusters());
    assets.addAll(_getMockSectorB_Fleets());

    // 3. Add Sector A (Commodities/Forex -> Life Support)
    assets.add(_getMockSectorA('gold', 'Gold', 2030.50, 2));
    assets.add(_getMockSectorA('oil', 'Crude Oil', 78.40, 2));
    assets.add(_getMockSectorA('usdinr', 'USD/INR', 83.12, 1));

    return assets;
  }

  @override
  Future<List<MockCandle>> getAssetHistory(String assetId, String interval) async {
    // ... (keep existing implementation) ...
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Generate realistic-looking random walk data
    final List<MockCandle> candles = [];
    final now = DateTime.now();
    
    // Base price depends on asset (rough hack for demo)
    double price = 100.0;
    if (assetId == 'bitcoin') price = 42000.0;
    if (assetId == 'ethereum') price = 2200.0;
    if (assetId == 'dogecoin') price = 0.15;
    if (assetId == 'aapl') price = 185.0;
    
    // Determine number of points and interval duration
    int points = 100;
    Duration step = const Duration(hours: 1);
    if (interval == '1D') step = const Duration(days: 1);
    if (interval == '1W') step = const Duration(days: 7);
    if (interval == '4H') step = const Duration(hours: 4);
    
    DateTime currentStr = now.subtract(step * points);
    
    final random = Random();
    
    for (int i = 0; i < points; i++) {
        // Random usage to generate O H L C
        double volatility = price * 0.02; // 2% volatility
        double change = (random.nextDouble() - 0.5) * volatility;
        
        double open = price;
        double close = price + change;
        double high = max(open, close) + random.nextDouble() * volatility * 0.5;
        double low = min(open, close) - random.nextDouble() * volatility * 0.5;
        
        candles.add(MockCandle(
          open: open, 
          high: high, 
          low: low, 
          close: close, 
          volume: 1000 + random.nextDouble() * 5000, 
          timestamp: currentStr.millisecondsSinceEpoch,
        ));
        
        price = close; // Next candle starts at this close
        currentStr = currentStr.add(step);
    }
    
    return candles;
  }

  // --- Mock Generators ---

  List<MarketAsset> _getMockSectorC() {
    return [
      MarketAsset(id: 'bitcoin', symbol: 'BTC', name: 'Bitcoin', currentPrice: 42000.0, percentChange24h: 2.5, type: AssetType.warpDrive, minLevelRequired: 5),
      MarketAsset(id: 'ethereum', symbol: 'ETH', name: 'Ethereum', currentPrice: 2200.0, percentChange24h: -1.2, type: AssetType.warpDrive, minLevelRequired: 3),
      MarketAsset(id: 'dogecoin', symbol: 'DOGE', name: 'Dogecoin', currentPrice: 0.15, percentChange24h: 5.0, type: AssetType.warpDrive, minLevelRequired: 1),
    ];
  }

  List<MarketAsset> _getMockSectorB_Fleets() {
    return [
      MarketAsset(
        id: 'sp500', 
        symbol: 'SPX', 
        name: 'S&P 500 Fleet', 
        currentPrice: 4800.0, 
        percentChange24h: 0.5, 
        type: AssetType.fleet, 
        minLevelRequired: 4
      ),
      MarketAsset(
        id: 'nasdaq', 
        symbol: 'NDX', 
        name: 'NASDAQ Fleet', 
        currentPrice: 16800.0, 
        percentChange24h: 0.8, 
        type: AssetType.fleet, 
        minLevelRequired: 4
      ),
    ];
  }

  List<MarketAsset> _getMockSectorB_Thrusters() {
    final random = Random();
    // Simulate volatility: -2% to +2% change roughly
    double AAPL_Price = 185.0 + (random.nextDouble() - 0.5) * 5; 
    double RELIANCE_Price = 2500.0 + (random.nextDouble() - 0.5) * 50;

    return [
      MarketAsset(
        id: 'aapl', 
        symbol: 'AAPL', 
        name: 'Apple Inc.', 
        currentPrice: AAPL_Price, 
        percentChange24h: (random.nextDouble() - 0.5) * 3.0, 
        type: AssetType.thruster, 
        minLevelRequired: 3
      ),
      MarketAsset(
        id: 'reliance', 
        symbol: 'RELIANCE', 
        name: 'Reliance Ind.', 
        currentPrice: RELIANCE_Price, 
        percentChange24h: (random.nextDouble() - 0.5) * 4.0, 
        type: AssetType.thruster, 
        minLevelRequired: 3
      ),
    ];
  }

  MarketAsset _getMockSectorA(String id, String name, double basePrice, int level) {
    final random = Random();
    double price = basePrice + (random.nextDouble() - 0.5) * (basePrice * 0.01); // 1% volatility
    return MarketAsset(
      id: id,
      symbol: name.toUpperCase(),
      name: name,
      currentPrice: price,
      percentChange24h: (random.nextDouble() - 0.5) * 1.5,
      type: AssetType.lifeSupport,
      minLevelRequired: level,
    );
  }
}

class MockCandle {
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final int timestamp;

  MockCandle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.timestamp,
  });
}
