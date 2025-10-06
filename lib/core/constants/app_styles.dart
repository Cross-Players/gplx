// Declare common constant style such as color, text style, dimension
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2E3B55);
  static const Color background = Color(0xFFF5F5F5);
  static const Color error = Color(0xffED5B5B);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
  static const Color blue = Color(0xFF2196F3);
  static const Color orange = Color(0xFFFF9800);
  static const Color red = Color(0xFFF44336);
  static const Color green = Color(0xFF4CAF50);
  static const Color teal = Color(0xFF009688);
  static const Color purple = Color(0xFF9C27B0);
  static const Color brown = Color(0xFF795548);
  static const Color blueGrey = Color(0xFF607D8B);
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color inputLabel = Color(0xFF757575);
  static const Color inputIcon = Color(0xFF757575);
}

class AppStyles {
  AppStyles._();

  // color
  // static const primaryColor = Color(0xff68A596);
  static const primaryColor = Color.fromRGBO(60, 134, 197, 1);
  static final secondaryColor = Colors.grey[700];
  static const bgDarkModeColor = Colors.black;
  static const bgLightModeColor = Color(0xffF6F6F6);
  static const iconDarkModeColor = Color(0xffF6F6F6);
  static const iconLightModeColor = Colors.black;
  static const errorColor = Color(0xffED5B5B);
  static const buttonColor = Color.fromRGBO(0, 122, 255, 1);
  static const fontSecondaryColor = Color.fromRGBO(82, 82, 82, 1);

  // font
  static const String notoSansJP = 'NotoSansJP';

  // font size
  static const double fontSizeS = 11;
  static const double fontSizeM = 13;
  static const double fontSizeL = 15;
  static const double fontSizeH = 20;

  // icon size
  static const double iconSizeS = 18;
  static const double iconSizeM = 24;
  static const double iconSizeL = 36;
  static const double iconSizeH = 42;

  // button size
  static const double buttonRadiusS = 10;
  static const double buttonRadiusM = 15;
  static const double buttonRadiusL = 30;
  static const double buttonBottomHeight = 50;

  // dimension
  static const double horizontalSpace = 20;
  static const double verticalSpace = 20;
  static const double gridViewSpace = 15;
  static const double listItemSpace = 8;
  static const double imageRatio = 335 / 182;

  // text style
  static const TextStyle textRegular = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: Colors.black,
  );

  static final TextStyle textMedium = textRegular.copyWith(
    fontWeight: FontWeight.w500,
  );

  static final TextStyle textBold = textRegular.copyWith(
    fontWeight: FontWeight.w700,
  );
}

// LoginPage specific styles
class AppLoginColors {
  static const Color primary = AppColors.primary;
  static const Color background = AppColors.background;
  static const Color inputFill = AppColors.background;
  static const Color inputBorder = AppColors.inputBorder;
  static const Color inputLabel = AppColors.inputLabel;
  static const Color inputIcon = AppColors.inputIcon;
  static const Color error = AppColors.error;
}

class AppLoginTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppLoginColors.primary,
  );
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );
  static const TextStyle error = TextStyle(
    color: AppLoginColors.error,
    fontSize: 14,
  );
  static const TextStyle label = TextStyle(
    color: AppLoginColors.primary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
}

class AppLoginDecorations {
  static BoxDecoration card = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.1),
        blurRadius: 10,
        spreadRadius: 5,
      ),
    ],
  );
}

class AppLoginPaddings {
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: 30);
  static const EdgeInsets card = EdgeInsets.all(20);
}

class AppHomeColors {
  static const orange = AppColors.orange;
  static const red = AppColors.red;
  static const green = AppColors.green;
  static const teal = AppColors.teal;
  static const blue = AppColors.blue;
  static const purple = AppColors.purple;
  static const brown = AppColors.brown;
  static const blueGrey = AppColors.blueGrey;
}

class AppSettingsColors {
  static const sectionBg = AppColors.background;
  static const sectionText = AppColors.grey;
  static const logoutBg = AppColors.white;
  static const logoutText = AppColors.red;
  static const logoutIcon = AppColors.red;
  static const vehicleSelected = AppColors.blue;
}

class AppSettingsTextStyles {
  static const section = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppSettingsColors.sectionText,
  );
  static const logout = TextStyle(
    color: AppSettingsColors.logoutText,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );
  static const vehicleDesc = TextStyle(fontSize: 12);
}

class AppSettingsPaddings {
  static const section = EdgeInsets.fromLTRB(16, 16, 16, 8);
  static const logout = EdgeInsets.symmetric(vertical: 10);
  static const logoutMargin = EdgeInsets.symmetric(horizontal: 16);
}
