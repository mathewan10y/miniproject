import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stardust/core/providers/refinery_provider.dart';
import '../providers/bot_chat_provider.dart';

class TopBar extends ConsumerWidget {
  final String title;
  final VoidCallback? onVarsityToggle;

  /// Optional widget rendered on the right side of the TopBar, before the
  /// fuel display. Useful for injecting page-specific action buttons without
  /// modifying the shared TopBar layout.
  final Widget? actions;

  const TopBar({
    super.key,
    required this.title,
    this.onVarsityToggle,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final winery = ref.watch(refineryProvider);
    final fuel =
        winery
            .refinedFuel; // Assuming this is the "paper money" / fuel equivalent

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: Colors.cyan.withOpacity(0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title & Left Controls
          Row(
            children: [
              if (onVarsityToggle != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    icon: const Icon(Icons.school, color: Colors.cyan),
                    onPressed: onVarsityToggle,
                    tooltip: "Varsity Orbit",
                  ),
                ),
              Text(
                title,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),

          // Right Side: (optional actions) + Fuel & Bots
          Row(
            children: [
              // Page-specific action button (e.g. SmsSyncButton on Logistics)
              if (actions != null) ...[actions!, const SizedBox(width: 8)],

              // Fuel Display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_gas_station,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fuel.toStringAsFixed(0),
                      style: GoogleFonts.shareTechMono(
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Bot Icons
              _buildBotIcon(context, ref, 'lib/assets/case.png', BotType.aura),
              const SizedBox(width: 12),
              _buildBotIcon(context, ref, 'lib/assets/tars.png', BotType.crash),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotIcon(
    BuildContext context,
    WidgetRef ref,
    String assetPath,
    BotType type,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(botChatProvider.notifier).openChat(type);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
          image: DecorationImage(
            image: AssetImage(assetPath),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class BotChatPanel extends ConsumerStatefulWidget {
  const BotChatPanel({super.key});

  @override
  ConsumerState<BotChatPanel> createState() => _BotChatPanelState();
}

class _BotChatPanelState extends ConsumerState<BotChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Responsive breakpoints
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;

  bool _isMobile(double width) => width < _mobileBreakpoint;
  bool _isTablet(double width) =>
      width >= _mobileBreakpoint && width < _tabletBreakpoint;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(botChatProvider);
    final activeBot = chatState.activeBot;

    if (activeBot == null) return const SizedBox();

    // Dynamic Theming
    final isCrash = activeBot == BotType.crash;
    final themeColor = isCrash ? Colors.orange : Colors.cyan;
    final headerText =
        isCrash ? "CRASH OVERRIDE // UNSTABLE" : "AURA SYSTEM // ONLINE";
    final hintText =
        isCrash ? "Say something, if you must..." : "Enter directive...";

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Get screen dimensions for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = _isMobile(screenWidth);
    final isTablet = _isTablet(screenWidth);

    // Responsive width - consistent mobile-like centered design for all screens
    final panelWidth =
        isMobile
            ? screenWidth *
                0.92 // 92% on mobile
            : isTablet
            ? screenWidth *
                0.6 // 60% on tablet
            : screenWidth * 0.4; // 40% on desktop (but still centered)

    // Fixed 45% height, positioned at bottom
    final panelHeight = screenHeight * 0.45;
    final bottomOffset = 16.0;
    final horizontalOffset = (screenWidth - panelWidth) / 2; // Always centered

    // Responsive sizing
    final headerPadding = isMobile ? 10.0 : 12.0;
    final headerIconSize = isMobile ? 16.0 : 18.0;
    final headerFontSize = isMobile ? 11.0 : 14.0;
    final messagePadding = isMobile ? 12.0 : 16.0;
    final inputPadding = isMobile ? 10.0 : 12.0;

    return Positioned(
      bottom: bottomOffset,
      left: horizontalOffset,
      width: panelWidth,
      height: panelHeight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1115).withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: themeColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(headerPadding),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                  border: Border(
                    bottom: BorderSide(color: themeColor.withOpacity(0.3)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCrash ? Icons.warning_amber_rounded : Icons.security,
                      color: themeColor,
                      size: headerIconSize,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        headerText,
                        style: GoogleFonts.shareTechMono(
                          color: themeColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: headerFontSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: isMobile ? 22 : 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed:
                          () => ref.read(botChatProvider.notifier).closeChat(),
                    ),
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(messagePadding),
                  itemCount: chatState.currentMessages.length,
                  itemBuilder: (context, index) {
                    final msg = chatState.currentMessages[index];
                    return _buildMessageBubble(msg, themeColor, isMobile);
                  },
                ),
              ),

              // Input
              Container(
                padding: EdgeInsets.all(inputPadding),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white10)),
                  color: Colors.black26,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white,
                          fontSize: isMobile ? 13 : 14,
                        ),
                        decoration: InputDecoration(
                          hintText: hintText,
                          hintStyle: GoogleFonts.shareTechMono(
                            color: Colors.white24,
                            fontSize: isMobile ? 13 : 14,
                          ),
                          border: InputBorder.none,
                          isDense: isMobile,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: isMobile ? 8 : 12,
                          ),
                        ),
                        onSubmitted: (value) {
                          ref.read(botChatProvider.notifier).sendMessage(value);
                          _controller.clear();
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color: themeColor,
                        size: isMobile ? 22 : 24,
                      ),
                      padding: EdgeInsets.all(isMobile ? 6 : 8),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        ref
                            .read(botChatProvider.notifier)
                            .sendMessage(_controller.text);
                        _controller.clear();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, Color themeColor, bool isMobile) {
    final messageFontSize = isMobile ? 12.0 : 14.0;
    final bubblePadding = isMobile ? 10.0 : 12.0;
    final bubbleMargin = isMobile ? 8.0 : 12.0;
    final sideMargin = isMobile ? 24.0 : 40.0;

    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: EdgeInsets.only(bottom: bubbleMargin, left: sideMargin),
          padding: EdgeInsets.all(bubblePadding),
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.15),
            border: Border.all(color: themeColor.withOpacity(0.3)),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(2),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Text(
            msg.text,
            style: GoogleFonts.shareTechMono(
              color: Colors.white,
              fontSize: messageFontSize,
            ),
          ),
        ),
      );
    } else {
      // Handle System Messages (botType == null)
      if (msg.botType == null) {
        return Align(
          alignment: Alignment.center,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 12,
              vertical: isMobile ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              msg.text,
              style: GoogleFonts.shareTechMono(
                color: Colors.white54,
                fontSize: isMobile ? 9 : 10,
              ),
            ),
          ),
        );
      }

      final isCrash = msg.botType == BotType.crash;
      final color = isCrash ? Colors.orange : Colors.cyan;
      final name = isCrash ? "CRASH" : "AURA";
      final avatarSize = isMobile ? 24.0 : 28.0;

      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(bottom: bubbleMargin, right: sideMargin),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                margin: EdgeInsets.only(top: isMobile ? 2 : 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.5)),
                  image: DecorationImage(
                    image: AssetImage(
                      isCrash ? 'lib/assets/tars.png' : 'lib/assets/case.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.orbitron(
                        color: color,
                        fontSize: isMobile ? 9 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isMobile ? 3 : 4),
                    Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(2),
                          topRight: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        msg.text,
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white70,
                          fontSize: messageFontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
