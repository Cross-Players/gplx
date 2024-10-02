import 'package:flutter/material.dart';

/// Declare static keys of the app such as navigator key, widget key
class AppKeys {
  AppKeys._();

  //============================================================
  //  Global keys
  //============================================================

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static GlobalKey<ScaffoldMessengerState> snackBarKey =
      GlobalKey<ScaffoldMessengerState>();
  //============================================================
  //  Widget keys
  //============================================================

  // Home
  static const Key loginScreen = Key('loginScreen');
  static const Key homeScreen = Key('loginScreen');
}
