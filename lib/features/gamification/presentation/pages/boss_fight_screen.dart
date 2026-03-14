import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../user_stats_provider.dart';
import '../../data/quiz_data.dart';

class BossFightScreen extends ConsumerStatefulWidget {
  final int levelId;
  const BossFightScreen({super.key, required this.levelId});

  @override
  ConsumerState<BossFightScreen> createState() => _BossFightScreenState();
}

class _BossFightScreenState extends ConsumerState<BossFightScreen> with SingleTickerProviderStateMixin {
  int _userHp = 3;
  int _bossHp = 3;
  late final QuizQuestion _quiz;
  int? _selectedIndex;
  bool _hasAnswered = false;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _quiz = QuizData.getBossQuiz(widget.levelId);
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0.0);
  }

  void _submitAnswer() {
    if (_selectedIndex == null) return;
    setState(() => _hasAnswered = true);
    
    final isCorrect = _selectedIndex == _quiz.correctIndex;

    Future.delayed(const Duration(milliseconds: 600), () {
      if (isCorrect) {
        setState(() => _bossHp = 0);
        _triggerShake();
        Future.delayed(const Duration(seconds: 2), _winSequence);
      } else {
        setState(() => _userHp = 0);
        _triggerShake();
        Future.delayed(const Duration(seconds: 2), _loseSequence);
      }
    });
  }

  void _winSequence() {
    if (!mounted) return;
    ref.read(userStatsProvider.notifier).addExperience(500);
    // Let's assume user stats handles level up?
    // UserStats doesn't explicitly have a level up trigger yet besides rank mapping,
    // wait, we can just bump currentLevel explicitly here or assume XP handles it.
    // If the Boss Fight inherently unlocks the NEXT level, let's bump it.
    ref.read(userStatsProvider.notifier).levelUp();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.greenAccent, width: 2), borderRadius: BorderRadius.circular(16)),
        title: Text("SECTOR SECURED", style: GoogleFonts.orbitron(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
        content: Text("You defeated the anomaly! +500 XP. New transmission unlocked.", style: GoogleFonts.shareTechMono(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // dialog
              Navigator.of(context).pop(true); // screen
            },
            child: Text("PROCEED", style: GoogleFonts.shareTechMono(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );
  }

  void _loseSequence() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.redAccent, width: 2), borderRadius: BorderRadius.circular(16)),
        title: Text("HULL COMPROMISED", style: GoogleFonts.orbitron(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text("Critical mistake. Return to the Codex and study.", style: GoogleFonts.shareTechMono(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // dialog
              Navigator.of(context).pop(false); // screen
            },
            child: Text("RETREAT", style: GoogleFonts.shareTechMono(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A10),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final double offset = 10 * _shakeController.value * (1 - _shakeController.value) * (Theme.of(context).platform == TargetPlatform.android ? 1 : -1);
            return Transform.translate(
              offset: Offset(offset, offset),
              child: child,
            );
          },
          child: Column(
            children: [
              // Top Bar (HP)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("COMMANDER", style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(3, (idx) => Icon(
                            idx < _userHp ? Icons.favorite : Icons.favorite_border,
                            color: Colors.greenAccent,
                            size: 28,
                          )),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("ANOMALY Lv.${widget.levelId}", style: GoogleFonts.orbitron(color: Colors.redAccent, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(3, (idx) => Container(
                            margin: const EdgeInsets.only(left: 4),
                            width: 32,
                            height: 12,
                            decoration: BoxDecoration(
                              color: idx < _bossHp ? Colors.redAccent : Colors.white12,
                              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Boss Graphics Area
              Expanded(
                flex: 2,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 100, spreadRadius: 20),
                          ],
                        ),
                      ),
                      // Mock Image / Graphic
                      Icon(Icons.warning_amber_rounded, size: 140, color: Colors.redAccent.withOpacity(0.8)),
                    ],
                  ),
                ),
              ),

              // Dialog / Questions
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B121C),
                    border: const Border(top: BorderSide(color: Colors.redAccent, width: 2)),
                    boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, -10))],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _quiz.question,
                        style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 16, height: 1.5, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      ...List.generate(_quiz.options.length, (index) {
                        final isSelected = _selectedIndex == index;
                        final isCorrect = index == _quiz.correctIndex;
                        Color borderColor = Colors.white24;
                        Color bgColor = Colors.black38;

                        if (_hasAnswered) {
                          if (isCorrect) {
                            borderColor = Colors.greenAccent; bgColor = Colors.greenAccent.withOpacity(0.2);
                          } else if (isSelected) {
                            borderColor = Colors.redAccent; bgColor = Colors.redAccent.withOpacity(0.2);
                          }
                        } else if (isSelected) {
                          borderColor = const Color(0xFF00D9FF); bgColor = const Color(0xFF00D9FF).withOpacity(0.1);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: _hasAnswered ? null : () => setState(() => _selectedIndex = index),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _quiz.options[index],
                                style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      if (!_hasAnswered)
                        ElevatedButton(
                          onPressed: _selectedIndex == null ? null : _submitAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text("EXECUTE", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
