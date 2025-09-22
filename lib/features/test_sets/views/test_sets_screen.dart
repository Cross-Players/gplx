import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/features/test/models/license_data.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test/models/quiz_result.dart';
import 'package:gplx/features/test/services/quiz_progress_service.dart';
import 'package:gplx/features/test/views/quiz_result_summary.dart';
import 'package:gplx/features/test/views/quiz_screen.dart';
import 'package:gplx/features/test_sets/constants/test_sets_constants.dart';
import 'package:gplx/features/test_sets/controllers/test_controller.dart';
import 'package:gplx/features/test_sets/views/components/start_quiz_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestSetsScreen extends ConsumerStatefulWidget {
  const TestSetsScreen({super.key});

  @override
  ConsumerState<TestSetsScreen> createState() => _TestSetsScreenState();
}

class _TestSetsScreenState extends ConsumerState<TestSetsScreen>
    with WidgetsBindingObserver {
  // map testSetId -> QuizResult
  final Map<String, QuizResult> _savedResults = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedResults();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Khi app được resume (quay lại từ màn hình khác), cập nhật lại kết quả
      _loadSavedResults();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cập nhật kết quả mỗi khi dependencies thay đổi (có thể do navigation)
    _loadSavedResults();
  }

  Future<void> _loadSavedResults() async {
    final licenseType = ref.read(licenseTypeProvider);
    final prefs = await SharedPreferences.getInstance();
    final testNumbers = generateTestSetNumbers(licenseType);
    for (final testNumber in testNumbers) {
      final formattedId = TestSetsUtils.formatTestSetId(
        testNumber - 1,
        licenseType.name,
      );
      final key = 'quiz_result_$formattedId';
      final saved = prefs.getString(key);
      if (saved != null) {
        try {
          final map = jsonDecode(saved) as Map<String, dynamic>;
          final result = QuizResult.fromJson(map);
          _savedResults[formattedId] = result;
        } catch (_) {}
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final licenseType = ref.watch(licenseTypeProvider);

    return Scaffold(
      appBar: AppBar(title: Text("Đề thi hạng ${licenseType.name}")),
      body: GridView.builder(
        padding: const EdgeInsets.all(TestSetsConstants.gridPadding),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: TestSetsUtils.getGridColumns(context),
          mainAxisSpacing: TestSetsConstants.gridSpacing,
          crossAxisSpacing: TestSetsConstants.gridSpacing,
          childAspectRatio: TestSetsConstants.gridChildAspectRatio,
        ),
        itemCount: generateTestSetNumbers(licenseType).length,
        itemBuilder: (context, index) {
          final testNumber = generateTestSetNumbers(licenseType)[index];
          final formattedId = TestSetsUtils.formatTestSetId(
            testNumber - 1,
            licenseType.name,
          );
          final savedResult = _savedResults[formattedId];

          return TestSetCard(
            testNumber: testNumber,
            correct: savedResult?.correctAnswers ?? 0,
            wrong: savedResult?.wrongAnswers ?? 0,
            isCompleted: savedResult != null,
            isPassed: savedResult?.isPassed,
            onTap: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                final key = 'quiz_result_$formattedId';
                final saved = prefs.getString(key);
                if (saved != null) {
                  // load saved result
                  final map = jsonDecode(saved) as Map<String, dynamic>;
                  final result = QuizResult.fromJson(map);

                  // try to load questions for this test to show in the summary
                  List questions = <dynamic>[];
                  try {
                    final controller = TestController();
                    questions = await controller.fetchQuestionsByTestSets(
                      licenseType,
                      testNumber,
                    );
                  } catch (_) {
                    // ignore; show summary without questions if fetch fails
                  }

                  final selectedAnswers = TestSetsUtils.convertSelectedAnswers(
                    result.selectedAnswers,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizResultSummary(
                        quizResult: result,
                        questions: questions.cast<Question>(),
                        selectedAnswers: selectedAnswers,
                        timeTaken: result.timeTaken ?? Duration.zero,
                        onBackPressed: () => Navigator.pop(context),
                        onRetakeQuiz: () async {
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('quiz_result_$formattedId');
                            await QuizProgressService.instance
                                .clearProgress(formattedId);
                          } catch (_) {}

                          final result = await Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  QuizScreen(testSetId: formattedId),
                            ),
                          );
                          // Refresh results when coming back from retake
                          if (result != null || mounted) {
                            await _loadSavedResults();
                          }
                        },
                      ),
                    ),
                  );
                  return;
                }
              } catch (e) {
                // ignore storage/parse errors and fallback to quiz screen
              }

              _showStartQuizDialog(context, testNumber, 12, formattedId);
            },
          );
        },
      ),
    );
  }

  void _showStartQuizDialog(
    BuildContext context,
    int testNumber,
    int questionCount,
    String testSetId,
  ) {
    showDialog(
      context: context,
      builder: (context) => StartQuizDialog(
        testNumber: testNumber,
        onStart: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(testSetId: testSetId),
            ),
          );
          // Refresh results when coming back from quiz
          if (result != null || mounted) {
            await _loadSavedResults();
          }
        },
      ),
    );
  }
}

class TestSetCard extends StatelessWidget {
  final int testNumber;
  final int correct;
  final int wrong;
  final bool isCompleted;
  final bool? isPassed;
  final VoidCallback onTap;

  const TestSetCard({
    super.key,
    required this.testNumber,
    required this.correct,
    required this.wrong,
    required this.isCompleted,
    required this.onTap,
    required this.isPassed,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isCompleted
        ? (isPassed == false ? AppStyles.errorColor : Colors.green[700])
        : Colors.grey[200];

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            const Spacer(),
            Text(
              'ĐỀ THI SỐ $testNumber',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCompleted ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isCompleted) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: Colors.grey[300]),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: AppStyles.iconSizeM,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$correct',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: AppStyles.fontSizeL,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.cancel,
                      color: Colors.red[700],
                      size: AppStyles.iconSizeM,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$wrong',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: AppStyles.fontSizeL,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Convert selected answers map from String keys to int keys
  static Map<int, int> convertSelectedAnswers(
    Map<String, int>? selectedAnswers,
  ) {
    final converted = <int, int>{};
    selectedAnswers?.forEach((key, value) {
      converted[int.parse(key)] = value;
    });
    return converted;
  }
}
