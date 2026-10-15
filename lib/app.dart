import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/routes/app_routes.dart';
import 'package:gplx/core/theme/app_theme.dart';
import 'package:gplx/features/home/presentation/screens/home_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Ôn thi GPLX B2',
      debugShowCheckedModeBanner: false,
      // Login is disabled: everyone goes straight to the home screen.
      // To re-enable, set `home: const AuthLayout()` again.
      home: const HomeScreen(),
      theme: AppTheme.light,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
