import 'package:bivio_quiz/models/quiz_question.dart';

/// Fallback in-memory question bank used if loading `assets/data/questions.json`
/// ever fails (for example, in stripped test environments).
///
/// Primary question loading happens dynamically in [QuestionRepository].
const List<QuizQuestion> fallbackQuestions = [
  QuizQuestion(
    text: 'What are the main building blocks of Flutter UIs?',
    answers: [
      'Widgets',
      'Components',
      'Blocks',
      'Functions',
    ],
    category: 'Flutter Basics',
    difficulty: 'Easy',
    explanation:
        'Everything in a Flutter UI is built by composing immutable Widget objects.',
  ),
  QuizQuestion(
    text: 'How are Flutter UIs built?',
    answers: [
      'By combining widgets in code',
      'By combining widgets in a visual editor',
      'By defining widgets in config files',
      'By using XCode for iOS and Android Studio for Android',
    ],
    category: 'Flutter Basics',
    difficulty: 'Easy',
    explanation:
        'Flutter uses a declarative UI model where you compose nested widget trees directly in Dart code.',
  ),
  QuizQuestion(
    text: 'What is the purpose of a StatefulWidget?',
    answers: [
      'Update UI as data changes',
      'Update data as UI changes',
      'Ignore data changes',
      'Render UI that does not depend on data',
    ],
    category: 'State Management',
    difficulty: 'Easy',
    explanation:
        'A StatefulWidget pairs an immutable widget with a mutable State object that triggers rebuilds when data changes.',
  ),
  QuizQuestion(
    text:
        'Which widget should you try to use more often: StatelessWidget or StatefulWidget?',
    answers: [
      'StatelessWidget',
      'StatefulWidget',
      'Both are equally good',
      'None of the above',
    ],
    category: 'Flutter Basics',
    difficulty: 'Medium',
    explanation:
        'StatelessWidgets are simpler and lighter whenever a widget does not manage mutable local state.',
  ),
  QuizQuestion(
    text: 'What happens if you change data in a StatelessWidget?',
    answers: [
      'The UI is not updated',
      'The UI is updated',
      'The closest StatefulWidget is updated',
      'Any nested StatefulWidgets are updated',
    ],
    category: 'State Management',
    difficulty: 'Medium',
    explanation:
        'StatelessWidgets have no State object or setState() method, so mutating fields does not rebuild the UI.',
  ),
  QuizQuestion(
    text: 'How should you update local state inside a StatefulWidget?',
    answers: [
      'By calling setState()',
      'By calling updateData()',
      'By calling updateUI()',
      'By calling updateState()',
    ],
    category: 'State Management',
    difficulty: 'Easy',
    explanation:
        'Calling setState() tells Flutter that state changed so it schedules a rebuild of the widget subtree.',
  ),
];
