import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/models/license_data.dart';
import 'package:gplx/features/test/models/question.dart';

// Provider family to load deadpoint questions for a specific license type
final deadpointQuestionsForLicenseProvider =
    FutureProvider.autoDispose.family<List<Question>, LicenseType>(
  (ref, licenseType) async {
    final String prefix;
    if (licenseType == LicenseType.A1 ||
        licenseType == LicenseType.A ||
        licenseType == LicenseType.B1) {
      prefix = licenseType.name;
    } else {
      prefix = 'overall';
    }

    try {
      final assetPath = 'assets/question_data/${prefix}_deadpoint.json';
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);

      // Extract questions array from the JSON object
      final List<dynamic> jsonList = jsonData['questions'] as List<dynamic>;

      final questions = jsonList
          .map((json) => Question.fromJson(json as Map<String, dynamic>))
          .toList();

      return questions;
    } catch (e) {
      debugPrint('Error loading deadpoint questions: $e');
      return [];
    }
  },
);

// Provider to load deadpoint questions based on current license type
final deadpointQuestionsProvider =
    FutureProvider.autoDispose<List<Question>>((ref) async {
  final licenseType = ref.watch(licenseTypeProvider);
  return ref.watch(deadpointQuestionsForLicenseProvider(licenseType).future);
});

// Provider to get count of deadpoint questions for current license type
final deadpointQuestionsCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final questions = await ref.watch(deadpointQuestionsProvider.future);
  return questions.length;
});
