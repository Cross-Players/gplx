import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gplx/features/test/models/license_data.dart';
import 'package:gplx/features/test/models/question.dart';

class TestController {
  /// Convert special license types to the unified Firebase path
  String _getActualLicenseType(LicenseType licenseType) {
    final specialLicenses = [
      LicenseType.D1,
      LicenseType.D2,
      LicenseType.D,
      LicenseType.BE,
      LicenseType.C1E,
      LicenseType.CE,
      LicenseType.D1E,
      LicenseType.D2E,
      LicenseType.DE,
    ];
    return specialLicenses.contains(licenseType)
        ? 'D1_D2_D_BE_C1E_CE_D1E_D2E_DE'
        : licenseType.name;
  }

  Future<List<Question>> fetchQuestionsByTestSets(
    LicenseType licenseType,
    int testNumber,
  ) async {
    // Check if licenseType is one of the special licenses
    final actualLicenseType = _getActualLicenseType(licenseType);

    debugPrint('🔍 Original license: $licenseType, Using: $actualLicenseType');

    // Firebase path: A/0/questions/ (testNumber - 1 because Firebase is 0-indexed)
    final database = FirebaseDatabase.instance
        .ref(actualLicenseType)
        .child((testNumber - 1).toString())
        .child('questions');

    debugPrint('🔍 Fetching questions for license: $licenseType, test: $testNumber');
    try {
      final snapshot = await database.get();
      if (snapshot.exists) {
        final data = snapshot.value;
        debugPrint('📊 Raw data type: ${data.runtimeType}');
        debugPrint(
          '📊 Raw data length: ${data is List ? data.length : (data is Map ? (data).length : 'unknown')}',
        );
        List<Question> questions = [];

        if (data is List) {
          // Handle data as List<Object?>
          for (int i = 0; i < data.length; i++) {
            try {
              if (data[i] == null) {
                continue;
              }
              final rawData = Map<String, dynamic>.from(data[i] as Map);
              debugPrint(
                '📋 Processing question ${i + 1}: ${rawData['question_content']?.toString() ?? 'No content'}...',
              );
              final normalizedData = _normalizeQuestionData(rawData);
              final question = Question.fromJson(normalizedData);
              questions.add(question);
              debugPrint('✅ Successfully parsed question ${i + 1}');
            } catch (e) {
              debugPrint('❌ Error processing question ${i + 1}: $e');
              continue; // Skip this question and continue with others
            }
          }
        } else {
          debugPrint('⚠️ Unexpected data type: ${data.runtimeType}');
        }

        debugPrint(
          '📈 Fetched ${questions.length} questions for test set $testNumber of license $licenseType',
        );
        return questions;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Fetch all dead point questions (questions with question_dead_point = true) for a license type
  Future<List<Question>> fetchDeadPointQuestions(
      LicenseType licenseType) async {
    // Check if licenseType is one of the special licenses
    final actualLicenseType = _getActualLicenseType(licenseType);

    debugPrint('💀 Fetching dead point questions for license: $licenseType');
    debugPrint('💀 Using actual license type: $actualLicenseType');
    try {
      final database = FirebaseDatabase.instance.ref(actualLicenseType);
      final snapshot = await database.limitToFirst(10).orderByKey().get();

      if (!snapshot.exists) {
        debugPrint('❌ No data exists for license: $licenseType');
        return [];
      }

      final data = snapshot.value;
      debugPrint('📊 Dead point raw data type: ${data.runtimeType}');
      List<Question> deadPointQuestions = [];

      if (data is List) {
        // Handle data as List (test sets)
        for (int testIndex = 0; testIndex < data.length; testIndex++) {
          if (data[testIndex] == null) continue;

          final testData = data[testIndex] as Map;
          if (testData['questions'] != null && testData['questions'] is List) {
            final questions = testData['questions'] as List;

            for (int questionIndex = 0;
                questionIndex < questions.length;
                questionIndex++) {
              if (questions[questionIndex] == null) continue;

              try {
                final rawQuestion = Map<String, dynamic>.from(
                  questions[questionIndex] as Map,
                );
                debugPrint(
                  '🔍 Checking question ${questionIndex + 1} in test ${testIndex + 1}: ${rawQuestion['question_content']?.toString() ?? 'No content'}...',
                );
                final normalizedData = _normalizeQuestionData(rawQuestion);
                final question = Question.fromJson(normalizedData);

                // Only add questions where isDeadPoint is true
                if (question.isDeadPoint == true) {
                  debugPrint('💀 Found dead point question: ${question.content}...');
                  deadPointQuestions.add(question);
                } else {
                  debugPrint(
                    '📝 Regular question (not dead point): ${question.content}...',
                  );
                }
              } catch (e) {
                // Skip invalid questions
                continue;
              }
            }
          }
        }
      }
      debugPrint(
        '💀 Total dead point questions found for license $licenseType: ${deadPointQuestions.length}',
      );

      // Remove duplicates based on question content
      final uniqueDeadPointQuestions = _removeDuplicateQuestions(
        deadPointQuestions,
      );
      debugPrint(
        '🔄 After removing duplicates: ${uniqueDeadPointQuestions.length} unique dead point questions',
      );

      return uniqueDeadPointQuestions;
    } catch (e) {
      return [];
    }
  }

  /// Normalize Firebase data to match our model expectations
  Map<String, dynamic> _normalizeQuestionData(Map<String, dynamic> rawData) {
    final normalized = <String, dynamic>{};

    // Convert all potential string fields to strings, handling nulls and different types
    normalized['question_content'] = rawData['question_content']?.toString();
    normalized['question_number'] = rawData['question_number'] is int
        ? rawData['question_number']
        : int.tryParse(rawData['question_number']?.toString() ?? '0') ?? 0;
    normalized['question_chapter'] = rawData['question_chapter']?.toString();
    normalized['driving_license_level'] =
        rawData['driving_license_level']?.toString();
    normalized['question_image'] = rawData['question_image']?.toString();

    // Handle question_dead_point
    normalized['question_dead_point'] = rawData['question_dead_point'] == true;
    if (rawData['question_dead_point'] != null) {
      debugPrint('🎯 Question dead point: ${rawData['question_dead_point']}');
    }

    // Handle answers array - ensure proper structure
    if (rawData['answers'] is List) {
      final answers = rawData['answers'] as List;
      normalized['answers'] = answers.map((answer) {
        if (answer is Map) {
          return {
            'answer_content': answer['answer_content']?.toString() ?? '',
            'is_correct':
                answer['is_correct'] == true || answer['is_correct'] == 'true',
          };
        }
        return answer;
      }).toList();
    } else {
      normalized['answers'] = [];
    }
    return normalized;
  }

  /// Remove duplicate questions based on question number only
  List<Question> _removeDuplicateQuestions(List<Question> questions) {
    final seenNumbers = <int>{};
    final uniqueQuestions = <Question>[];

    for (final question in questions) {
      final questionNumber = question.number ?? 0;

      if (!seenNumbers.contains(questionNumber)) {
        seenNumbers.add(questionNumber);
        uniqueQuestions.add(question);
        debugPrint(
          '✅ Added unique dead point question #$questionNumber: ${question.content}...',
        );
      } else {
        debugPrint(
          '🔄 Skipped duplicate question #$questionNumber: ${question.content}...',
        );
      }
    }

    return uniqueQuestions;
  }
}
