import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:bivio_quiz/data/questions.dart';
import 'package:bivio_quiz/models/quiz_question.dart';

/// Repository responsible for dynamically loading and filtering quiz questions.
///
/// By default, questions are loaded from the bundled Bivio question bank at
/// `lib/data/bivio-quiz.json`. To switch to a remote REST API or Firebase
/// endpoint later, only [loadQuestions] needs to be updated.
class QuestionRepository {
  const QuestionRepository({
    this.assetPath = 'lib/data/bivio-quiz.json',
  });

  /// Asset path pointing to the JSON question bank.
  final String assetPath;

  /// Loads and decodes all [QuizQuestion] items from [assetPath].
  ///
  /// Falls back to [fallbackQuestions] if the asset cannot be read or parsed.
  Future<List<QuizQuestion>> loadQuestions() async {
    try {
      final rawJson = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final loaded = parseQuestionBank(decoded);
      return loaded.isEmpty ? fallbackQuestions : loaded;
    } catch (_) {
      // Gracefully fall back so the app remains usable even if JSON loading fails.
      return fallbackQuestions;
    }
  }

  /// Converts the Bivio question-bank format into [QuizQuestion] objects.
  ///
  /// The JSON stores `answer` as a 0-based index into `options`, while
  /// [QuizQuestion] expects the correct answer at index 0 so that the UI can
  /// shuffle a copy without mutating the bank. Category ids are resolved to
  /// their display names and difficulty values are title-cased for the filters.
  static List<QuizQuestion> parseQuestionBank(Map<String, dynamic> decoded) {
    final categoryNames = <String, String>{
      for (final entry in decoded['categories'] as List<dynamic>? ?? const [])
        (entry as Map<String, dynamic>)['id'] as String:
            entry['name'] as String? ?? entry['id'] as String,
    };

    final questions = decoded['questions'] as List<dynamic>? ?? const [];
    return questions.map((item) {
      final question = item as Map<String, dynamic>;
      final options = List<String>.from(question['options'] as List<dynamic>);
      final answerIndex = question['answer'] as int;
      final correctAnswer = options.removeAt(answerIndex);

      final rawCategory = question['category'] as String? ?? 'general';
      final rawDifficulty = question['difficulty'] as String? ?? 'easy';
      final difficulty = rawDifficulty.isEmpty
          ? 'Easy'
          : rawDifficulty[0].toUpperCase() + rawDifficulty.substring(1);

      return QuizQuestion(
        text: question['question'] as String,
        answers: [correctAnswer, ...options],
        category: categoryNames[rawCategory] ?? rawCategory,
        difficulty: difficulty,
        explanation: question['explanation'] as String? ?? '',
      );
    }).toList();
  }

  /// Filters [allQuestions] by the selected [category] and [difficulty].
  ///
  /// Passing `'All'` for either parameter disables filtering on that dimension.
  static List<QuizQuestion> filterQuestions({
    required List<QuizQuestion> allQuestions,
    required String category,
    required String difficulty,
  }) {
    return allQuestions.where((question) {
      final matchesCategory =
          category == 'All' || question.category == category;
      final matchesDifficulty =
          difficulty == 'All' || question.difficulty == difficulty;
      return matchesCategory && matchesDifficulty;
    }).toList();
  }

  /// Extracts the ordered list of available categories, always starting with `'All'`.
  static List<String> extractCategories(List<QuizQuestion> allQuestions) {
    final unique = allQuestions.map((q) => q.category).toSet().toList()..sort();
    return ['All', ...unique];
  }

  /// Standard ordered list of difficulty filters.
  static const List<String> difficulties = ['All', 'Easy', 'Medium', 'Hard'];
}
