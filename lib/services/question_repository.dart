import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:bivio_quiz/data/questions.dart';
import 'package:bivio_quiz/models/quiz_question.dart';

/// Repository responsible for dynamically loading and filtering quiz questions.
///
/// By default, questions are loaded from the bundled JSON asset
/// `assets/data/questions.json`. To switch to a remote REST API or Firebase
/// endpoint later, only [loadQuestions] needs to be updated.
class QuestionRepository {
  const QuestionRepository({
    this.assetPath = 'assets/data/questions.json',
  });

  /// Asset path pointing to the JSON question bank.
  final String assetPath;

  /// Loads and decodes all [QuizQuestion] items from [assetPath].
  ///
  /// Falls back to [fallbackQuestions] if the asset cannot be read or parsed.
  Future<List<QuizQuestion>> loadQuestions() async {
    try {
      final rawJson = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(rawJson) as List<dynamic>;
      final loaded = decoded
          .map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>))
          .toList();
      return loaded.isEmpty ? fallbackQuestions : loaded;
    } catch (_) {
      // Gracefully fall back so the app remains usable even if JSON loading fails.
      return fallbackQuestions;
    }
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
