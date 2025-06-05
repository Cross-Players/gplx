import 'package:flutter/material.dart';
import 'package:gplx/features/home/presentation/screens/home_screen.dart';
import 'package:gplx/features/settings/presentation/screens/settings_screen.dart';
import 'package:gplx/features/signs/presentation/screens/traffic_signs_screen.dart';
import 'package:gplx/features/exercise/views/all_chapter_screen.dart';
import 'package:gplx/features/test_sets/views/test_sets_screen.dart';
import 'package:gplx/features/tips/presentation/screens/memorization_tips.dart';

class AppRoutes {
  static const String home = '/';
  static const String settings = '/settings';
  static const String testSets = '/test-sets';
  static const String test = '/test';
  static const String signs = '/signs';
  static const String quiz = '/quiz';
  static const String allChapters = '/all-chapters';
  static const String tips = '/tips';

  static Route<dynamic> onGenerateRoute(RouteSettings route) {
    switch (route.name) {
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
      default:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
    }
  }
}
