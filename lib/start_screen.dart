import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bivio_quiz/models/quiz_attempt.dart';

/// Landing screen for Bivio Quiz.
///
/// Displays the Bivio logo, title, best score badge, quiz history button,
/// category and difficulty filters, timer/sound toggles, and the Start Quiz CTA.
class StartScreen extends StatelessWidget {
  const StartScreen({
    super.key,
    required this.onStartQuiz,
    required this.categories,
    required this.difficulties,
    required this.selectedCategory,
    required this.selectedDifficulty,
    required this.onCategoryChanged,
    required this.onDifficultyChanged,
    required this.matchingQuestionCount,
    required this.timerEnabled,
    required this.onTimerToggled,
    required this.soundEnabled,
    required this.onSoundToggled,
    required this.bestPercentage,
    required this.history,
    required this.onClearHistory,
  });

  /// Starts the quiz with the currently selected filters and toggles.
  final void Function() onStartQuiz;

  /// Available category filter labels (always starts with `'All'`).
  final List<String> categories;

  /// Available difficulty filter labels (`'All'`, `'Easy'`, `'Medium'`, `'Hard'`).
  final List<String> difficulties;

  /// Currently selected category filter.
  final String selectedCategory;

  /// Currently selected difficulty filter.
  final String selectedDifficulty;

  /// Called when the user selects a new category chip.
  final void Function(String category) onCategoryChanged;

  /// Called when the user selects a new difficulty chip.
  final void Function(String difficulty) onDifficultyChanged;

  /// Number of questions matching the active category + difficulty filter.
  final int matchingQuestionCount;

  /// Whether the per-question countdown timer is enabled.
  final bool timerEnabled;

  /// Called when the user toggles the countdown timer switch.
  final void Function(bool enabled) onTimerToggled;

  /// Whether sound/haptic feedback is enabled.
  final bool soundEnabled;

  /// Called when the user toggles sound & haptics.
  final void Function(bool enabled) onSoundToggled;

  /// Highest percentage score persisted across past quiz attempts.
  final int bestPercentage;

  /// Chronological list (newest first) of past quiz attempts.
  final List<QuizAttempt> history;

  /// Clears saved quiz history and resets the best score.
  final Future<void> Function() onClearHistory;

  /// Opens a modal bottom sheet displaying past quiz attempts and a Clear button.
  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0A2463),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quiz History',
                      style: GoogleFonts.lato(
                        color: const Color(0xFFF8FAE5),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (history.isNotEmpty)
                      TextButton.icon(
                        onPressed: () async {
                          await onClearHistory();
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF8A80),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No attempts yet. Complete a quiz to see your score history here!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: history.length,
                      separatorBuilder: (_, _) =>
                          const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (_, index) {
                        final attempt = history[index];
                        final dateLabel =
                            '${attempt.timestamp.year}-${attempt.timestamp.month.toString().padLeft(2, '0')}-${attempt.timestamp.day.toString().padLeft(2, '0')} '
                            '${attempt.timestamp.hour.toString().padLeft(2, '0')}:${attempt.timestamp.minute.toString().padLeft(2, '0')}';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: attempt.percentage >= 70
                                ? const Color(0xFF69F0AE)
                                : const Color(0xFFFF8A80),
                            child: Text(
                              '${attempt.percentage}%',
                              style: const TextStyle(
                                color: Color(0xFF0A2463),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            '${attempt.score} / ${attempt.totalQuestions} correct',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${attempt.category} • ${attempt.difficulty} • $dateLabel',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds a reusable horizontal Wrap of filter chips for category or difficulty.
  ///
  /// Uses solid royal blue (`#1565C0`) for unselected chips and warm cream
  /// (`#F8FAE5`) with deep navy (`#0A2463`) text for the selected chip so both
  /// states stay high-contrast and legible over the blue gradient background.
  Widget _buildChipGroup({
    required String label,
    required List<String> options,
    required String selectedValue,
    required void Function(String value) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFF8FAE5),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onSelected(option),
              // High-contrast warm cream pill when selected; solid royal blue when idle.
              selectedColor: const Color(0xFFF8FAE5),
              backgroundColor: const Color(0xFF1565C0),
              surfaceTintColor: Colors.transparent,
              checkmarkColor: const Color(0xFF0A2463),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF0A2463) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFFF8FAE5)
                    : const Color(0xFF90CAF9),
                width: isSelected ? 1.5 : 1.0,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canStart = matchingQuestionCount > 0;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top bar showing persisted best score badge and history trigger.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_outlined,
                            color: Color(0xFFF8FAE5),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            bestPercentage > 0
                                ? 'Best: $bestPercentage%'
                                : 'Best: --',
                            style: const TextStyle(
                              color: Color(0xFFF8FAE5),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showHistorySheet(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFF8FAE5),
                      ),
                      icon: const Icon(Icons.history, size: 18),
                      label: Text('History (${history.length})'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bivio brand image used throughout the quiz app and PDF reports.
                Image.asset(
                  'assets/images/bivio.jpeg',
                  width: 210,
                ),
                const SizedBox(height: 24),

                // Main headline in warm cream (#F8FAE5).
                Text(
                  'Learn Bivio easy way',
                  style: GoogleFonts.lato(
                    color: const Color(0xFFF8FAE5),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Category filter selector.
                _buildChipGroup(
                  label: 'CATEGORY',
                  options: categories,
                  selectedValue: selectedCategory,
                  onSelected: onCategoryChanged,
                ),
                const SizedBox(height: 16),

                // Difficulty filter selector.
                _buildChipGroup(
                  label: 'DIFFICULTY',
                  options: difficulties,
                  selectedValue: selectedDifficulty,
                  onSelected: onDifficultyChanged,
                ),
                const SizedBox(height: 18),

                // Compact settings strip for optional 20s timer and sound/haptics.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Wrap(
                    spacing: 16,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: Color(0xFFF8FAE5),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '20s Timer',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          Switch(
                            value: timerEnabled,
                            onChanged: onTimerToggled,
                            activeThumbColor: const Color(0xFF69F0AE),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.volume_up_outlined,
                            color: Color(0xFFF8FAE5),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Haptics & Sound',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          Switch(
                            value: soundEnabled,
                            onChanged: onSoundToggled,
                            activeThumbColor: const Color(0xFF69F0AE),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Primary Start Quiz button showing the filtered question count.
                OutlinedButton.icon(
                  onPressed: canStart ? onStartQuiz : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF8FAE5),
                    disabledForegroundColor: Colors.white38,
                    side: BorderSide(
                      color: canStart
                          ? const Color(0xFFF8FAE5)
                          : Colors.white30,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_right_alt),
                  label: Text(
                    canStart
                        ? 'Start Quiz ($matchingQuestionCount questions)'
                        : 'No matching questions',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
