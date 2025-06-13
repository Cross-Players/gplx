import 'package:flutter/material.dart';
import 'package:gplx/core/services/firebase/auth_sevices.dart';
import 'package:gplx/features/home/presentation/screens/home_screen.dart';
import 'package:gplx/features/login/app_loading_page.dart';
import 'package:gplx/features/login/login_page.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, this.pageIfNotConnected});

  final Widget? pageIfNotConnected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: authServices,
        builder: (context, authSevices, child) {
          return StreamBuilder(
              stream: authSevices.authStateChanges,
              builder: (context, snapshot) {
                Widget widget;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  widget = const AppLoadingPage();
                } else if (snapshot.hasData) {
                  widget = const HomeScreen();
                } else {
                  widget = pageIfNotConnected ?? const LoginPage();
                }
                return widget;
              });
        });
  }
}
