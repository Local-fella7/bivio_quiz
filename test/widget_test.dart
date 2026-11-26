import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bivio_quiz/models/quiz_question.dart';
import 'package:bivio_quiz/quiz.dart';
import 'package:bivio_quiz/services/question_repository.dart';
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
    expect(find.text('Start Quiz (12 questions)'), findsOneWidget);
    expect(find.text('Flutter Basics'), findsOneWidget);
    expect(find.text('Dart'), findsOneWidget);
    expect(find.text('State Management'), findsOneWidget);
  });

  testWidgets(
      'Category filtering, full quiz flow, explanations, Home, and history work',
      (WidgetTester tester) async {
    // Read the JSON question bank synchronously for test assertions.
    final rawJson = File('assets/data/questions.json').readAsStringSync();
    final allQuestions = (jsonDecode(rawJson) as List<dynamic>)
        .map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>))
        .toList();
    final dartQuestions = QuestionRepository.filterQuestions(
      allQuestions: allQuestions,
      category: 'Dart',
      difficulty: 'All',
    );
    expect(dartQuestions.length, 4);

    await tester.pumpWidget(
      Quiz(questionRepository: _InMemoryQuestionRepository(allQuestions)),
    );
    await tester.pumpAndSettle();

    // Filter to the "Dart" category and verify the count updates to 4.
    await tester.tap(find.text('Dart'));
    await tester.pumpAndSettle();
    expect(find.text('Start Quiz (4 questions)'), findsOneWidget);

    // Start the filtered quiz.
    await tester.ensureVisible(find.text('Start Quiz (4 questions)'));
    await tester.tap(find.text('Start Quiz (4 questions)'));
    await tester.pumpAndSettle();

    // Answer every Dart question correctly, waiting through the 650ms feedback delay.
    for (var i = 0; i < dartQuestions.length; i++) {
      final question = dartQuestions[i];
      expect(find.text('Question ${i + 1} of ${dartQuestions.length}'),
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
        'You answered ${dartQuestions.length} out of ${dartQuestions.length} questions correctly!',
      ),
      findsOneWidget,
    );
    expect(find.text(dartQuestions.first.explanation), findsOneWidget);
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
}
