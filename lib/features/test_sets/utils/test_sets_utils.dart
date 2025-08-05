import 'package:flutter/material.dart';
import 'package:gplx/features/test_sets/constants/test_sets_constants.dart';

/// Utility class for test sets operations
class TestSetsUtils {
  /// Get responsive grid columns based on screen width
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return TestSetsConstants.mobileGridColumns;
    return TestSetsConstants.desktopGridColumns;
  }

  /// Format test set ID with leading zeros
  static String formatTestSetId(int index, String vehicleType) {
    final formattedIndex = (index + 1).toString().padLeft(2, '0');
    return '$formattedIndex-$vehicleType';
  }

  /// Show loading snackbar
  static void showLoadingSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: TestSetsConstants.loadingSnackBarDuration,
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: TestSetsConstants.successSnackBarDuration,
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Convert selected answers map from String keys to int keys
  static Map<int, int> convertSelectedAnswers(
      Map<String, int>? selectedAnswers) {
    final converted = <int, int>{};
    selectedAnswers?.forEach((key, value) {
      converted[int.parse(key)] = value;
    });
    return converted;
  }
}
