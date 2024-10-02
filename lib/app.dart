import 'package:flutter/material.dart';
import 'package:gh247_user/core/constants/app_keys.dart';
import 'package:gh247_user/core/router/routes.dart';

/// Define routers, themes
class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Giao hang 247 User',
      navigatorKey: AppKeys.navigatorKey,
      scaffoldMessengerKey: AppKeys.snackBarKey,
      routes: Routes.routes,
      initialRoute: Routes.home,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
