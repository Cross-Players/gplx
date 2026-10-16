import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gplx/features/test/models/license_data.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestController {
  // In-memory cache for dead point questions (per license type)
  static final Map<String, List<Question>> _deadPointQuestionsCache = {};

  // Cache key prefix for SharedPreferences
  static const String _cacheKeyPrefix = 'dead_point_questions_';
  static const String _cacheExpiryPrefix = 'dead_point_expiry_';

  // Cache expiry duration: 7 days
  static const int _cacheDurationDays = 7;

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

    debugPrint(
        '🔍 Fetching questions for license: $licenseType, test: $testNumber');
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

  /// Load cached dead point questions from SharedPreferences
  Future<List<Question>?> _loadCachedDeadPointQuestions(
      LicenseType licenseType) async {
    try {
      // 1. Check in-memory cache first
      final cacheKey = licenseType.name;
      if (_deadPointQuestionsCache.containsKey(cacheKey)) {
        debugPrint('✅ Found in memory cache for $licenseType');
        return _deadPointQuestionsCache[cacheKey];
      }

      // 2. Check SharedPreferences cache
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('$_cacheKeyPrefix${licenseType.name}');
      final expiryTimestamp =
          prefs.getInt('$_cacheExpiryPrefix${licenseType.name}');

      if (cachedJson != null && expiryTimestamp != null) {
        // Check if cache is still valid
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now < expiryTimestamp) {
          debugPrint('✅ Found valid cached data for $licenseType');
          final List<dynamic> jsonList = jsonDecode(cachedJson);
          final questions =
              jsonList.map((json) => Question.fromJson(json)).toList();

          // Store in memory cache for faster access
          _deadPointQuestionsCache[cacheKey] = questions;

          return questions;
        } else {
          debugPrint('⏰ Cache expired for $licenseType');
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error loading cached data: $e');
      return null;
    }
  }

  /// Save dead point questions to cache
  Future<void> _saveCachedDeadPointQuestions(
      LicenseType licenseType, List<Question> questions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = licenseType.name;

      // 1. Save to memory cache
      _deadPointQuestionsCache[cacheKey] = questions;

      // 2. Save to SharedPreferences
      final jsonList = questions.map((q) => q.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString('$_cacheKeyPrefix${licenseType.name}', jsonString);

      // 3. Save expiry timestamp (7 days from now)
      final expiryTimestamp = DateTime.now()
          .add(const Duration(days: _cacheDurationDays))
          .millisecondsSinceEpoch;
      await prefs.setInt(
          '$_cacheExpiryPrefix${licenseType.name}', expiryTimestamp);

      debugPrint(
          '💾 Cached ${questions.length} dead point questions for $licenseType');
    } catch (e) {
      debugPrint('❌ Error saving cache: $e');
    }
  }

  /// Clear cache for a specific license type
  static Future<void> clearCache(LicenseType licenseType) async {
    try {
      // Clear memory cache
      _deadPointQuestionsCache.remove(licenseType.name);

      // Clear SharedPreferences cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cacheKeyPrefix${licenseType.name}');
      await prefs.remove('$_cacheExpiryPrefix${licenseType.name}');

      debugPrint('🗑️ Cleared cache for $licenseType');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Clear all dead point questions cache
  static Future<void> clearAllCache() async {
    try {
      // Clear memory cache
      _deadPointQuestionsCache.clear();

      // Clear SharedPreferences cache
      final prefs = await SharedPreferences.getInstance();
      for (final type in LicenseType.values) {
        await prefs.remove('$_cacheKeyPrefix${type.name}');
        await prefs.remove('$_cacheExpiryPrefix${type.name}');
      }

      debugPrint('🗑️ Cleared all dead point questions cache');
    } catch (e) {
      debugPrint('❌ Error clearing all cache: $e');
    }
  }

  /// Fetch dead point questions for a specific license type
  Future<List<Question>> fetchDeadPointQuestions(
      LicenseType licenseType) async {
    // 1. Try to load from cache first
    final cachedQuestions = await _loadCachedDeadPointQuestions(licenseType);
    if (cachedQuestions != null && cachedQuestions.isNotEmpty) {
      debugPrint(
          '✅ Returning ${cachedQuestions.length} cached dead point questions for $licenseType');
      return cachedQuestions;
    }

    // 2. If no cache, fetch from Firebase
    // Check if licenseType is one of the special licenses
    final actualLicenseType = _getActualLicenseType(licenseType);

    // Get the number of test sets for this license type
    final numberOfTestSets = numberOfTestSetsBasedOnLicense(licenseType);

    debugPrint(
        '💀 Fetching dead point questions for license: $licenseType ($numberOfTestSets test sets)');
    debugPrint('💀 Using actual license type: $actualLicenseType');
    try {
      final database = FirebaseDatabase.instance.ref(actualLicenseType);
      // Fetch only the number of test sets for this license type
      final snapshot =
          await database.limitToFirst(numberOfTestSets).orderByKey().get();

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
                  debugPrint(
                      '💀 Found dead point question: ${question.content}...');
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

      // 3. Save to cache before returning
      await _saveCachedDeadPointQuestions(
          licenseType, uniqueDeadPointQuestions);

      return uniqueDeadPointQuestions;
    } catch (e) {
      debugPrint('❌ Error fetching dead point questions: $e');
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
