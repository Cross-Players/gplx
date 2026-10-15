import 'package:flutter/material.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/widgets/base64_image_widget.dart';
import 'package:gplx/features/test/constants/quiz_constants.dart';
import 'package:gplx/features/test/models/question.dart';

/// Widget for displaying quiz question header
class QuestionHeaderWidget extends StatelessWidget {
  final int? questionIndex;
  final bool isQuiz;
  final String questionContent;
  final dynamic question; // Add question parameter to access question.number

  const QuestionHeaderWidget({
    super.key,
    this.questionIndex,
    required this.isQuiz,
    required this.questionContent,
    this.question,
  });

  @override
  Widget build(BuildContext context) {
    final q = question;
    final isDeadPoint = q is Question && q.isDeadPoint == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppPalette.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${QuizConstants.questionPrefix}${isQuiz ? questionIndex! + 1 : (question?.number ?? questionIndex)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: AppPalette.primary,
                ),
              ),
            ),
            if (isDeadPoint) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppPalette.dangerSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Điểm liệt',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.danger,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          questionContent,
          style: const TextStyle(
            fontSize: QuizConstants.questionContentFontSize + 1,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: AppPalette.ink,
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying question image
class QuestionImageWidget extends StatelessWidget {
  final String imageUrl;

  const QuestionImageWidget({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: QuizConstants.defaultPadding),
      height: QuizConstants.questionImageHeight,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(QuizConstants.borderRadius),
        child: Base64ImageWidget(
          base64String: imageUrl,
        ),
      ),
    );
  }
}

/// Widget for quiz navigation controls
class QuizNavigationWidget extends StatelessWidget {
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onShowQuestionIndex;

  /// Checks the current answer. Null when there is nothing to check.
  final VoidCallback? onCheck;

  const QuizNavigationWidget({
    super.key,
    required this.canGoPrevious,
    required this.canGoNext,
    this.onPrevious,
    this.onNext,
    this.onShowQuestionIndex,
    this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        border: const Border(top: BorderSide(color: AppPalette.border)),
        boxShadow: AppPalette.softShadow(),
      ),
      child: Row(
        children: [
          _NavButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: canGoPrevious ? onPrevious : null,
          ),
          const SizedBox(width: 10),
          _NavButton(
            icon: Icons.grid_view_rounded,
            onPressed: onShowQuestionIndex,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onCheck,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppPalette.success,
                disabledBackgroundColor: AppPalette.background,
                disabledForegroundColor: AppPalette.inkFaint,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppPalette.radiusS),
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 20),
              label: const Text('Kiểm tra'),
            ),
          ),
          const SizedBox(width: 10),
          _NavButton(
            icon: Icons.arrow_forward_ios_rounded,
            onPressed: canGoNext ? onNext : null,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  const _NavButton({
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: filled && enabled ? AppPalette.primary : AppPalette.background,
      borderRadius: BorderRadius.circular(AppPalette.radiusS),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppPalette.radiusS),
        onTap: onPressed,
        child: SizedBox(
          width: 52,
          height: 48,
          child: Icon(
            icon,
            size: 18,
            color: !enabled
                ? AppPalette.inkFaint
                : (filled ? Colors.white : AppPalette.ink),
          ),
        ),
      ),
    );
  }
}

/// Widget for question index modal
class QuestionIndexModalWidget extends StatelessWidget {
  final int totalQuestions;
  final int currentQuestionIndex;
  final Map<int, bool> checkedQuestions;
  final Map<int, int> selectedAnswers;
  final Function(int) onQuestionTap;
  final bool Function(int) isAnswerCorrect;
  final bool isQuiz;
  final List<dynamic>?
      questions; // For getting question numbers when isQuiz = false
  const QuestionIndexModalWidget({
    super.key,
    required this.totalQuestions,
    required this.currentQuestionIndex,
    required this.checkedQuestions,
    required this.selectedAnswers,
    required this.onQuestionTap,
    required this.isAnswerCorrect,
    required this.isQuiz,
    this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      height:
          MediaQuery.of(context).size.height * QuizConstants.bottomSheetHeight,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: QuizConstants.questionGridCrossAxisCount,
          childAspectRatio: QuizConstants.questionGridChildAspectRatio,
          crossAxisSpacing: QuizConstants.questionGridSpacing,
          mainAxisSpacing: QuizConstants.questionGridSpacing,
        ),
        itemCount: totalQuestions,
        itemBuilder: (context, index) =>
            _buildQuestionIndexItem(context, index),
      ),
    );
  }

  Widget _buildQuestionIndexItem(BuildContext context, int index) {
    final isCurrentQuestion = currentQuestionIndex == index;
    final isChecked = checkedQuestions[index] ?? false;
    final isCorrect = isChecked ? isAnswerCorrect(index) : false;

    final isAnswered = selectedAnswers.containsKey(index);
    Color backgroundColor = AppPalette.background;
    Color textColor = AppPalette.ink;

    if (isAnswered) {
      backgroundColor = AppPalette.primarySoft;
      textColor = AppPalette.primaryDeep;
    }

    if (isChecked) {
      backgroundColor =
          isCorrect ? AppPalette.successSoft : AppPalette.dangerSoft;
      textColor = isCorrect ? AppPalette.success : AppPalette.danger;
    }

    if (isCurrentQuestion) {
      backgroundColor = AppPalette.primary;
      textColor = Colors.white;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(AppPalette.radiusS),
      onTap: () {
        Navigator.pop(context);
        onQuestionTap(index);
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppPalette.radiusS),
        ),
        child: Center(
          child: Text(
            _getDisplayNumber(index),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: QuizConstants.counterFontSize,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  String _getDisplayNumber(int index) {
    if (isQuiz) {
      // For quiz: use index + 1 (same as QuestionHeaderWidget: questionIndex! + 1)
      return (index + 1).toString();
    } else {
      // For exercise: use question.number (same as QuestionHeaderWidget: questionIndex)
      if (questions != null && index < questions!.length) {
        final question = questions![index];
        return question.number.toString();
      }
      return (index + 1).toString(); // Fallback
    }
  }
}
