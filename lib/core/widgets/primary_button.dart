import 'package:flutter/material.dart';
import 'package:gplx/core/constants/app_styles.dart';

class PrimaryButton extends StatelessWidget {
  final String content;
  final void Function()? onPressed;
  // final bool isEnabled;

  const PrimaryButton({
    super.key,
    required this.content,
    required this.onPressed,
    // required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppStyles.buttonColor,
          // isEnabled ? AppStyles.colorPrimary : AppStyles.colorDisableButton,
          padding: const EdgeInsets.symmetric(
            vertical: AppStyles.verticalSpace / 1.2,
          ),
        ),
        onPressed: onPressed,
        child: Text(
          content,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: AppStyles.fontSizeL,
            // color: isEnabled
            //     ? AppStyles.colorBackground
            //     : AppStyles.colorDisableTextButton,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
