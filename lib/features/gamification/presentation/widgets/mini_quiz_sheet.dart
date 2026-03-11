import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../user_stats_provider.dart';
import '../../services/tutorial_engine_service.dart';
import '../../data/quiz_data.dart';
import '../../services/tutorial_engine_service.dart';

class MiniQuizSheet extends ConsumerStatefulWidget {
  final int levelId;
  final String subLevelTitle;
  final String question;
  final List<String> options;
  final int correctIndex;

  const MiniQuizSheet({
    super.key,
    required this.levelId,
    required this.subLevelTitle,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  @override
  ConsumerState<MiniQuizSheet> createState() => _MiniQuizSheetState();
}

class _MiniQuizSheetState extends ConsumerState<MiniQuizSheet> {
  int? _selectedIndex;
  bool _hasAnswered = false;
  bool _isCorrect = false;

  void _submitAnswer() async {
    if (_selectedIndex == null) return;

    setState(() {
      _hasAnswered = true;
      _isCorrect = _selectedIndex == widget.correctIndex;
    });

    if (_isCorrect) {
      // Award XP
      ref.read(userStatsProvider.notifier).addExperience(10);
      // Mark as read
      if (!mounted) return;
      await ref.read(tutorialEngineProvider).markSubLevelCompleted(widget.levelId, widget.subLevelTitle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1520),
        border: Border(top: BorderSide(color: Color(0xFF00D9FF), width: 2)),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Color(0xFF00D9FF)),
              const SizedBox(width: 8),
              Text(
                "CADET EVALUATION",
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF00D9FF),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.question,
            style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 24),
          ...List.generate(widget.options.length, (index) {
            final isSelected = _selectedIndex == index;
            final isCorrectOption = index == widget.correctIndex;

            Color borderColor = Colors.white24;
            Color bgColor = Colors.black38;

            if (_hasAnswered) {
              if (isCorrectOption) {
                borderColor = Colors.greenAccent;
                bgColor = Colors.greenAccent.withOpacity(0.2);
              } else if (isSelected) {
                borderColor = Colors.redAccent;
                bgColor = Colors.redAccent.withOpacity(0.2);
              }
            } else if (isSelected) {
              borderColor = const Color(0xFF00D9FF);
              bgColor = const Color(0xFF00D9FF).withOpacity(0.1);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: _hasAnswered ? null : () => setState(() => _selectedIndex = index),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: isSelected
                            ? Center(child: Icon(Icons.circle, size: 12, color: borderColor))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.options[index],
                          style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      if (_hasAnswered && isCorrectOption)
                        const Icon(Icons.check_circle, color: Colors.greenAccent),
                      if (_hasAnswered && isSelected && !isCorrectOption)
                        const Icon(Icons.cancel, color: Colors.redAccent),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          if (!_hasAnswered)
            ElevatedButton(
              onPressed: _selectedIndex == null ? null : _submitAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                "VERIFY ANSWER",
                style: GoogleFonts.shareTechMono(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          if (_hasAnswered)
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_isCorrect), // Returns true if correct
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCorrect ? Colors.greenAccent : Colors.orangeAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                _isCorrect ? "SYSTEM SECURED - +10 XP" : "INCORRECT - RETRY OR REVIEW MANUAL",
                style: GoogleFonts.shareTechMono(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}

class MiniQuizSheetWrapper extends StatelessWidget {
  final int levelId;
  final String subLevelTitle;
  final int subLevelIndex;

  const MiniQuizSheetWrapper({
    super.key,
    required this.levelId,
    required this.subLevelTitle,
    required this.subLevelIndex,
  });

  @override
  Widget build(BuildContext context) {
    final quiz = QuizData.getSubLevelQuiz(levelId, subLevelIndex);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: MiniQuizSheet(
        levelId: levelId,
        subLevelTitle: subLevelTitle,
        question: quiz.question,
        options: quiz.options,
        correctIndex: quiz.correctIndex,
      ),
    );
  }
}
