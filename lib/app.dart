import 'package:flutter/material.dart';
import 'package:gplx/core/routes/app_routes.dart';

/// Define routers, themes
class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ôn thi GPLX B2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
