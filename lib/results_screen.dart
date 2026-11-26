import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:bivio_quiz/models/quiz_question.dart';
import 'package:bivio_quiz/questions_summary/questions_summary.dart';
import 'package:bivio_quiz/services/pdf_download_service.dart';
import 'package:bivio_quiz/services/quiz_pdf_service.dart';
import 'package:bivio_quiz/widgets/celebration_flowers.dart';

/// Final screen shown after the user completes all active quiz questions.
///
/// Displays:
/// - Total score (`You answered X out of N questions correctly!`) and percentage
/// - Persisted best score badge
/// - Scrollable [QuestionsSummary] with answer explanations
/// - A **Share Result** action offering a detailed PDF report (share, download
///   or print) plus a plain-text copy
/// - Action buttons to **Restart Quiz** or return **Home**
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
    this.pdfService = const QuizPdfService(),
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

  /// Builds the PDF report shared or downloaded from this screen.
  final QuizPdfService pdfService;

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

  /// Generates the PDF bytes for the current session.
  Future<Uint8List> _buildPdf() {
    return pdfService.generate(
      questions: questions,
      chosenAnswers: chosenAnswers,
      category: category,
      difficulty: difficulty,
      bestPercentage: bestPercentage,
    );
  }

  /// Shows the share sheet with options for WhatsApp, Files, email, and more.
  Future<void> _sharePdf(BuildContext context) async {
    try {
      final bytes = await _buildPdf();
      await Printing.sharePdf(
        bytes: bytes,
        filename: QuizPdfService.suggestedFileName(),
      );
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(context, 'Could not share the PDF. Please try again.');
    }
  }

  /// Saves the PDF to Downloads, or starts a browser download on web.
  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final bytes = await _buildPdf();
      final filename = QuizPdfService.suggestedFileName();
      final savedPath = await downloadPdfBytes(bytes, filename);
      if (!context.mounted) return;
      _showMessage(
        context,
        savedPath == null
            ? 'PDF download started.'
            : 'PDF saved to $savedPath',
      );
    } catch (error) {
      debugPrint('PDF download failed: $error');
      if (!context.mounted) return;
      _showMessage(context, 'Could not download the PDF. Please try again.');
    }
  }

  /// Copies a formatted score summary to the system clipboard.
  Future<void> _copySummary(
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
    _showMessage(context, 'Result copied to clipboard!');
  }

  /// Presents PDF share/download and text-copy actions to the user.
  void _showShareOptions(
    BuildContext context, {
    required int numCorrect,
    required int numTotal,
    required int percentage,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0A2463),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share your result',
                style: TextStyle(
                  color: Color(0xFFF8FAE5),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined,
                    color: Color(0xFFF8FAE5)),
                title: const Text('Share PDF',
                    style: TextStyle(color: Color(0xFFF8FAE5))),
                subtitle: const Text('WhatsApp, Files, email and other apps',
                    style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _sharePdf(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined,
                    color: Color(0xFFF8FAE5)),
                title: const Text('Download / print PDF',
                    style: TextStyle(color: Color(0xFFF8FAE5))),
                subtitle: const Text('Save as a PDF file or send to a printer',
                    style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _downloadPdf(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined,
                    color: Color(0xFFF8FAE5)),
                title: const Text('Copy text summary',
                    style: TextStyle(color: Color(0xFFF8FAE5))),
                subtitle: const Text('Paste a short score into any app',
                    style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _copySummary(
                    context,
                    numCorrect: numCorrect,
                    numTotal: numTotal,
                    percentage: percentage,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a short floating message without blocking the current screen.
  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
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
                          onPressed: () => _showShareOptions(
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
