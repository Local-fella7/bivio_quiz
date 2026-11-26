import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bivio_quiz/models/quiz_question.dart';
import 'package:bivio_quiz/quiz.dart';
import 'package:bivio_quiz/services/question_repository.dart';
import 'package:bivio_quiz/services/quiz_pdf_service.dart';
import 'package:bivio_quiz/widgets/celebration_flowers.dart';

/// Simple test repository that returns pre-loaded questions deterministically.
class _InMemoryQuestionRepository extends QuestionRepository {
  const _InMemoryQuestionRepository(this._questions);

  final List<QuizQuestion> _questions;

  @override
  Future<List<QuizQuestion>> loadQuestions() async => _questions;
}

/// End-to-end widget tests for Bivio Quiz covering:
/// - Dynamic JSON question loading & StartScreen rendering
/// - Category & difficulty filtering
/// - QuestionsScreen progress indicator & instant feedback transitions
/// - ResultsScreen score, answer explanations, Share Result, Restart, and Home
/// - Local history persistence via SharedPreferences
void main() {
  setUp(() {
    // Disable runtime HTTP font fetching so tests run deterministically offline.
    GoogleFonts.config.allowRuntimeFetching = false;
    // Start each test with a clean in-memory SharedPreferences store.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('StartScreen loads JSON questions and renders filters & Start Quiz',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Quiz());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Learn Bivio easy way'), findsOneWidget);
    expect(find.text('Start Quiz (64 questions)'), findsOneWidget);
    expect(find.text('Essentials & Access'), findsOneWidget);
    expect(find.text('Sales, Orders & Bills'), findsOneWidget);
    expect(find.text('Quick Mode'), findsOneWidget);
  });

  testWidgets(
      'Category filtering, full quiz flow, explanations, Home, and history work',
      (WidgetTester tester) async {
    // Read the Bivio JSON question bank synchronously for test assertions.
    final rawJson = File('lib/data/bivio-quiz.json').readAsStringSync();
    final allQuestions = QuestionRepository.parseQuestionBank(
      jsonDecode(rawJson) as Map<String, dynamic>,
    );
    final bivioQuestions = QuestionRepository.filterQuestions(
      allQuestions: allQuestions,
      category: 'Essentials & Access',
      difficulty: 'All',
    );
    expect(bivioQuestions.length, 10);

    await tester.pumpWidget(
      Quiz(questionRepository: _InMemoryQuestionRepository(allQuestions)),
    );
    await tester.pumpAndSettle();

    // Filter to the "Essentials & Access" category and verify the count.
    await tester.tap(find.text('Essentials & Access'));
    await tester.pumpAndSettle();
    expect(find.text('Start Quiz (10 questions)'), findsOneWidget);

    // Start the filtered quiz.
    await tester.ensureVisible(find.text('Start Quiz (10 questions)'));
    await tester.tap(find.text('Start Quiz (10 questions)'));
    await tester.pumpAndSettle();

    // Answer every question correctly, waiting through the 650ms feedback delay.
    for (var i = 0; i < bivioQuestions.length; i++) {
      final question = bivioQuestions[i];
      expect(find.text('Question ${i + 1} of ${bivioQuestions.length}'),
          findsOneWidget);
      expect(find.text(question.text), findsOneWidget);

      await tester.ensureVisible(find.text(question.correctAnswer));
      await tester.tap(find.text(question.correctAnswer));
      // Advance past the 650ms instant-feedback delay and screen transition.
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
    }

    // Verify ResultsScreen score, flower celebration (>50%), explanation, and actions.
    expect(find.byType(CelebrationFlowers), findsOneWidget);
    expect(find.text('Great Job! 🌸'), findsOneWidget);
    expect(
      find.text(
        'You answered ${bivioQuestions.length} out of ${bivioQuestions.length} questions correctly!',
      ),
      findsOneWidget,
    );
    expect(find.text(bivioQuestions.first.explanation), findsOneWidget);
    expect(find.text('Share Result'), findsOneWidget);
    expect(find.text('Restart Quiz'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    // Tap Home and confirm Best score (100%) and History (1) are updated.
    await tester.ensureVisible(find.text('Home'));
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Best: 100%'), findsOneWidget);
    expect(find.text('History (1)'), findsOneWidget);
  });

  test('QuizPdfService generates a valid multi-page PDF report', () async {
    final rawJson = File('lib/data/bivio-quiz.json').readAsStringSync();
    final questions = QuestionRepository.parseQuestionBank(
      jsonDecode(rawJson) as Map<String, dynamic>,
    );

    final bytes = await const QuizPdfService().generate(
      questions: questions,
      chosenAnswers: questions.map((q) => q.correctAnswer).toList(),
      category: 'All',
      difficulty: 'All',
      bestPercentage: 100,
      generatedAt: DateTime(2026, 11, 26, 14, 45),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(100000));
  });

  testWidgets('Share Result offers PDF share, download, and text copy',
      (WidgetTester tester) async {
    const question = QuizQuestion(
      text: 'Is this a single-question quiz?',
      answers: ['Yes', 'No'],
      category: 'Essentials & Access',
      difficulty: 'Easy',
      explanation: 'This makes the results screen quick to reach in tests.',
    );

    await tester.pumpWidget(
      Quiz(questionRepository: _InMemoryQuestionRepository([question])),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Start Quiz (1 questions)'));
    await tester.tap(find.text('Start Quiz (1 questions)'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Yes'));
    await tester.tap(find.text('Yes'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Share Result'));
    await tester.tap(find.text('Share Result'));
    await tester.pumpAndSettle();

    expect(find.text('Share PDF'), findsOneWidget);
    expect(find.text('Download / print PDF'), findsOneWidget);
    expect(find.text('Copy text summary'), findsOneWidget);
  });
}
