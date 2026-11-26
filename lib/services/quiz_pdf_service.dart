import 'dart:typed_data';

import 'package:bivio_quiz/models/quiz_question.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Creates a portable PDF report of a completed Bivio Quiz session.
///
/// The report contains the score summary followed by every question with the
/// user's answer, the correct answer, and the explanation. Bytes produced here
/// can be saved, printed, or handed to the platform share sheet by callers.
class QuizPdfService {
  const QuizPdfService();

  /// Brand image shown in the app and at the top of every result PDF.
  static const String logoAsset = 'assets/images/bivio.jpeg';

  static const String _regularFontAsset = 'assets/fonts/DejaVuSans.ttf';
  static const String _boldFontAsset = 'assets/fonts/DejaVuSans-Bold.ttf';

  /// Builds a stable file name such as `bivio-quiz-result-20261126-1445.pdf`.
  static String suggestedFileName([DateTime? now]) {
    final timestamp = now ?? DateTime.now();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return 'bivio-quiz-result-'
        '${timestamp.year}${twoDigits(timestamp.month)}${twoDigits(timestamp.day)}'
        '-${twoDigits(timestamp.hour)}${twoDigits(timestamp.minute)}.pdf';
  }

  /// Generates the PDF bytes for [questions] and the matching [chosenAnswers].
  Future<Uint8List> generate({
    required List<QuizQuestion> questions,
    required List<String> chosenAnswers,
    required String category,
    required String difficulty,
    required int bestPercentage,
    DateTime? generatedAt,
  }) async {
    final theme = await _loadTheme();
    final document = pw.Document(theme: theme);
    final logo = await _loadLogo();
    final timestamp = generatedAt ?? DateTime.now();
    final total = questions.length;
    final correct = <int>[
      for (var i = 0; i < total; i++)
        if (i < chosenAnswers.length &&
            chosenAnswers[i] == questions[i].correctAnswer)
          i,
    ].length;
    final percentage = total == 0 ? 0 : ((correct / total) * 100).round();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logo != null) ...[
                pw.Image(logo, width: 44, height: 42),
                pw.SizedBox(width: 12),
              ],
              pw.Text(
                'Bivio Quiz - Result Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0A2463'),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Generated ${timestamp.toLocal().toString().split('.').first}',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromHex('#666666'),
            ),
          ),
          pw.SizedBox(height: 12),
          _summaryCard(
            category: category,
            difficulty: difficulty,
            correct: correct,
            total: total,
            percentage: percentage,
            bestPercentage: bestPercentage,
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Question breakdown',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0A2463'),
            ),
          ),
          pw.SizedBox(height: 8),
          ...List<pw.Widget>.generate(
            total,
            (index) => _questionBlock(
              index: index,
              question: questions[index],
              userAnswer: index < chosenAnswers.length
                  ? chosenAnswers[index]
                  : '(no answer)',
              isCorrect: index < chosenAnswers.length &&
                  chosenAnswers[index] == questions[index].correctAnswer,
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _summaryCard({
    required String category,
    required String difficulty,
    required int correct,
    required int total,
    required int percentage,
    required int bestPercentage,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#EEF3FB'),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Score: $correct/$total ($percentage%)',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0A2463'),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Filters: $category / $difficulty',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Best score: $bestPercentage%',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _questionBlock({
    required int index,
    required QuizQuestion question,
    required String userAnswer,
    required bool isCorrect,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#D6DCE5')),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Q${index + 1}. ${question.text}',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0A2463'),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${question.category} | ${question.difficulty}',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromHex('#666666'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Your answer: $userAnswer ${isCorrect ? '[CORRECT]' : '[INCORRECT]'}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: isCorrect
                  ? PdfColor.fromHex('#1B5E20')
                  : PdfColor.fromHex('#B71C1C'),
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Correct answer: ${question.correctAnswer}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          if (question.explanation.trim().isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              'Explanation: ${question.explanation}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }

  Future<pw.ThemeData?> _loadTheme() async {
    try {
      final regular = pw.Font.ttf(await rootBundle.load(_regularFontAsset));
      final bold = pw.Font.ttf(await rootBundle.load(_boldFontAsset));
      return pw.ThemeData.withFont(base: regular, bold: bold);
    } catch (_) {
      return null;
    }
  }

  /// Loads the bundled brand image so the PDF matches the app's identity.
  Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final data = await rootBundle.load(logoAsset);
      return pw.MemoryImage(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } catch (_) {
      return null;
    }
  }
}
