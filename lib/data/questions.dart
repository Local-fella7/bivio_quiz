import 'package:bivio_quiz/models/quiz_question.dart';

/// Fallback in-memory question bank used if loading `lib/data/bivio-quiz.json`
/// ever fails (for example, in stripped test environments).
///
/// Primary question loading happens dynamically in [QuestionRepository].
const List<QuizQuestion> fallbackQuestions = [
  QuizQuestion(
    text: 'What determines which screens and actions are available to you in Bivio?',
    answers: [
      'Your company configuration and your assigned role',
      'Your browser type and screen size',
      'The time of day and your physical location',
      'Your subscription price and device model',
    ],
    category: 'Essentials & Access',
    difficulty: 'Easy',
    explanation:
        'Your company configuration and role determine which screens and actions appear.',
  ),
  QuizQuestion(
    text: 'How do you sign in to Quick View (waiter PIN login)?',
    answers: [
      'Company code and a 4-digit PIN',
      'Email address and password',
      'Table number and waiter name',
      'QR token and bill number',
    ],
    category: 'Essentials & Access',
    difficulty: 'Easy',
    explanation:
        'Quick View uses a company code plus a 4-digit PIN entered on the on-screen keypad.',
  ),
  QuizQuestion(
    text: 'What must happen to an order before it can be turned into a bill?',
    answers: [
      'It must be closed / approved',
      'It must be cancelled',
      'It must be paid',
      'It must be printed',
    ],
    category: 'Sales, Orders & Bills',
    difficulty: 'Easy',
    explanation:
        'Only closed/approved orders are eligible for billing; saving an Open order is not enough.',
  ),
  QuizQuestion(
    text: 'What is the difference between a purchase and a delivery?',
    answers: [
      'A purchase records supplier/cost; a delivery records actual receipt',
      'They are the same transaction',
      'A delivery happens before a purchase',
      'A purchase updates stock directly',
    ],
    category: 'Inventory & Purchasing',
    difficulty: 'Easy',
    explanation:
        'Purchases record what was bought from which supplier; deliveries record what actually arrived.',
  ),
  QuizQuestion(
    text: 'How do PIN sessions affect the password-change prompt in Quick Mode?',
    answers: [
      'They bypass password-change prompts and cannot open the change-password page',
      'They must change their password before taking orders',
      'They are logged out every hour',
      'They require email sign-in for every order',
    ],
    category: 'Quick Mode',
    difficulty: 'Medium',
    explanation:
        'PIN sessions bypass password-change prompts and cannot open the change-password page.',
  ),
  QuizQuestion(
    text: 'Why might a button in Bivio be disabled?',
    answers: [
      'Your role or the record\'s status does not allow the action',
      'Your browser zoom level',
      'The network speed',
      'The screen size',
    ],
    category: 'Troubleshooting',
    difficulty: 'Easy',
    explanation:
        'A button may be hidden or disabled when your role or the record status does not allow the action.',
  ),
];
