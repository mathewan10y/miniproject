import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/ledger/expense_provider.dart';
import '../../../features/ledger/income_provider.dart';
import '../services/sms_fetch_service.dart';
import '../services/sms_llm_processor.dart';
import '../../../core/services/audio_service.dart';

/// A fully self-contained, drop-in button that:
/// 1. Guards platform support (web, iOS, desktop) — shows a Snackbar if unsupported
/// 2. Requests SMS permission — shows a Snackbar if denied
/// 3. Fetches transactional SMS messages from the last 30 days
/// 4. Sends them to Gemini for classification
/// 5. Saves results directly into [expenseProvider] / [incomeProvider]
/// 6. Shows a Snackbar for every possible outcome
///
/// Usage — just drop it anywhere inside a ProviderScope:
/// ```dart
/// const SmsSyncButton()
/// ```
class SmsSyncButton extends ConsumerStatefulWidget {
  /// When [compact] is true (default), renders as a small [IconButton] with
  /// a tooltip — ideal for tight spaces like the TopBar on narrow phones.
  /// Set to false to render the full [ElevatedButton] with a text label.
  final bool compact;

  const SmsSyncButton({super.key, this.compact = true});

  @override
  ConsumerState<SmsSyncButton> createState() => _SmsSyncButtonState();
}

class _SmsSyncButtonState extends ConsumerState<SmsSyncButton> {
  bool _isLoading = false;

  Future<void> _onTap() async {
    ref.read(audioServiceProvider).playSound('buttontap.ogg');
    setState(() => _isLoading = true);

    try {
      // ── Step 1: Fetch SMS (typed result handles all platform cases) ────────
      final fetchResult = await SmsFetchService().fetchTransactionalSms();

      switch (fetchResult.status) {
        case SmsFetchStatus.unsupportedWeb:
          _showSnackbar(
            '🌐 SMS sync is not available in the browser.\n'
            'Please use the Android app to sync transactions.',
            isError: true,
            icon: Icons.web_asset_off_outlined,
          );
          return;

        case SmsFetchStatus.unsupportedIos:
          _showSnackbar(
            '🍎 SMS sync is not supported on iOS.\n'
            'Apple restricts third-party SMS access for security.',
            isError: true,
            icon: Icons.phone_iphone_outlined,
          );
          return;

        case SmsFetchStatus.permissionDenied:
          _showSnackbar(
            '🔒 SMS permission was denied.\n'
            'Go to Settings → Apps → Stardust → Permissions to enable it.',
            isError: true,
            icon: Icons.lock_outline,
          );
          return;

        case SmsFetchStatus.noMessagesFound:
          _showSnackbar(
            'No banking SMS found in the last 30 days.\n'
            'Make sure you have financial messages in your inbox.',
            isError: false,
            icon: Icons.inbox_outlined,
          );
          return;

        case SmsFetchStatus.error:
          _showSnackbar(
            '⚠ SMS read error: ${fetchResult.errorMessage ?? "unknown error"}',
            isError: true,
            icon: Icons.error_outline,
          );
          return;

        case SmsFetchStatus.success:
          break; // continue below
      }

      // ── Step 2: LLM Processing ─────────────────────────────────────────────
      final transactions = await SmsLlmProcessor().process(
        fetchResult.messages,
      );

      if (transactions.isEmpty) {
        _showSnackbar(
          '🤖 Gemini could not identify any transactions in your SMS.\n'
          'The messages may not contain clear financial data.',
          isError: false,
          icon: Icons.auto_awesome_outlined,
        );
        return;
      }

      // ── Step 3: Save to ledger ─────────────────────────────────────────────
      int expenseCount = 0;
      int incomeCount = 0;

      for (final txn in transactions) {
        if (txn.type == 'expense' && txn.amount > 0) {
          await ref
              .read(expenseProvider.notifier)
              .addExpense(txn.amount, txn.category, txn.isWant);
          expenseCount++;
        } else if (txn.type == 'income' && txn.amount > 0) {
          await ref
              .read(incomeProvider.notifier)
              .addIncome(txn.amount, txn.category);
          incomeCount++;
        }
      }

      // ── Step 4: Detailed success Snackbar ──────────────────────────────────
      final total = expenseCount + incomeCount;
      if (total == 0) {
        _showSnackbar(
          'Sync complete, but no valid amounts were found.',
          isError: false,
          icon: Icons.check_circle_outline,
        );
      } else {
        final parts = <String>[];
        if (expenseCount > 0) {
          parts.add('$expenseCount expense${expenseCount == 1 ? '' : 's'}');
        }
        if (incomeCount > 0) {
          parts.add('$incomeCount income${incomeCount == 1 ? '' : 's'}');
        }
        _showSnackbar(
          '✓ Synced ${parts.join(' & ')} from SMS',
          isError: false,
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      _showSnackbar(
        '⚠ Unexpected error during sync: $e',
        isError: true,
        icon: Icons.error_outline,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {required bool isError, IconData? icon}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError
                ? const Color(0xFFB00020) // deep red for errors
                : const Color(0xFF2E7D32), // deep green for success/info
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 6 : 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      // ── Compact mode: icon-only, fits in tight spaces like the TopBar ──────
      return Tooltip(
        message: 'Sync from SMS',
        child: IconButton(
          onPressed: _isLoading ? null : _onTap,
          icon:
              _isLoading
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.sms_outlined, size: 22),
          color: const Color(0xFF00D9FF), // cyan — matches app theme
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF00D9FF).withOpacity(0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: const Color(0xFF00D9FF).withOpacity(0.4)),
            ),
          ),
        ),
      );
    }

    // ── Full mode: labeled ElevatedButton ────────────────────────────────────
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon:
          _isLoading
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.sms_outlined, size: 18),
      label: Text(
        _isLoading ? 'Scanning…' : 'Sync SMS',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}
