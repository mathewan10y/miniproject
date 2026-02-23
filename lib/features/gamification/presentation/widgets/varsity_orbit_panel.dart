import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/varsity_service.dart';
import '../../domain/models/varsity_level.dart';
import 'top_bar.dart'; // For Bot interaction if needed, or simply triggered via provider
import '../providers/bot_chat_provider.dart';
import '../../../../core/services/aura_service.dart';
import '../../../../core/services/crash_service.dart';

// Simple provider for the service
final varsityServiceProvider = Provider<VarsityService>((ref) => VarsityService());

class VarsityOrbitPanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const VarsityOrbitPanel({super.key, required this.onClose});

  @override
  ConsumerState<VarsityOrbitPanel> createState() => _VarsityOrbitPanelState();
}

class _VarsityOrbitPanelState extends ConsumerState<VarsityOrbitPanel> {
  String? _expandedLevelId;

  @override
  Widget build(BuildContext context) {
    final varsityService = ref.watch(varsityServiceProvider);
    final levels = varsityService.getLevels();

    return Positioned(
      top: 60, // Below TopBar
      bottom: 0,
      left: 0, // Left side alignment
      width: MediaQuery.of(context).size.width * 0.3, // 30% width, mirrored
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1115).withOpacity(0.95),
          border: const Border(right: BorderSide(color: Colors.cyan, width: 2)), // Right border for Left panel
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: Colors.cyan.withOpacity(0.3))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: widget.onClose,
                  ),
                  const Spacer(),
                  Text(
                    "VARSITY ORBIT // LEVELS",
                    style: GoogleFonts.shareTechMono(
                      color: Colors.cyan,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.school,
                    color: Colors.cyan,
                    size: 18,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: levels.length,
                itemBuilder: (context, index) {
                  final level = levels[index];
                  return _buildLevelCard(level);
                },
              ),
            ),
            
            // Bot Interaction Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
                color: Colors.black26,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Text(
                    "REQUEST BRIEFING", 
                    style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10),
                    textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 8),
                   Row(
                     children: [
                       Expanded(
                         child: ElevatedButton.icon(
                           onPressed: () {
                             final text = AuraService().getVarsityBriefing();
                             ref.read(botChatProvider.notifier).openChat(BotType.aura);
                             // We need to inject the message. The BotChatNotifier might not have a public method for specific text injection easily without user input simulation.
                             // Looking at BotChatNotifier (I assume it exists), usually it handles user input.
                             // I'll simulate a "system" response or just let the user "ask" and get a response.
                             // For now, I'll just print it as a system message if possible, or try to find a way to make the bot say it.
                             // Actually, let's just use `sendMessage` with a special flag or just `addMessage`.
                             // Since I can't easily see the Notifier implementation right now (I saw the provider usage), 
                             // I will Assume there is a way or I will just send a mock user message "Brief me on Varsity" and then the bot responds.
                             // Taking a simpler approach: Just calling a method on the notifier if I can.
                             // I'll just use the `openChat` for now and maybe try to `sendMessage` as the *bot*.
                             // Wait, `sendMessage` in `BotChatPanel` seemed to take user input.
                             // I will implement a helper in the `BotChatNotifier` if I can, but I can't edit it right now easily without finding it.
                             // `botChatProvider.notifier` was called in `top_bar.dart`.
                             // I'll assume `addMessage` exists or similar. 
                             // Re-reading `top_bar.dart`: `ref.read(botChatProvider.notifier).sendMessage(value);`
                             // I'll try to find `bot_chat_provider.dart` to see if I can make the bot talk.
                             // For now, I'll just open the chat.
                             _triggerBotResponse(ref, BotType.aura);
                           },
                           icon: const Icon(Icons.shield, size: 16),
                           label: const Text("AURA"),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.cyan.withOpacity(0.2),
                             foregroundColor: Colors.cyan,
                           ),
                         ),
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                         child: ElevatedButton.icon(
                           onPressed: () {
                             _triggerBotResponse(ref, BotType.crash);
                           },
                           icon: const Icon(Icons.warning, size: 16),
                           label: const Text("CRASH"),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.orange.withOpacity(0.2),
                             foregroundColor: Colors.orange,
                           ),
                         ),
                       ),
                     ],
                   )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerBotResponse(WidgetRef ref, BotType type) {
    // Open the chat first
    ref.read(botChatProvider.notifier).openChat(type);
    
    // Inject the specific message
    String message = "";
    if (type == BotType.aura) {
       message = AuraService().getVarsityBriefing();
    } else {
       message = CrashService().getVarsityRoast();
    }
    
    // Small delay to make it feel natural after opening
    Future.delayed(const Duration(milliseconds: 300), () {
       ref.read(botChatProvider.notifier).injectBotResponse(type, message);
    });
  }

  Widget _buildLevelCard(VarsityLevel level) {
    final isExpanded = _expandedLevelId == level.id;
    final isLocked = level.isLocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isExpanded ? Colors.cyan.withOpacity(0.05) : Colors.white.withOpacity(0.02),
        border: Border.all(
          color: isExpanded ? Colors.cyan.withOpacity(0.5) : Colors.white10,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedLevelId = null;
                } else {
                  _expandedLevelId = level.id;
                }
              });
            },
            leading: Icon(
              isLocked ? Icons.lock : Icons.lock_open,
              color: isLocked ? Colors.grey : Colors.cyan,
            ),
            title: Text(
              level.name.toUpperCase(),
              style: GoogleFonts.orbitron(
                color: isLocked ? Colors.grey : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              level.title,
              style: GoogleFonts.shareTechMono(
                color: isLocked ? Colors.grey : Colors.white54,
                fontSize: 12,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white24,
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.description,
                    style: GoogleFonts.shareTechMono(color: Colors.cyan, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),
                  ...level.modules.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         const Icon(Icons.arrow_right, color: Colors.white24, size: 16),
                         Expanded(child: Text(m, style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 12))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
