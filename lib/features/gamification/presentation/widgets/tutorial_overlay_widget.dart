import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CharacterSpeaker { aura, crash }

class DialogNode {
  final CharacterSpeaker speaker;
  final String text;

  const DialogNode(this.speaker, this.text);
}

class TutorialOverlayWidget extends ConsumerStatefulWidget {
  final List<DialogNode> dialogs;
  final VoidCallback onComplete;

  const TutorialOverlayWidget({
    super.key,
    required this.dialogs,
    required this.onComplete,
  });

  @override
  ConsumerState<TutorialOverlayWidget> createState() => _TutorialOverlayWidgetState();
}

class _TutorialOverlayWidgetState extends ConsumerState<TutorialOverlayWidget> {
  int _currentIndex = 0;
  bool _isTyping = true; // wait for text to finish typing before allowing next

  void _nextDialog() {
    if (!_isTyping) {
      if (_currentIndex < widget.dialogs.length - 1) {
        setState(() {
          _currentIndex++;
          _isTyping = true;
        });
      } else {
        widget.onComplete();
      }
    } else {
      // If user taps while typing, skip to the end of the current text instantly.
      setState(() {
        _isTyping = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dialogs.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentDialog = widget.dialogs[_currentIndex];
    final isAura = currentDialog.speaker == CharacterSpeaker.aura;
    
    final themeColor = isAura ? const Color(0xFF00D9FF) : const Color(0xFFFF2A2A);
    final shadowColor = isAura ? const Color(0xFF00D9FF).withOpacity(0.5) : const Color(0xFFFF2A2A).withOpacity(0.5);
    final characterName = isAura ? "AURA v3.2" : "CRASH-X";
    // Using local placeholder assets for characters as requested. Ensure these exist or use default icons.
    // avatarImage: isAura ? 'assets/tars.png' : 'assets/case.png' (used when assets available)

    // Need a full screen tap detector to progress the dialogue
    return GestureDetector(
      onTap: _nextDialog,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 1. The Background: Dark overlay without blur
            Positioned.fill(
              child: Container(color: const Color(0xAA0B0E14)),
            ),

            // 4. Developer Skip Button
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: widget.onComplete,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "SKIP TUTORIAL [DEV]",
                    style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 10),
                  ),
                ),
              ),
            ),

            // Avatar & Dialog Container at the bottom
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: isAura ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  // 2. The Avatar (conditionally placed left/right)
                  Row(
                    mainAxisAlignment: isAura ? MainAxisAlignment.start : MainAxisAlignment.end,
                    children: [
                      // Avatar placeholder (simplified)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1520),
                          shape: BoxShape.circle,
                          border: Border.all(color: themeColor, width: 2),
                          boxShadow: [
                            BoxShadow(color: shadowColor, blurRadius: 20, spreadRadius: -5),
                          ]
                        ),
                        // Use actual avatar images (tars.png and case.png)
                        child: ClipOval(
                          child: Image.asset(
                            isAura ? 'lib/assets/tars.png' : 'lib/assets/case.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            semanticLabel: isAura ? 'AURA Avatar' : 'CRASH Avatar',
                          ),
                        ),
                      ),
                    ],
                  ),  

                  // 3. The Dialog Box
                  Container(
                    width: double.infinity, // stretch full width
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF060A10), // Dark background
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeColor, width: 2),
                      boxShadow: [
                        BoxShadow(color: shadowColor, blurRadius: 15, spreadRadius: -2),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: themeColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            characterName,
                            style: GoogleFonts.orbitron(
                              color: themeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Dialogue Text (Animated or Instant)
                        _isTyping 
                        ? AnimatedTextKit(
                            key: ValueKey('$_currentIndex'), // Force rebuild on new text
                            animatedTexts: [
                              TypewriterAnimatedText(
                                currentDialog.text,
                                textStyle: GoogleFonts.shareTechMono(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                                speed: const Duration(milliseconds: 30),
                              ),
                            ],
                            isRepeatingAnimation: false,
                            displayFullTextOnTap: true,
                            onFinished: () {
                              if (mounted) setState(() => _isTyping = false);
                            },
                          )
                        : Text(
                            currentDialog.text,
                            style: GoogleFonts.shareTechMono(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),

                        // Animated "Tap to continue" indicator
                        if (!_isTyping)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                "▼", // Simple blinking arrow substitution
                                style: TextStyle(color: themeColor, fontSize: 16),
                              ),
                            ),
                          ),
                      ],
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
