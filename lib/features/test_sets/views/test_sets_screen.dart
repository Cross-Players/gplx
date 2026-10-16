import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/widgets/gradient_app_bar.dart';
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
      appBar: GradientAppBar(
        title: Text("Đề thi hạng ${licenseType.name}"),
      ),
      body: GridView.builder(
        padding: EdgeInsets.fromLTRB(
          TestSetsConstants.gridPadding,
          TestSetsConstants.gridPadding,
          TestSetsConstants.gridPadding,
          TestSetsConstants.gridPadding + MediaQuery.of(context).padding.bottom,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: TestSetsUtils.getGridColumns(context),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
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

                  List<Question> questions = [];
                  final prefs = await SharedPreferences.getInstance();
                  final questionsKey = 'questions_$formattedId';
                  final cachedQuestions = prefs.getString(questionsKey);
                  if (cachedQuestions != null) {
                    // Lấy từ local
                    final decoded = jsonDecode(cachedQuestions) as List;
                    questions =
                        decoded.map((e) => Question.fromJson(e)).toList();
                  } else {
                    // Lấy từ API và lưu vào local
                    try {
                      final controller = TestController();
                      questions = await controller.fetchQuestionsByTestSets(
                        licenseType,
                        testNumber,
                      );
                      final encoded =
                          jsonEncode(questions.map((e) => e.toJson()).toList());
                      await prefs.setString(questionsKey, encoded);
                    } catch (_) {
                      // ignore; show summary without questions if fetch fails
                    }
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
                          return '';
                        },
                      ),
                    ),
                  );
                  return;
                }
              } catch (e) {
                // ignore storage/parse errors and fallback to quiz screen
              }

              _showStartQuizDialog(context, testNumber, formattedId);
            },
          );
        },
      ),
    );
  }

  void _showStartQuizDialog(
    BuildContext context,
    int testNumber,
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
    final failed = isCompleted && isPassed == false;
    final Color accent = !isCompleted
        ? AppPalette.primary
        : (failed ? AppPalette.danger : AppPalette.success);
    final total = correct + wrong;

    return Material(
      color: AppPalette.surface,
      borderRadius: BorderRadius.circular(AppPalette.radiusM),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppPalette.radiusM),
            border: Border.all(
              color: isCompleted
                  ? accent.withValues(alpha: 0.35)
                  : AppPalette.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$testNumber',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        failed ? 'Trượt' : 'Đạt',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    )
                  else
                    const Icon(Icons.play_circle_fill_rounded,
                        color: AppPalette.primary, size: 26),
                ],
              ),
              const Spacer(),
              Text(
                'Đề số $testNumber',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.ink,
                ),
              ),
              const SizedBox(height: 6),
              if (isCompleted) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : correct / total,
                    minHeight: 5,
                    color: AppPalette.success,
                    backgroundColor: AppPalette.dangerSoft,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.check_rounded,
                        size: 14, color: AppPalette.success),
                    Text(
                      ' $correct',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.close_rounded,
                        size: 14, color: AppPalette.danger),
                    Text(
                      ' $wrong',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.danger,
                      ),
                    ),
                  ],
                ),
              ] else
                const Text(
                  'Chưa làm',
                  style: TextStyle(fontSize: 12, color: AppPalette.inkMuted),
                ),
            ],
          ),
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
