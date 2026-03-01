import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

// Only import dart:io on non-web builds to avoid web compilation errors
import 'sms_fetch_service_io.dart'
    if (dart.library.html) 'sms_fetch_service_web.dart'
    as platform_check;

/// Describes every possible outcome of [SmsFetchService.fetchTransactionalSms].
enum SmsFetchStatus {
  /// Platform is a browser — SMS is architecturally impossible.
  unsupportedWeb,

  /// Platform is iOS — Apple does not allow third-party SMS access.
  unsupportedIos,

  /// User denied the SMS permission dialog.
  permissionDenied,

  /// Permission granted, inbox queried, but no financial SMS were found.
  noMessagesFound,

  /// One or more transactional SMS messages were successfully fetched.
  success,

  /// An unexpected runtime error occurred.
  error,
}

/// Typed result returned by [SmsFetchService.fetchTransactionalSms].
class SmsFetchResult {
  final SmsFetchStatus status;
  final List<String> messages;
  final String? errorMessage;

  const SmsFetchResult({
    required this.status,
    this.messages = const [],
    this.errorMessage,
  });
}

/// Handles SMS permission requests and fetches transactional messages.
class SmsFetchService {
  static final SmsFetchService _instance = SmsFetchService._internal();
  factory SmsFetchService() => _instance;
  SmsFetchService._internal();

  static const List<String> _transactionKeywords = [
    '₹',
    'INR',
    'credited',
    'debited',
    'credit',
    'debit',
    'paid',
    'received',
    'transferred',
    'payment',
    'transaction',
    'withdrawn',
    'deposited',
    'rs.',
    'rs ',
    'amount',
    'balance',
    'a/c',
    'acct',
    'upi',
    'neft',
    'imps',
    'rtgs',
  ];

  /// Fetches transactional SMS messages and returns a typed [SmsFetchResult].
  /// Always safe to call — handles web, iOS, permission denial, and errors
  /// gracefully without throwing.
  Future<SmsFetchResult> fetchTransactionalSms() async {
    // ── 1. Web guard (must come first — dart:io Platform is unsafe on web) ──
    if (kIsWeb) {
      return const SmsFetchResult(status: SmsFetchStatus.unsupportedWeb);
    }

    // ── 2. Platform guard ────────────────────────────────────────────────────
    final isAndroid = platform_check.isAndroid();
    final isIos = platform_check.isIos();

    if (isIos) {
      return const SmsFetchResult(status: SmsFetchStatus.unsupportedIos);
    }

    if (!isAndroid) {
      // Desktop (Windows, macOS, Linux) treated same as unsupported
      return const SmsFetchResult(status: SmsFetchStatus.unsupportedWeb);
    }

    // ── 3. Permission request ────────────────────────────────────────────────
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      return const SmsFetchResult(status: SmsFetchStatus.permissionDenied);
    }

    // ── 4. Read SMS inbox ────────────────────────────────────────────────────
    try {
      final SmsQuery query = SmsQuery();
      final List<SmsMessage> allMessages = await query.getAllSms;

      final cutoff = DateTime.now().subtract(const Duration(days: 30));

      final List<String> transactional = [];
      for (final msg in allMessages) {
        final date = msg.date;
        if (date == null || date.isBefore(cutoff)) continue;
        final body = msg.body ?? '';
        if (_isTransactional(body)) transactional.add(body);
      }

      if (transactional.isEmpty) {
        return const SmsFetchResult(status: SmsFetchStatus.noMessagesFound);
      }

      return SmsFetchResult(
        status: SmsFetchStatus.success,
        messages: transactional,
      );
    } catch (e) {
      return SmsFetchResult(
        status: SmsFetchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  bool _isTransactional(String body) {
    final lower = body.toLowerCase();
    return _transactionKeywords.any((kw) => lower.contains(kw.toLowerCase()));
  }
}
