import 'package:flutter/material.dart';
import 'package:bivio_quiz/data/questions.dart';
import 'package:bivio_quiz/models/quiz_attempt.dart';
import 'package:bivio_quiz/models/quiz_question.dart';
import 'package:bivio_quiz/questions_screen.dart';
import 'package:bivio_quiz/results_screen.dart';
import 'package:bivio_quiz/services/question_repository.dart';
import 'package:bivio_quiz/services/quiz_storage_service.dart';
import 'package:bivio_quiz/start_screen.dart';

/// Root stateful controller for Bivio Quiz.
///
/// Manages:
/// - Dynamic question loading from `lib/data/bivio-quiz.json` via [QuestionRepository]
/// - Local score & history persistence via [QuizStorageService]
/// - Active screen state (`'start-screen'`, `'questions-screen'`, `'results-screen'`)
/// - Category/difficulty filtering, countdown timer toggle, and sound/haptics toggle
/// - Smooth [AnimatedSwitcher] fade + slide transitions over the blue gradient backdrop
class Quiz extends StatefulWidget {
  const Quiz({
    super.key,
    this.questionRepository = const QuestionRepository(),
  });

  /// Injectable repository allowing tests or future API backends to supply questions.
  final QuestionRepository questionRepository;

  @override
  State<Quiz> createState() => _QuizState();
}

class _QuizState extends State<Quiz> {
  /// Persistence service for high scores and past quiz attempts.
  final QuizStorageService _storageService = QuizStorageService();

  /// Full question bank loaded dynamically from JSON (initialized with fallback
  /// so the first frame renders immediately without a blank screen).
  List<QuizQuestion> _allQuestions = fallbackQuestions;

  /// Subset of [_allQuestions] used in the current quiz session.
  List<QuizQuestion> _activeQuestions = fallbackQuestions;

  /// Answers selected by the user during the current quiz session.
  List<String> _selectedAnswers = [];

  /// String state controlling which screen is currently displayed.
  String _activeScreen = 'start-screen';

  /// Selected topic category filter (`'All'` shows every category).
  String _selectedCategory = 'All';

  /// Selected difficulty filter (`'All'` shows every difficulty).
  String _selectedDifficulty = 'All';

  /// Whether the 20-second per-question countdown timer is active.
  bool _timerEnabled = false;

  /// Whether haptic feedback and system click sounds are enabled.
  bool _soundEnabled = true;

  /// Persisted highest percentage score achieved across sessions.
  int _bestPercentage = 0;

  /// Persisted history of completed quiz attempts (newest first).
  List<QuizAttempt> _history = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// Loads the JSON question bank and saved score/history concurrently.
  Future<void> _initializeData() async {
    final loadedQuestions = await widget.questionRepository.loadQuestions();
    final savedHistory = await _storageService.loadHistory();
    final savedBest = await _storageService.loadBestPercentage();

    if (!mounted) return;
    setState(() {
      _allQuestions = loadedQuestions;
      _history = savedHistory;
      _bestPercentage = savedBest;
    });
  }

  /// Returns the list of questions matching the currently selected filters.
  List<QuizQuestion> get _filteredQuestions => QuestionRepository.filterQuestions(
        allQuestions: _allQuestions,
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
      );

  /// Transitions from [StartScreen] into [QuestionsScreen] using filtered questions.
  void _startQuiz() {
    final matching = _filteredQuestions;
    if (matching.isEmpty) return;

    setState(() {
      _activeQuestions = matching;
      _selectedAnswers = [];
      _activeScreen = 'questions-screen';
    });
  }

  /// Records a chosen answer and, once all questions are answered, saves the
  /// attempt to local storage and switches to [ResultsScreen].
  void _chooseAnswer(String answer) {
    _selectedAnswers.add(answer);

    if (_selectedAnswers.length == _activeQuestions.length) {
      // Compute score to store in local history.
      var correctCount = 0;
      for (var i = 0; i < _activeQuestions.length; i++) {
        if (_selectedAnswers[i] == _activeQuestions[i].correctAnswer) {
          correctCount++;
        }
      }

      final attempt = QuizAttempt(
        score: correctCount,
        totalQuestions: _activeQuestions.length,
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        timestamp: DateTime.now(),
      );

      setState(() {
        _activeScreen = 'results-screen';
        if (attempt.percentage > _bestPercentage) {
          _bestPercentage = attempt.percentage;
        }
        _history = [attempt, ..._history];
      });

      // Persist asynchronously so the UI transitions immediately without blocking.
      _persistAttempt(attempt);
    }
  }

  /// Saves [attempt] via [QuizStorageService] and syncs local state.
  Future<void> _persistAttempt(QuizAttempt attempt) async {
    final updatedBest = await _storageService.saveAttempt(attempt);
    final updatedHistory = await _storageService.loadHistory();
    if (!mounted) return;
    setState(() {
      _bestPercentage = updatedBest;
      _history = updatedHistory;
    });
  }

  /// Clears local history and resets the best score badge.
  Future<void> _clearHistory() async {
    await _storageService.clearHistory();
    if (!mounted) return;
    setState(() {
      _history = [];
      _bestPercentage = 0;
    });
  }

  /// Restarts the quiz immediately with the same active questions and settings.
  void _restartQuiz() {
    setState(() {
      _selectedAnswers = [];
      _activeScreen = 'questions-screen';
    });
  }

  /// Returns to [StartScreen] so the user can change filters or check history.
  void _returnHome() {
    setState(() {
      _selectedAnswers = [];
      _activeScreen = 'start-screen';
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = QuestionRepository.extractCategories(_allQuestions);
    final matchingCount = _filteredQuestions.length;

    // Assign a ValueKey to each screen so AnimatedSwitcher animates transitions.
    Widget screenWidget = StartScreen(
      key: const ValueKey('start-screen'),
      onStartQuiz: _startQuiz,
      categories: categories,
      difficulties: QuestionRepository.difficulties,
      selectedCategory: _selectedCategory,
      selectedDifficulty: _selectedDifficulty,
      onCategoryChanged: (category) {
        setState(() {
          _selectedCategory = category;
        });
      },
      onDifficultyChanged: (difficulty) {
        setState(() {
          _selectedDifficulty = difficulty;
        });
      },
      matchingQuestionCount: matchingCount,
      timerEnabled: _timerEnabled,
      onTimerToggled: (enabled) {
        setState(() {
          _timerEnabled = enabled;
        });
      },
      soundEnabled: _soundEnabled,
      onSoundToggled: (enabled) {
        setState(() {
          _soundEnabled = enabled;
        });
      },
      bestPercentage: _bestPercentage,
      history: _history,
      onClearHistory: _clearHistory,
    );

    if (_activeScreen == 'questions-screen') {
      screenWidget = QuestionsScreen(
        key: const ValueKey('questions-screen'),
        questions: _activeQuestions,
        onSelectAnswer: _chooseAnswer,
        onReturnHome: _returnHome,
        timerEnabled: _timerEnabled,
        soundEnabled: _soundEnabled,
      );
    }

    if (_activeScreen == 'results-screen') {
      screenWidget = ResultsScreen(
        key: const ValueKey('results-screen'),
        questions: _activeQuestions,
        chosenAnswers: _selectedAnswers,
        bestPercentage: _bestPercentage,
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        onRestart: _restartQuiz,
        onReturnHome: _returnHome,
      );
    }

    return MaterialApp(
      title: 'Bivio Quiz',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          // Full-screen blue gradient backdrop shared across all screens.
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D47A1),
                Color(0xFF1976D2),
                Color(0xFF42A5F5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: screenWidget,
          ),
        ),
      ),
    );
  }
}
