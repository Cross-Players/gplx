import 'package:flutter/material.dart';
import 'package:gplx/core/constants/app_styles.dart';

class TestSetCard extends StatelessWidget {
  final int testNumber;
  final int questionCount;
  final int correct;
  final int wrong;
  final bool isCompleted;
  final bool? isPassed;
  final VoidCallback onTap;

  const TestSetCard({
    super.key,
    required this.testNumber,
    required this.questionCount,
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
            Text(
              '$questionCount câu hỏi',
              style: TextStyle(
                fontSize: 12,
                color: isCompleted ? Colors.white70 : Colors.black54,
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
