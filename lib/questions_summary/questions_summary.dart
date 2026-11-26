import 'package:flutter/material.dart';
import 'package:bivio_quiz/questions_summary/summary_item.dart';

/// Scrollable list of [SummaryItem] widgets shown on [ResultsScreen].
///
/// Wrapped in a bounded [SizedBox] + [SingleChildScrollView] so long quizzes
/// with answer explanations remain comfortably scrollable on every screen size.
class QuestionsSummary extends StatelessWidget {
  const QuestionsSummary(this.summaryData, {super.key});

  /// Ordered per-question breakdown maps prepared by [ResultsScreen].
  final List<Map<String, Object>> summaryData;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: SingleChildScrollView(
        child: Column(
          children: summaryData.map((data) => SummaryItem(data)).toList(),
        ),
      ),
    );
  }
}
