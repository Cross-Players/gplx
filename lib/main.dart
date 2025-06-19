import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/app.dart';
import 'package:gplx/core/services/cache_expiry_manager.dart';
import 'package:gplx/firebase_options.dart';

Future<void> main() async {
  // Keep splash screen up until app is fully loaded
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize services in parallel
    await Future.wait([
      CacheExpiryManager.cleanExpiredCache(),
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      // Add other initialization here if needed
    ]);

    runApp(const ProviderScope(child: App()));
  } catch (e) {
    print('Error during initialization: $e');
  } finally {
    // Remove splash screen when initialization is complete
    FlutterNativeSplash.remove();
  }
}
