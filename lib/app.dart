import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/routes/app_routes.dart';
import 'package:gplx/features/test/providers/vehicle_provider.dart';

/// Define routers, themes
class App extends ConsumerWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load saved vehicle type when app starts
    ref.watch(loadSavedVehicleTypeProvider);
    return MaterialApp(
      title: 'Ôn thi GPLX B2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
            backgroundColor: AppStyles.primaryColor,
            foregroundColor: Colors.black,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
        tabBarTheme: const TabBarTheme(
          indicatorColor: AppStyles.primaryColor,
          labelColor: AppStyles.primaryColor,
          labelPadding: EdgeInsets.symmetric(horizontal: 16.0),
          indicatorSize: TabBarIndicatorSize.tab,
          tabAlignment: TabAlignment.start,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: AppStyles.primaryColor),
        useMaterial3: true,
      ),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
