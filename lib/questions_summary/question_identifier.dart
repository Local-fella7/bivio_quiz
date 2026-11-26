import 'package:flutter/material.dart';

/// Circular numbered badge displayed next to each item in [QuestionsSummary].
///
/// Renders green (`#69F0AE`) when the user answered correctly and coral-red
/// (`#FF8A80`) when the user answered incorrectly or timed out.
class QuestionIdentifier extends StatelessWidget {
  const QuestionIdentifier({
    super.key,
    required this.isCorrectAnswer,
    required this.questionIndex,
  });

  /// Zero-based question index; displayed as 1-based (`questionIndex + 1`).
  final int questionIndex;

  /// Whether the user's answer matched the correct answer.
  final bool isCorrectAnswer;

  @override
  Widget build(BuildContext context) {
    final questionNumber = questionIndex + 1;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isCorrectAnswer
            ? const Color(0xFF69F0AE)
            : const Color(0xFFFF8A80),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        questionNumber.toString(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF0A2463),
        ),
      ),
    );
  }
}
