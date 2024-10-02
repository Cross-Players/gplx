import 'package:flutter/material.dart';

class LoaddingView extends StatelessWidget {
  const LoaddingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator.adaptive();
  }
}
