import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/features/test/models/vehicle.dart';
import 'package:gplx/features/test_sets/constants/test_sets_constants.dart';

/// Dialog for confirming quiz start
class StartQuizDialog extends ConsumerWidget {
  final int testNumber;
  final VoidCallback onStart;

  const StartQuizDialog({
    super.key,
    required this.testNumber,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(selectedVehicleTypeProvider);
    final questionCount = vehicle.totalQuestionsPerQuiz;
    return AlertDialog(
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppPalette.heroGradient,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.assignment_rounded,
            color: Colors.white, size: 28),
      ),
      title: Text('Đề thi số $testNumber'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _QuizInfoRow(
                  icon: Icons.quiz_rounded,
                  text: '$questionCount câu',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuizInfoRow(
                  icon: Icons.timer_rounded,
                  text: '${vehicle.minutes} phút',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            TestSetsConstants.quizInstructions,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppPalette.ink,
            ),
          ),
          const SizedBox(height: 6),
          ...TestSetsConstants.quizInstructionItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(item, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(TestSetsConstants.cancelButton),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onStart();
                },
                child: const Text(TestSetsConstants.startButton),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget for displaying quiz information row
class _QuizInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _QuizInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.primarySoft,
        borderRadius: BorderRadius.circular(AppPalette.radiusS),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppPalette.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppPalette.primaryDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
