import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bivio_quiz/questions_summary/question_identifier.dart';

/// Single row in [QuestionsSummary] displaying one answered question's breakdown:
/// - Circular numbered [QuestionIdentifier] badge (green if correct, red if wrong)
/// - Question text in [GoogleFonts.lato]
/// - The user's chosen answer (colored red if wrong, green if right)
/// - The canonical correct answer (in green)
/// - A short educational explanation of why the correct answer is right
class SummaryItem extends StatelessWidget {
  const SummaryItem(this.itemData, {super.key});

  /// Map containing `question_index`, `question`, `user_answer`,
  /// `correct_answer`, and `explanation`.
  final Map<String, Object> itemData;

  @override
  Widget build(BuildContext context) {
    final userAnswer = itemData['user_answer'] as String;
    final correctAnswer = itemData['correct_answer'] as String;
    final explanation = itemData['explanation'] as String? ?? '';
    final isCorrectAnswer = userAnswer == correctAnswer;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionIdentifier(
            isCorrectAnswer: isCorrectAnswer,
            questionIndex: itemData['question_index'] as int,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemData['question'] as String,
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your answer: $userAnswer',
                  style: TextStyle(
                    color: isCorrectAnswer
                        ? const Color(0xFF69F0AE)
                        : const Color(0xFFFF8A80),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isCorrectAnswer)
                  Text(
                    'Correct answer: $correctAnswer',
                    style: const TextStyle(
                      color: Color(0xFF69F0AE),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (explanation.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      explanation,
                      style: const TextStyle(
                        color: Color(0xFFE3F2FD),
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
