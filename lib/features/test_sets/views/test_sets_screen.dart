import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/routes/app_routes.dart';
import 'package:gplx/features/test/models/quiz.dart';
import 'package:gplx/features/test/providers/firestore_providers.dart';
import 'package:gplx/features/test_sets/controllers/test_results_provider.dart';

class TestSetsScreen extends ConsumerWidget {
  const TestSetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get all test results from local storage
    final testResultsAsyncValue = ref.watch(testResultsProvider);
    // Fetch quizzes from Firestore using the notifier provider
    final quizzesAsyncValue = ref.watch(quizzesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Các đề thi Bằng B2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh quizzes from Firestore using the notifier
              ref.read(quizzesNotifierProvider.notifier).refreshQuizzes();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _showDeleteConfirmationDialog(context, ref);
            },
          ),
        ],
      ),
      body: quizzesAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lỗi tải dữ liệu: ${error.toString()}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(quizzesNotifierProvider.notifier).refreshQuizzes();
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (quizzes) {
          if (quizzes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Không có đề thi nào',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(quizzesNotifierProvider.notifier)
                          .refreshQuizzes();
                    },
                    child: const Text('Tải lại'),
                  ),
                ],
              ),
            );
          }

          return testResultsAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Text('Lỗi tải kết quả: $error'),
            ),
            data: (savedResults) {
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                itemCount: quizzes.length,
                itemBuilder: (context, index) {
                  final quiz = quizzes[index];
                  final testNumber = index + 1;

                  // Extract test number from quiz ID or title for matching
                  int quizTestNumber = _extractTestNumber(quiz.id, quiz.title);

                  // Find the result for this quiz if it exists by matching quizId
                  final quizResult = savedResults.isNotEmpty
                      ? savedResults
                              .where((result) =>
                                  result.quizId == quiz.id ||
                                  _extractTestNumber(
                                          result.quizId, result.quizTitle) ==
                                      quizTestNumber)
                              .isEmpty
                          ? null
                          : savedResults.firstWhere((result) =>
                              result.quizId == quiz.id ||
                              _extractTestNumber(
                                      result.quizId, result.quizTitle) ==
                                  quizTestNumber)
                      : null;

                  // Use saved result data if available, otherwise use default values
                  final isCompleted = quizResult != null;
                  final correct = isCompleted ? quizResult.correctAnswers : 0;
                  final wrong = isCompleted ? quizResult.wrongAnswers : 0;

                  return _TestSetCard(
                    quiz: quiz,
                    testNumber: testNumber,
                    correct: correct,
                    wrong: wrong,
                    isCompleted: isCompleted,
                    onTap: () {
                      _showStartQuizDialog(context, quiz, testNumber, () {
                        // Navigate to the new dedicated QuizPage instead of TestQuestionScreen
                        Navigator.pushNamed(
                          context,
                          AppRoutes.quiz,
                          arguments: {'quizId': quiz.id},
                        );
                      });
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showStartQuizDialog(
    BuildContext context,
    Quiz quiz,
    int testNumber,
    VoidCallback onStart,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đề thi số $testNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn sắp làm bài: ${quiz.title}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.timer, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Thời gian: ${quiz.timeLimit} phút',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Trong quá trình làm bài, bạn có thể:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Chọn một đáp án và kiểm tra ngay kết quả'),
            const Text('• Xem lại các câu đã làm và chưa làm'),
            const Text('• Nộp bài bất cứ lúc nào'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onStart();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('BẮT ĐẦU'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả kết quả?'),
        content: const Text(
            'Bạn có chắc chắn muốn xóa tất cả kết quả bài thi không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY'),
          ),
          TextButton(
            onPressed: () {
              // Clear all saved test results
              ref
                  .read(testResultsRepositoryProvider)
                  .clearAllResults()
                  .then((_) {
                // Refresh the provider to reload the data
                ref.refresh(testResultsProvider);
                Navigator.pop(context);
              });
            },
            child: const Text(
              'XÓA',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  int _extractTestNumber(String id, String title) {
    // Extract test number from the quiz ID or title
    // This is a simple implementation, you may need to adjust it based on your ID/title format
    final RegExp regExp = RegExp(r'(\d+)');
    final match = regExp.firstMatch(id) ?? regExp.firstMatch(title);
    return match != null ? int.tryParse(match.group(0) ?? '0') ?? 0 : 0;
  }
}

class _TestSetCard extends StatelessWidget {
  final Quiz quiz;
  final int testNumber;
  final int correct;
  final int wrong;
  final bool isCompleted;
  final VoidCallback onTap;

  const _TestSetCard({
    required this.quiz,
    required this.testNumber,
    required this.correct,
    required this.wrong,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isCompleted
        ? (wrong > 5 ? AppStyles.errorColor : Colors.green[700])
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
              'ĐỀ THI SỐ ${quiz.title}',
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
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
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
