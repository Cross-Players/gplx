import 'package:flutter/material.dart';
import 'package:gplx/features/home/presentation/screens/home_screen.dart';
import 'package:gplx/features/settings/presentation/screens/settings_screen.dart';
import 'package:gplx/features/signs/presentation/screens/traffic_signs_screen.dart';
import 'package:gplx/features/test_sets/views/test_sets_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String settings = '/settings';
  static const String testSets = '/test-sets';
  static const String test = '/test';
  static const String signs = '/signs';
  static const String quiz = '/quiz';

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
      // case testSets:
      //   return MaterialPageRoute(
      //     builder: (_) =>  TestSetsScreen(classData: classData.classType,),
      //   );
      case signs:
        return MaterialPageRoute(
          builder: (_) => const TrafficSignsScreen(),
        );
      // case quiz:
      //   // Extract the quiz ID from route arguments
      //   final args = route.arguments as Map<String, dynamic>?;
      //   final quizId = args?['quizId'] as String? ?? 'default';

      //   return MaterialPageRoute(
      //     builder: (_) => QuizPage(quizId: quizId),
      //   );
      default:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
    }
  }
}
