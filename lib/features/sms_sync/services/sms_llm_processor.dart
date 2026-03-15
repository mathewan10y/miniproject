import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Represents a single parsed financial transaction from an SMS message.
class ParsedTransaction {
  final String type; // 'expense' | 'income'
  final double amount;
  final String category;
  final bool isWant; // only meaningful for expenses

  ParsedTransaction({
    required this.type,
    required this.amount,
    required this.category,
    required this.isWant,
  });

  factory ParsedTransaction.fromJson(Map<String, dynamic> json) {
    return ParsedTransaction(
      type: (json['type'] as String? ?? 'ignore').toLowerCase(),
      amount: (json['amount'] as num? ?? 0.0).toDouble(),
      category: json['category'] as String? ?? 'Other',
      isWant: json['isWant'] as bool? ?? false,
    );
  }
}

/// Uses Gemini to parse raw SMS bodies into typed financial transactions.
class SmsLlmProcessor {
  static final SmsLlmProcessor _instance = SmsLlmProcessor._internal();
  factory SmsLlmProcessor() => _instance;
  SmsLlmProcessor._internal();

  // Batch size — send up to N messages per Gemini call to stay within limits
  static const int _batchSize = 20;

  // ── Local pre-filter regex lists ──────────────────────────────────────────

  static final List<RegExp> _otpPatterns = [
    RegExp(
      r'\b\d{4,6}\b\s*(?:is|are|hai)\s*(?:your|the|apka|apki)\s*(?:otp|one time password|code|pin|verification code|security code)',
      caseSensitive: false,
    ),
    RegExp(
      r'^(?:otp|code|pin|verification)\s*(?:is|:|hai)\s*\d{4,6}\b',
      caseSensitive: false,
    ),
    RegExp(
      r'\buse\s*\d{4,6}\s*to\s*(?:verify|confirm|authenticate|authorize|validate|complete)',
      caseSensitive: false,
    ),
  ];

  static final List<RegExp> _promotionalPatterns = [
    RegExp(r'congratulations.*you.*won', caseSensitive: false),
    RegExp(r'pre-approved.*loan.*apply.*now', caseSensitive: false),
    RegExp(r'limited.*time.*offer', caseSensitive: false),
    RegExp(r'discount|coupon|deal|sale|offer', caseSensitive: false),
    RegExp(r'click here|visit us|know more|apply now', caseSensitive: false),
  ];

  static final List<RegExp> _transactionIndicators = [
    RegExp(
      r'debited|debit|withdrawn|purchase|spent|paid|charged|deducted',
      caseSensitive: false,
    ),
    RegExp(
      r'credited|credit|received|deposit|salary|refund|transfer',
      caseSensitive: false,
    ),
    RegExp(r'(?:INR|Rs\.?|₹)\s*\d+', caseSensitive: false),
  ];

  /// Returns true only if [message] looks like a financial transaction.
  /// OTPs and promotional messages are rejected first.
  bool _isLikelyTransaction(String message) {
    if (_otpPatterns.any((re) => re.hasMatch(message))) return false;
    if (_promotionalPatterns.any((re) => re.hasMatch(message))) return false;
    if (_transactionIndicators.any((re) => re.hasMatch(message))) return true;
    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────

  static const String _systemPrompt = '''
You are a financial SMS parser for Indian banking messages. 
Analyze the following list of SMS messages and classify each one.

Return ONLY a valid JSON array — no markdown fences, no commentary.
Each element must follow this exact schema:
{
  "type": "expense" | "income" | "ignore",
  "amount": <number>,
  "category": "<string>",
  "isWant": <true|false>
}

Rules:
- "type" = "income" if money was CREDITED to the user's account (salary, refund, cashback, etc.)
- "type" = "expense" if money was DEBITED / spent / paid.
- "type" = "ignore" if the SMS is not a financial transaction (OTP, promotional, etc.)
- "amount" = the numeric rupee value (no currency symbol). If not parseable, use 0.
- "category" = one of: Food, Transport, Shopping, Entertainment, Utilities, Medical, 
                         Groceries, Salary, Freelance, Investment, Refund, Other
- "isWant" = true if the expense is a discretionary / lifestyle purchase (e.g. dining out, 
             shopping, streaming). false if it is a need (rent, medicine, utilities, groceries).
- For income entries, "isWant" must always be false.

The input messages are:
''';

  /// Processes a list of raw SMS bodies through Gemini and returns only
  /// actionable (non-"ignore") transactions.
  Future<List<ParsedTransaction>> process(List<String> messages) async {
    if (messages.isEmpty) return [];

    final model = await _buildModel();
    if (model == null) return [];

    // ── Task 1: local pre-filter — drop OTPs, promos, non-financial SMS ──
    final filtered = messages.where(_isLikelyTransaction).toList();
    if (filtered.isEmpty) return [];

    final List<ParsedTransaction> results = [];

    // Process in batches to avoid token limits
    final batches = <List<String>>[];
    for (int i = 0; i < filtered.length; i += _batchSize) {
      batches.add(filtered.sublist(
        i,
        i + _batchSize > filtered.length ? filtered.length : i + _batchSize,
      ));
    }

    for (int b = 0; b < batches.length; b++) {
      final batchResults = await _processBatch(model, batches[b]);
      results.addAll(batchResults);

      // ── Task 2: rate-limit guard — 1 s delay between batches ──
      if (b < batches.length - 1) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }

    return results;
  }

  Future<GenerativeModel?> _buildModel() async {
    try {
      await dotenv.load(fileName: '.env');
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) return null;

      return GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          // JSON structured output — low temperature for consistency
          temperature: 0.1,
          maxOutputTokens: 2048,
          responseMimeType: 'application/json',
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<ParsedTransaction>> _processBatch(
    GenerativeModel model,
    List<String> batch,
  ) async {
    // Number each message to help Gemini maintain order
    final numbered = batch
        .asMap()
        .entries
        .map((e) => '${e.key + 1}. "${e.value}"')
        .join('\n');

    final prompt = '$_systemPrompt\n$numbered';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final raw = response.text ?? '';
      if (raw.trim().isEmpty) return [];

      // Strip any accidental markdown fences
      final cleaned =
          raw
              .replaceAll(RegExp(r'```json', caseSensitive: false), '')
              .replaceAll('```', '')
              .trim();

      final decoded = jsonDecode(cleaned);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ParsedTransaction.fromJson)
          .where((t) => t.type != 'ignore' && t.amount > 0)
          .toList();
    } catch (e) {
      // On any parse error, return empty for this batch
      return [];
    }
  }
}
