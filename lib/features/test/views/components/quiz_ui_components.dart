import 'package:flutter/material.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/widgets/base64_image_widget.dart';
import 'package:gplx/features/test/constants/quiz_constants.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${QuizConstants.questionPrefix}${isQuiz ? questionIndex! + 1 : (question?.number ?? questionIndex)}:',
          style: AppStyles.textBold.copyWith(
            fontSize: AppStyles.fontSizeH,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          questionContent,
          style: AppStyles.textBold.copyWith(
            fontSize: QuizConstants.questionContentFontSize,
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

  const QuizNavigationWidget({
    super.key,
    required this.canGoPrevious,
    required this.canGoNext,
    this.onPrevious,
    this.onNext,
    this.onShowQuestionIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(QuizConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppStyles.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: canGoPrevious ? onPrevious : null,
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: onShowQuestionIndex,
                icon: const Icon(
                  Icons.menu_book_outlined,
                  size: 25,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: canGoNext ? onNext : null,
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for check answer button
class CheckAnswerButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const CheckAnswerButtonWidget({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -25),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(QuizConstants.buttonPadding),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
            color: Colors.green,
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
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

    Color backgroundColor = Colors.lightBlue[100]!;
    Color textColor = Colors.black;

    if (isChecked) {
      backgroundColor = isCorrect ? Colors.green[200]! : Colors.red[200]!;
    }

    if (isCurrentQuestion) {
      backgroundColor = Colors.blue[300]!;
      textColor = Colors.white;
    }

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onQuestionTap(index);
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(QuizConstants.borderRadius),
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
