import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// ─── Data Models ─────────────────────────────────────────────────────────────

class StockMetrics {
  final String symbol;
  final double revenueGrowth; // % YoY
  final double netProfitMargin; // %
  final double eps; // Earnings Per Share
  final double fcf; // Free Cash Flow (in billions)
  final double peRatio; // Price to Earnings
  final double pegRatio; // PEG Ratio
  final double roe; // Return on Equity %
  final double debtToEquity; // Ratio
  final double currentRatio; // Ratio
  final double evToEbitda; // EV/EBITDA

  const StockMetrics({
    required this.symbol,
    required this.revenueGrowth,
    required this.netProfitMargin,
    required this.eps,
    required this.fcf,
    required this.peRatio,
    required this.pegRatio,
    required this.roe,
    required this.debtToEquity,
    required this.currentRatio,
    required this.evToEbitda,
  });
}

class StockAnalysisResult {
  final List<String> strengths;
  final List<String> weaknesses;
  final String summary;
  final String rating; // "Bullish" | "Neutral" | "Bearish"
  final int score; // 0–10

  const StockAnalysisResult({
    required this.strengths,
    required this.weaknesses,
    required this.summary,
    required this.rating,
    required this.score,
  });

  factory StockAnalysisResult.fromJson(Map<String, dynamic> json) {
    return StockAnalysisResult(
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      summary: json['summary'] as String? ?? '',
      rating: json['rating'] as String? ?? 'Neutral',
      score: (json['score'] as num?)?.toInt() ?? 5,
    );
  }
}

// ─── Placeholder Metrics per Symbol ──────────────────────────────────────────

const Map<String, StockMetrics> _metricsBySymbol = {
  'AAPL': StockMetrics(
    symbol: 'AAPL',
    revenueGrowth: 8.1,
    netProfitMargin: 25.3,
    eps: 6.44,
    fcf: 99.6,
    peRatio: 28.5,
    pegRatio: 2.1,
    roe: 147.9,
    debtToEquity: 1.55,
    currentRatio: 0.99,
    evToEbitda: 21.4,
  ),
  'RELIANCE': StockMetrics(
    symbol: 'RELIANCE',
    revenueGrowth: 11.3,
    netProfitMargin: 6.8,
    eps: 99.5,
    fcf: 2.1,
    peRatio: 22.4,
    pegRatio: 1.9,
    roe: 12.3,
    debtToEquity: 0.42,
    currentRatio: 1.31,
    evToEbitda: 15.2,
  ),
  'BTC': StockMetrics(
    symbol: 'BTC',
    revenueGrowth: 120.0,
    netProfitMargin: 0.0,
    eps: 0.0,
    fcf: 0.0,
    peRatio: 0.0,
    pegRatio: 0.0,
    roe: 0.0,
    debtToEquity: 0.0,
    currentRatio: 0.0,
    evToEbitda: 0.0,
  ),
  'ETH': StockMetrics(
    symbol: 'ETH',
    revenueGrowth: 85.0,
    netProfitMargin: 0.0,
    eps: 0.0,
    fcf: 0.0,
    peRatio: 0.0,
    pegRatio: 0.0,
    roe: 0.0,
    debtToEquity: 0.0,
    currentRatio: 0.0,
    evToEbitda: 0.0,
  ),
  'SPX': StockMetrics(
    symbol: 'SPX',
    revenueGrowth: 6.2,
    netProfitMargin: 11.5,
    eps: 215.7,
    fcf: 1500.0,
    peRatio: 22.1,
    pegRatio: 1.8,
    roe: 19.4,
    debtToEquity: 0.95,
    currentRatio: 1.20,
    evToEbitda: 14.8,
  ),
  'NDX': StockMetrics(
    symbol: 'NDX',
    revenueGrowth: 9.4,
    netProfitMargin: 17.3,
    eps: 610.2,
    fcf: 5200.0,
    peRatio: 30.2,
    pegRatio: 2.3,
    roe: 28.7,
    debtToEquity: 0.78,
    currentRatio: 1.40,
    evToEbitda: 20.1,
  ),
};

/// Returns best-effort placeholder metrics for any symbol.
StockMetrics _getMetrics(String symbol) {
  if (_metricsBySymbol.containsKey(symbol)) return _metricsBySymbol[symbol]!;

  // Generic fallback for unknown symbols (crypto, commodities, forex)
  return StockMetrics(
    symbol: symbol,
    revenueGrowth: 12.0,
    netProfitMargin: 8.5,
    eps: 3.20,
    fcf: 1.5,
    peRatio: 18.0,
    pegRatio: 1.5,
    roe: 14.0,
    debtToEquity: 0.60,
    currentRatio: 1.50,
    evToEbitda: 12.0,
  );
}

// ─── Service ─────────────────────────────────────────────────────────────────

class StockAnalysisService {
  Future<StockAnalysisResult> analyze(String symbol) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) throw Exception('GEMINI_API_KEY not found in .env');

    final metrics = _getMetrics(symbol);

    final prompt = '''
You are a professional equity research analyst.

Analyze the following stock/asset fundamentals for ${metrics.symbol}:

Revenue Growth (YoY): ${metrics.revenueGrowth}%
Net Profit Margin: ${metrics.netProfitMargin}%
Earnings Per Share (EPS): ${metrics.eps}
Free Cash Flow (FCF, billions): ${metrics.fcf}
Price to Earnings Ratio (P/E): ${metrics.peRatio}
PEG Ratio: ${metrics.pegRatio}
Return on Equity (ROE): ${metrics.roe}%
Debt to Equity Ratio: ${metrics.debtToEquity}
Current Ratio: ${metrics.currentRatio}
EV/EBITDA: ${metrics.evToEbitda}

Provide a professional fundamental analysis. For crypto or index assets where some metrics are zero or not applicable, analyse based on available metrics and market context.

Return the output STRICTLY in JSON format with no markdown, no code fences, no explanation — only the raw JSON object:

{
  "strengths": ["point 1", "point 2", "point 3"],
  "weaknesses": ["point 1", "point 2"],
  "summary": "2-3 sentence professional summary",
  "rating": "Bullish",
  "score": 7
}

The "rating" field must be exactly one of: "Bullish", "Neutral", or "Bearish".
The "score" field must be an integer from 0 to 10.
''';

    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 1024,
        responseMimeType: "application/json",
      ),
    );

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '';

    print('[GeminiRaw] $text');

    // Strip markdown code fences if Gemini sneaks them in
    String cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned =
          cleaned
              .replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '')
              .replaceFirst(RegExp(r'```\s*$'), '')
              .trim();
    }

    print('[GeminiCleaned] $cleaned');

    final Map<String, dynamic> json = jsonDecode(cleaned);
    return StockAnalysisResult.fromJson(json);
  }
}
