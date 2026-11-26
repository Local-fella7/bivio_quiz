/// Immutable record of a completed quiz session stored in local history.
///
/// Serialized to/from JSON maps so [QuizStorageService] can persist past
/// attempts using `shared_preferences`.
class QuizAttempt {
  const QuizAttempt({
    required this.score,
    required this.totalQuestions,
    required this.category,
    required this.difficulty,
    required this.timestamp,
  });

  /// Number of questions answered correctly in this attempt.
  final int score;

  /// Total number of questions included in this attempt.
  final int totalQuestions;

  /// Selected category filter ('All', 'Flutter Basics', 'Dart', etc.).
  final String category;

  /// Selected difficulty filter ('All', 'Easy', 'Medium', 'Hard').
  final String difficulty;

  /// When the attempt was completed.
  final DateTime timestamp;

  /// Percentage score (0–100) used to compare attempts across different sizes.
  int get percentage =>
      totalQuestions == 0 ? 0 : ((score / totalQuestions) * 100).round();

  /// Converts this attempt into a JSON-encodable map for storage.
  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'totalQuestions': totalQuestions,
      'category': category,
      'difficulty': difficulty,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Restores a [QuizAttempt] from a decoded JSON map.
  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      score: json['score'] as int,
      totalQuestions: json['totalQuestions'] as int,
      category: json['category'] as String? ?? 'All',
      difficulty: json['difficulty'] as String? ?? 'All',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
