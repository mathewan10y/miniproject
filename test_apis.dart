import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  // Test CoinGecko
  try {
    final r1 = await http.get(
      Uri.parse('https://api.coingecko.com/api/v3/ping'),
    ).timeout(const Duration(seconds: 8));
    print('CoinGecko: ${r1.statusCode} — ${r1.body.substring(0, r1.body.length.clamp(0, 80))}');
  } catch (e) {
    print('CoinGecko ERROR: $e');
  }

  // Test Yahoo Finance
  try {
    final r2 = await http.get(
      Uri.parse('https://query1.finance.yahoo.com/v7/finance/quote?symbols=AAPL'),
      headers: {'User-Agent': 'Mozilla/5.0', 'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 8));
    print('Yahoo: ${r2.statusCode} — ${r2.body.substring(0, r2.body.length.clamp(0, 80))}');
  } catch (e) {
    print('Yahoo ERROR: $e');
  }

  exit(0);
}
