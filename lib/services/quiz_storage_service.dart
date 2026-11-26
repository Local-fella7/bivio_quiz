import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bivio_quiz/models/quiz_attempt.dart';

/// Persistence service backed by `shared_preferences` for storing the user's
/// best score percentage and recent quiz attempt history locally on the device.
class QuizStorageService {
  /// Storage key for the serialized list of [QuizAttempt] JSON strings.
  static const String _historyKey = 'bivio_quiz_history';

  /// Storage key for the highest percentage score achieved so far.
  static const String _bestScoreKey = 'bivio_quiz_best_percentage';

  /// Maximum number of recent attempts kept in local storage.
  static const int _maxHistoryEntries = 20;

  /// Reads the saved quiz attempt history (newest first).
  Future<List<QuizAttempt>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_historyKey) ?? [];

    return rawList.map((raw) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return QuizAttempt.fromJson(map);
    }).toList();
  }

  /// Reads the highest percentage score recorded across all attempts.
  Future<int> loadBestPercentage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestScoreKey) ?? 0;
  }

  /// Saves a newly completed [attempt] to the front of the history list and
  /// updates the stored best percentage if this attempt sets a new record.
  ///
  /// Returns the updated best percentage.
  Future<int> saveAttempt(QuizAttempt attempt) async {
    final prefs = await SharedPreferences.getInstance();

    // Prepend the new attempt and trim to [_maxHistoryEntries].
    final existing = await loadHistory();
    final updatedHistory = [attempt, ...existing].take(_maxHistoryEntries);
    final encoded = updatedHistory.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_historyKey, encoded);

    // Update the high score if the new attempt beats the current record.
    final currentBest = prefs.getInt(_bestScoreKey) ?? 0;
    final newBest =
        attempt.percentage > currentBest ? attempt.percentage : currentBest;
    await prefs.setInt(_bestScoreKey, newBest);

    return newBest;
  }

  /// Clears all saved history entries and resets the stored best percentage.
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    await prefs.remove(_bestScoreKey);
  }
}
