import 'package:flutter/material.dart';
import 'package:gplx/features/exercise/views/all_chapter_screen.dart';
import 'package:gplx/features/exercise/views/exercise_screen.dart';
import 'package:gplx/features/home/presentation/screens/home_screen.dart';
import 'package:gplx/features/login/login_page.dart';
import 'package:gplx/features/settings/presentation/screens/settings_screen.dart';
import 'package:gplx/features/signs/presentation/screens/traffic_signs_screen.dart';
import 'package:gplx/features/test/views/quiz_screen.dart';
import 'package:gplx/features/test_sets/views/test_sets_screen.dart';
import 'package:gplx/features/tips/presentation/screens/memorization_tips.dart';

class AppRoutes {
  static const String login = '/';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String testSets = '/test-sets';
  static const String test = '/test';
  static const String signs = '/signs';
  static const String quiz = '/quiz';
  static const String allChapters = '/all-chapters';
  static const String tips = '/tips';
  static const String wrongAnswers = '/wrong-answers';
  static const String deadpointQuestions = '/deadpoint-questions';

  static Route<dynamic> onGenerateRoute(RouteSettings route) {
    switch (route.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      case settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );
      case testSets:
        return MaterialPageRoute(
          builder: (_) => const TestSetsScreen(),
        );
      case signs:
        return MaterialPageRoute(
          builder: (_) => const TrafficSignsScreen(),
        );
      // case quiz:
      //   return MaterialPageRoute(
      //     builder: (_) => QuizPage(quizId: quizId),
      //   );
      case allChapters:
        return MaterialPageRoute(
          builder: (_) => const AllChapterScreen(),
        );
      case tips:
        return MaterialPageRoute(
          builder: (_) => const MemorizationTips(),
        );
      case deadpointQuestions:
        final testSetId = route.arguments as String;
        return MaterialPageRoute(
          builder: (context) => QuizScreen(testSetId: testSetId),
        );
      case AppRoutes.wrongAnswers:
        final args = route.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => ExerciseScreen(
            title: args['title'] as String,
            questions: Future.value(args['questions']),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
    }
  }
}
