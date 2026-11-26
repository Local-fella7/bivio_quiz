import 'package:flutter/material.dart';

/// Visual feedback states for an [AnswerButton].
///
/// - [idle]: Default deep-navy pill button before the user answers.
/// - [correct]: Highlighted green when this choice is the correct answer.
/// - [wrong]: Highlighted red when the user picked this incorrect choice.
/// - [dimmed]: Slightly faded for unselected options while feedback is shown.
enum AnswerButtonState {
  idle,
  correct,
  wrong,
  dimmed,
}

/// Reusable pill-shaped answer choice button styled for the blue gradient theme.
///
/// Supports instant visual feedback by smoothly transitioning its background
/// color and showing a check or close icon based on [feedbackState].
class AnswerButton extends StatelessWidget {
  const AnswerButton({
    super.key,
    required this.answerText,
    required this.onTap,
    this.feedbackState = AnswerButtonState.idle,
  });

  /// The text label displayed inside the button.
  final String answerText;

  /// Callback invoked when the user taps this answer (null disables taps).
  final void Function()? onTap;

  /// Current visual feedback state used during the brief post-tap highlight.
  final AnswerButtonState feedbackState;

  /// Resolves the pill background color for the current [feedbackState].
  Color get _backgroundColor {
    switch (feedbackState) {
      case AnswerButtonState.correct:
        return const Color(0xFF2E7D32); // Rich emerald green for correct answer
      case AnswerButtonState.wrong:
        return const Color(0xFFC62828); // Clear crimson red for wrong selection
      case AnswerButtonState.dimmed:
        return const Color(0x880A2463); // Semi-transparent navy when dimmed
      case AnswerButtonState.idle:
        return const Color(0xFF0A2463); // Deep navy blue matching blue gradient
    }
  }

  /// Resolves an optional trailing status icon when feedback is active.
  IconData? get _statusIcon {
    switch (feedbackState) {
      case AnswerButtonState.correct:
        return Icons.check_circle_outline;
      case AnswerButtonState.wrong:
        return Icons.cancel_outlined;
      case AnswerButtonState.idle:
      case AnswerButtonState.dimmed:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _statusIcon;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: feedbackState == AnswerButtonState.correct
              ? const Color(0xFF69F0AE)
              : feedbackState == AnswerButtonState.wrong
                  ? const Color(0xFFFF8A80)
                  : Colors.white24,
          width: feedbackState == AnswerButtonState.idle ? 1 : 1.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // InkWell provides a crisp ripple clipped to the pill border radius.
          borderRadius: BorderRadius.circular(40),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 24,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    answerText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 10),
                  Icon(icon, color: Colors.white, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
