import 'package:flutter/material.dart';
import 'package:gplx/core/constants/app_styles.dart';

class PrimaryButton extends StatelessWidget {
  final String content;
  final void Function()? onPressed;

  const PrimaryButton({
    super.key,
    required this.content,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppPalette.heroGradient,
          borderRadius: BorderRadius.circular(AppPalette.radiusM),
          boxShadow: enabled ? AppPalette.softShadow(AppPalette.primary) : null,
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
            ),
            onPressed: onPressed,
            child: Text(content),
          ),
        ),
      ),
    );
  }
}
