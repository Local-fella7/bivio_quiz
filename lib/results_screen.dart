import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bivio_quiz/models/quiz_question.dart';
import 'package:bivio_quiz/questions_summary/questions_summary.dart';
import 'package:bivio_quiz/widgets/celebration_flowers.dart';

/// Final screen shown after the user completes all active quiz questions.
///
/// Displays:
/// - Total score (`You answered X out of N questions correctly!`) and percentage
/// - Persisted best score badge
/// - Scrollable [QuestionsSummary] with answer explanations
/// - Action buttons to **Share Result**, **Restart Quiz**, or return **Home**
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.questions,
    required this.chosenAnswers,
    required this.bestPercentage,
    required this.category,
    required this.difficulty,
    required this.onRestart,
    required this.onReturnHome,
  });

  /// The exact list of questions asked in this session.
  final List<QuizQuestion> questions;

  /// Answers recorded for each question in the same order as [questions].
  final List<String> chosenAnswers;

  /// All-time best percentage persisted via [QuizStorageService].
  final int bestPercentage;

  /// Category filter used for this quiz session.
  final String category;

  /// Difficulty filter used for this quiz session.
  final String difficulty;

  /// Clears answers and starts a fresh round with the same filters.
  final void Function() onRestart;

  /// Returns the user to [StartScreen] to change filters or view history.
  final void Function() onReturnHome;

  /// Pairs each question with its canonical correct answer, user answer, and explanation.
  List<Map<String, Object>> get summaryData {
    final List<Map<String, Object>> summary = [];

    for (var i = 0; i < chosenAnswers.length && i < questions.length; i++) {
      summary.add({
        'question_index': i,
        'question': questions[i].text,
        'correct_answer': questions[i].correctAnswer,
        'user_answer': chosenAnswers[i],
        'explanation': questions[i].explanation,
      });
    }

    return summary;
  }

  /// Copies a formatted score summary to the system clipboard and notifies the user.
  Future<void> _shareResult(
    BuildContext context, {
    required int numCorrect,
    required int numTotal,
    required int percentage,
  }) async {
    final shareText =
        'I scored $numCorrect/$numTotal ($percentage%) on Bivio Quiz! '
        '[$category • $difficulty]';

    await Clipboard.setData(ClipboardData(text: shareText));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Result copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = summaryData;
    final numTotalQuestions = questions.length;
    final numCorrectQuestions = data
        .where((item) => item['user_answer'] == item['correct_answer'])
        .length;
    final percentage = numTotalQuestions == 0
        ? 0
        : ((numCorrectQuestions / numTotalQuestions) * 100).round();

    // Celebrate with popping flowers whenever the user scores strictly over 50%.
    final shouldCelebrate = percentage > 50;

    return Stack(
      children: [
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (shouldCelebrate) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x3369F0AE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF69F0AE),
                            width: 1.2,
                          ),
                        ),
                        child: const Text(
                          'Great Job! 🌸',
                          style: TextStyle(
                            color: Color(0xFFF8FAE5),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'You answered $numCorrectQuestions out of $numTotalQuestions questions correctly!',
                      style: GoogleFonts.lato(
                        color: const Color(0xFFF8FAE5),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // Score percentage and persisted best score pill.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Score: $percentage%  •  Best: $bestPercentage%',
                        style: const TextStyle(
                          color: Color(0xFFF8FAE5),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Scrollable breakdown of every question with explanations.
                    QuestionsSummary(data),
                    const SizedBox(height: 24),

                    // Action buttons: Share Result, Restart Quiz, and Back to Home.
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _shareResult(
                            context,
                            numCorrect: numCorrectQuestions,
                            numTotal: numTotalQuestions,
                            percentage: percentage,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFF8FAE5),
                            side: const BorderSide(color: Colors.white54),
                          ),
                          icon: const Icon(Icons.share_outlined, size: 18),
                          label: const Text('Share Result'),
                        ),
                        ElevatedButton.icon(
                          onPressed: onRestart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A2463),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Restart Quiz'),
                        ),
                        TextButton.icon(
                          onPressed: onReturnHome,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFF8FAE5),
                          ),
                          icon: const Icon(Icons.home_outlined, size: 18),
                          label: const Text('Home'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Non-blocking popping-flowers burst overlay for scores over 50%.
        if (shouldCelebrate) const Positioned.fill(child: CelebrationFlowers()),
      ],
    );
  }
}
