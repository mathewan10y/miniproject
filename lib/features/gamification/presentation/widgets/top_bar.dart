import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stardust/core/providers/refinery_provider.dart';
import '../providers/bot_chat_provider.dart';

class TopBar extends ConsumerWidget {
  final String title;

  const TopBar({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final winery = ref.watch(refineryProvider);
    final fuel = winery.refinedFuel; // Assuming this is the "paper money" / fuel equivalent
    
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
          // Title
          Text(
            title,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),

          // Right Side: Fuel & Bots
          Row(
            children: [
              // Fuel Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_gas_station, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      fuel.toStringAsFixed(0),
                      style: GoogleFonts.shareTechMono(color: Colors.green, fontSize: 16),
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

  Widget _buildBotIcon(BuildContext context, WidgetRef ref, String assetPath, BotType type) {
    return GestureDetector(
      onTap: () {
        ref.read(botChatProvider.notifier).toggleChat();
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(botChatProvider);
    
    if (!chatState.isChatOpen) return const SizedBox();

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

    return Positioned(
      top: 60, // Below TopBar
      bottom: 0,
      right: 0,
      width: MediaQuery.of(context).size.width * 0.3, // 30% width
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1115).withOpacity(0.95),
          border: const Border(left: BorderSide(color: Colors.cyan)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black45,
              child: Row(
                children: [
                  Text("COMM.LINK // ESTABLISHED", style: GoogleFonts.shareTechMono(color: Colors.cyan)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => ref.read(botChatProvider.notifier).toggleChat(),
                  ),
                ],
              ),
            ),
            
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: chatState.messages.length,
                itemBuilder: (context, index) {
                  final msg = chatState.messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),
            
            // Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.shareTechMono(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter command...",
                        hintStyle: GoogleFonts.shareTechMono(color: Colors.white24),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        ref.read(botChatProvider.notifier).sendMessage(value);
                        _controller.clear();
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.cyan),
                    onPressed: () {
                      ref.read(botChatProvider.notifier).sendMessage(_controller.text);
                      _controller.clear();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 40),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.cyan.withOpacity(0.1),
            border: Border.all(color: Colors.cyan.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(msg.text, style: GoogleFonts.shareTechMono(color: Colors.white)),
        ),
      );
    } else {
      final isCrash = msg.botType == BotType.crash;
      final color = isCrash ? Colors.orange : Colors.blue; 
      final name = isCrash ? "CRASH" : "AURA";
      
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, right: 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24, height: 24,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(isCrash ? 'lib/assets/tars.png' : 'lib/assets/case.png'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.orbitron(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(msg.text, style: GoogleFonts.shareTechMono(color: Colors.white70)),
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
