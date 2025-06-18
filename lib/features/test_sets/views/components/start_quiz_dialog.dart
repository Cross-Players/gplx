import 'package:flutter/material.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/features/test/models/vehicle.dart';
import 'package:gplx/features/test_sets/constants/test_sets_constants.dart';

/// Dialog for confirming quiz start
class StartQuizDialog extends StatelessWidget {
  final int testNumber;
  final int questionCount;
  final Vehicle vehicle;
  final VoidCallback onStart;

  const StartQuizDialog({
    super.key,
    required this.testNumber,
    required this.questionCount,
    required this.vehicle,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Đề thi số $testNumber'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bạn sắp làm đề thi số $testNumber',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _QuizInfoRow(
            icon: Icons.quiz,
            text: 'Số câu hỏi: $questionCount câu',
          ),
          _QuizInfoRow(
            icon: Icons.timer,
            text: 'Thời gian: ${vehicle.minutes} phút',
          ),
          const SizedBox(height: 16),
          const Text(
            TestSetsConstants.quizInstructions,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...TestSetsConstants.quizInstructionItems.map((item) => Text(item)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(TestSetsConstants.cancelButton),
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
          child: const Text(TestSetsConstants.startButton),
        ),
      ],
    );
  }
}

/// Widget for displaying quiz information row
class _QuizInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _QuizInfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
