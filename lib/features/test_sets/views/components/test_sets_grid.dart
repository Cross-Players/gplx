import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/models/quiz_result.dart';
import 'package:gplx/features/test/models/vehicle.dart';
import 'package:gplx/features/test/providers/quiz_providers.dart';
import 'package:gplx/features/test/providers/quiz_results_provider.dart';
import 'package:gplx/features/test/views/quiz_result_summary.dart';
import 'package:gplx/features/test/views/quiz_screen.dart';
import 'package:gplx/features/test_sets/constants/test_sets_constants.dart';
import 'package:gplx/features/test_sets/utils/test_sets_utils.dart';
import 'package:gplx/features/test_sets/views/components/test_set_card.dart';
import 'package:gplx/features/test_sets/views/components/start_quiz_dialog.dart';

/// Grid view for displaying test sets
class TestSetsGrid extends ConsumerWidget {
  final List<List<int>> testSets;
  final Vehicle vehicle;

  const TestSetsGrid({
    super.key,
    required this.testSets,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testResults = ref.watch(quizResultsNotifierProvider);

    return GridView.builder(
      padding: const EdgeInsets.all(TestSetsConstants.gridPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: TestSetsUtils.getGridColumns(context),
        mainAxisSpacing: TestSetsConstants.gridSpacing,
        crossAxisSpacing: TestSetsConstants.gridSpacing,
        childAspectRatio: TestSetsConstants.gridChildAspectRatio,
      ),
      itemCount: testSets.length,
      itemBuilder: (context, index) => _buildTestSetCard(
        context,
        ref,
        index,
        testResults,
      ),
    );
  }

  Widget _buildTestSetCard(
    BuildContext context,
    WidgetRef ref,
    int index,
    QuizResultsState testResults,
  ) {
    final testSet = testSets[index];
    final testNumber = index + 1;
    final testSetId = TestSetsUtils.formatTestSetId(index, vehicle.vehicleType);

    // Find quiz result
    final quizResult = testResults.results
        .where((result) => result.quizId == testSetId)
        .firstOrNull;

    // Get result data
    final isCompleted = quizResult != null;
    final correct = isCompleted ? quizResult.correctAnswers : 0;
    final wrong = isCompleted ? quizResult.wrongAnswers : 0;

    return TestSetCard(
      testNumber: testNumber,
      questionCount: testSet.length,
      correct: correct,
      wrong: wrong,
      isCompleted: isCompleted,
      isPassed: quizResult?.isPassed,
      onTap: () => _handleTestSetTap(
        context,
        ref,
        quizResult,
        testSetId,
        testNumber,
        testSet.length,
      ),
    );
  }

  void _handleTestSetTap(
    BuildContext context,
    WidgetRef ref,
    QuizResult? quizResult,
    String testSetId,
    int testNumber,
    int questionCount,
  ) {
    // Check if quiz result exists and has selectedAnswers
    final hasSelectedAnswers = quizResult?.selectedAnswers != null &&
        quizResult!.selectedAnswers!.isNotEmpty;

    if (quizResult != null && hasSelectedAnswers) {
      // Show result summary for completed quiz
      _showQuizResult(context, ref, quizResult, testSetId);
    } else {
      // Show dialog to start new quiz
      _showStartQuizDialog(context, testNumber, questionCount, testSetId);
    }
  }

  void _showQuizResult(
    BuildContext context,
    WidgetRef ref,
    QuizResult quizResult,
    String testSetId,
  ) async {
    try {
      final questions = await ref.read(quizQuestionsProvider(testSetId).future);

      if (!context.mounted) return;

      final selectedAnswers = TestSetsUtils.convertSelectedAnswers(
        quizResult.selectedAnswers,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultSummary(
            quizResult: quizResult,
            questions: questions,
            selectedAnswers: selectedAnswers,
            timeTaken: quizResult.timeTaken ?? Duration.zero,
            onBackPressed: () => Navigator.pop(context),
            onRetakeQuiz: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(testSetId: testSetId),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        TestSetsUtils.showErrorSnackBar(
          context,
          '${TestSetsConstants.loadResultErrorMessage}$e',
        );
      }
    }
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
        questionCount: questionCount,
        vehicle: vehicle,
        onStart: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(testSetId: testSetId),
            ),
          );
        },
      ),
    );
  }
}
