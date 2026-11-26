import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bivio_quiz/answer_button.dart';
import 'package:bivio_quiz/models/quiz_question.dart';

/// Interactive quiz screen displaying one question at a time.
///
/// Features included:
/// - Progress header (`Question X of N`) + animated [LinearProgressIndicator]
/// - Optional 20-second per-question countdown timer
/// - Instant green/red answer feedback for 650ms before auto-advancing
/// - Optional haptic & system click sound feedback
/// - Cached shuffled answer order per question so options stay stable on rebuilds
class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({
    super.key,
    required this.questions,
    required this.onSelectAnswer,
    required this.onReturnHome,
    required this.timerEnabled,
    required this.soundEnabled,
    this.secondsPerQuestion = 20,
  });

  /// Filtered list of questions for the active quiz session.
  final List<QuizQuestion> questions;

  /// Callback invoked after feedback completes to record the user's answer.
  final void Function(String answer) onSelectAnswer;

  /// Callback to exit the active session and return to [StartScreen].
  final void Function() onReturnHome;

  /// Enables or disables the per-question countdown timer.
  final bool timerEnabled;

  /// Enables or disables haptic feedback and system click sounds.
  final bool soundEnabled;

  /// Number of seconds allotted per question when [timerEnabled] is true.
  final int secondsPerQuestion;

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  /// Sentinel answer recorded when the countdown timer reaches zero.
  static const String _timedOutLabel = "Time's up (No answer)";

  /// Duration to show green/red answer feedback before moving on.
  static const Duration _feedbackDuration = Duration(milliseconds: 650);

  /// Zero-based index of the question currently shown.
  int _currentQuestionIndex = 0;

  /// Cached shuffled answers for the current question so timer ticks do not reshuffle.
  late List<String> _shuffledAnswers;

  /// Answer tapped by the user (or [_timedOutLabel]) while feedback is active.
  String? _selectedAnswer;

  /// Locks input during the 650ms feedback delay to prevent double-taps.
  bool _isLocked = false;

  /// Remaining seconds on the countdown timer for the current question.
  late int _remainingSeconds;

  /// Periodic timer driving the per-question countdown.
  Timer? _countdownTimer;

  /// One-shot timer driving the delay after instant answer feedback.
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    _prepareCurrentQuestion();
  }

  @override
  void dispose() {
    // Always cancel timers to avoid setState-after-dispose errors.
    _countdownTimer?.cancel();
    _advanceTimer?.cancel();
    super.dispose();
  }

  /// Shuffles answers for [_currentQuestionIndex], resets feedback state,
  /// and starts the countdown timer if enabled.
  void _prepareCurrentQuestion() {
    _countdownTimer?.cancel();
    _advanceTimer?.cancel();

    _shuffledAnswers =
        widget.questions[_currentQuestionIndex].getShuffledAnswers();
    _selectedAnswer = null;
    _isLocked = false;
    _remainingSeconds = widget.secondsPerQuestion;

    if (widget.timerEnabled) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_remainingSeconds <= 1) {
          timer.cancel();
          _handleAnswer(_timedOutLabel);
        } else {
          setState(() {
            _remainingSeconds--;
          });
        }
      });
    }
  }

  /// Plays light/medium haptics and a subtle system click when [soundEnabled] is on.
  void _playFeedback({required bool isCorrect}) {
    if (!widget.soundEnabled) return;
    if (isCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
    SystemSound.play(SystemSoundType.click);
  }

  /// Handles user tap (or timer expiration), highlights the answer, and
  /// advances to the next question after [_feedbackDuration].
  void _handleAnswer(String chosenAnswer) {
    if (_isLocked) return;

    _countdownTimer?.cancel();
    final currentQuestion = widget.questions[_currentQuestionIndex];
    final isCorrect = chosenAnswer == currentQuestion.correctAnswer;

    _playFeedback(isCorrect: isCorrect);

    setState(() {
      _selectedAnswer = chosenAnswer;
      _isLocked = true;
    });

    _advanceTimer = Timer(_feedbackDuration, () {
      if (!mounted) return;

      widget.onSelectAnswer(chosenAnswer);

      // Only advance locally if more questions remain; otherwise Quiz switches
      // to ResultsScreen upon receiving the final answer.
      if (_currentQuestionIndex < widget.questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _prepareCurrentQuestion();
        });
      }
    });
  }

  /// Determines the visual [AnswerButtonState] for each option during feedback.
  AnswerButtonState _buttonStateFor(String answer, String correctAnswer) {
    if (_selectedAnswer == null) {
      return AnswerButtonState.idle;
    }
    if (answer == correctAnswer) {
      return AnswerButtonState.correct;
    }
    if (answer == _selectedAnswer) {
      return AnswerButtonState.wrong;
    }
    return AnswerButtonState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.questions[_currentQuestionIndex];
    final totalQuestions = widget.questions.length;
    final progress = (_currentQuestionIndex + 1) / totalQuestions;
    final isLowTime = widget.timerEnabled && _remainingSeconds <= 5;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top metadata bar: Home exit button, Question X of N, and optional timer.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: widget.onReturnHome,
                      tooltip: 'Back to Home',
                      icon: const Icon(
                        Icons.home_outlined,
                        color: Color(0xFFF8FAE5),
                      ),
                    ),
                    Text(
                      'Question ${_currentQuestionIndex + 1} of $totalQuestions',
                      style: GoogleFonts.lato(
                        color: const Color(0xFFF8FAE5),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.timerEnabled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isLowTime
                              ? const Color(0xFFC62828)
                              : Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_remainingSeconds}s',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Spacer keeps the question counter centered when timer is off.
                      const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 10),

                // Linear progress bar visualizing quiz completion progress.
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF69F0AE),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category & Difficulty badge for the current question.
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${currentQuestion.category} • ${currentQuestion.difficulty}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Question prompt in Lato font.
                Text(
                  currentQuestion.text,
                  style: GoogleFonts.lato(
                    color: const Color(0xFFF8FAE5),
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Shuffled answer buttons with instant green/red feedback states.
                ..._shuffledAnswers.map((answer) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: AnswerButton(
                      answerText: answer,
                      feedbackState: _buttonStateFor(
                        answer,
                        currentQuestion.correctAnswer,
                      ),
                      onTap: _isLocked ? null : () => _handleAnswer(answer),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
