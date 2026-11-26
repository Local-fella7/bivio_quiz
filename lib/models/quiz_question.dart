/// Immutable data model representing a single quiz question.
///
/// By convention, [answers] always stores the correct answer at index `0`.
/// The UI calls [getShuffledAnswers] so the choices appear in random order
/// without mutating the original [answers] list.
class QuizQuestion {
  const QuizQuestion({
    required this.text,
    required this.answers,
    required this.category,
    required this.difficulty,
    required this.explanation,
  });

  /// The prompt text displayed to the user.
  final String text;

  /// All answer options for this question; index `0` is the correct answer.
  final List<String> answers;

  /// Topic category used for filtering (e.g., 'Flutter Basics', 'Dart').
  final String category;

  /// Difficulty level used for filtering ('Easy', 'Medium', or 'Hard').
  final String difficulty;

  /// Short educational explanation shown on the Results Screen.
  final String explanation;

  /// Convenience getter returning the canonical correct answer (always index 0).
  String get correctAnswer => answers.first;

  /// Returns a newly shuffled copy of [answers] so the original list stays intact.
  List<String> getShuffledAnswers() {
    final shuffledList = List<String>.of(answers);
    shuffledList.shuffle();
    return shuffledList;
  }

  /// Parses a flat JSON map into a [QuizQuestion] instance.
  ///
  /// The Bivio question bank uses a different envelope and is parsed by
  /// [QuestionRepository.parseQuestionBank] instead.
  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      text: json['text'] as String,
      answers: List<String>.from(json['answers'] as List<dynamic>),
      category: json['category'] as String? ?? 'Flutter Basics',
      difficulty: json['difficulty'] as String? ?? 'Easy',
      explanation: json['explanation'] as String? ?? '',
    );
  }
}
