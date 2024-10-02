import 'package:gh247_user/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize some services like firebase

  runApp(const ProviderScope(child: App()));
}
