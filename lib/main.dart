import 'package:flutter/material.dart';
import 'package:bivio_quiz/quiz.dart';

/// Application entry point for Bivio Quiz.
///
/// Launches the root [Quiz] widget, which owns app-level state, dynamic
/// question loading, local history persistence, and screen transitions.
void main() {
  runApp(const Quiz());
}
