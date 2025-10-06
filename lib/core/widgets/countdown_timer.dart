import 'package:flutter/material.dart';

class CountdownTimer extends StatelessWidget {
  final Duration duration;
  final TextStyle? textStyle;
  final VoidCallback? onTimerComplete;

  const CountdownTimer({
    super.key,
    required this.duration,
    this.textStyle,
    this.onTimerComplete,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    // Format as MM:SS
    final formattedTime =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Text(
      formattedTime,
      style: textStyle ?? const TextStyle(fontSize: 20),
    );
  }
}
