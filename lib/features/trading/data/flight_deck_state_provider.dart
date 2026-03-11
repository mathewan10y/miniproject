import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/market_asset.dart';
import '../data/market_service.dart';

// ─── State Model ─────────────────────────────────────────────────────────────

/// Holds the currently displayed chart data so it survives navigation.
class FlightDeckChartState {
  final MarketAsset? selectedAsset;
  final List<MockCandle> candles;
  final String selectedInterval;

  const FlightDeckChartState({
    this.selectedAsset,
    this.candles = const [],
    this.selectedInterval = '1H',
  });

  bool get hasData => selectedAsset != null && candles.isNotEmpty;

  FlightDeckChartState copyWith({
    MarketAsset? selectedAsset,
    List<MockCandle>? candles,
    String? selectedInterval,
  }) {
    return FlightDeckChartState(
      selectedAsset: selectedAsset ?? this.selectedAsset,
      candles: candles ?? this.candles,
      selectedInterval: selectedInterval ?? this.selectedInterval,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class FlightDeckChartNotifier extends Notifier<FlightDeckChartState> {
  @override
  FlightDeckChartState build() => const FlightDeckChartState();

  void saveChartData({
    required MarketAsset asset,
    required List<MockCandle> candles,
    required String interval,
  }) {
    state = FlightDeckChartState(
      selectedAsset: asset,
      candles: candles,
      selectedInterval: interval,
    );
  }

  void clearChart() {
    state = const FlightDeckChartState();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final flightDeckChartProvider =
    NotifierProvider<FlightDeckChartNotifier, FlightDeckChartState>(
      FlightDeckChartNotifier.new,
    );
