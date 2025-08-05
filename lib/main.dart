import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize some services like firebase

  runApp(const ProviderScope(child: App()));
}
