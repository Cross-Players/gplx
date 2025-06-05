import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/app.dart';
import 'package:gplx/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize some services like firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: App()));
}
