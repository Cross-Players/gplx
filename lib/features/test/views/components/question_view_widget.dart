import 'package:flutter/material.dart';
import 'package:gplx/core/widgets/base64_image_widget.dart';
import 'package:gplx/features/test/constants/quiz_constants.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test/services/quiz_logic_service.dart';
import 'package:gplx/features/test/views/components/quiz_ui_components.dart';

/// Widget for displaying a single answer option
class AnswerOptionWidget extends StatelessWidget {
  final int questionIndex;
  final int optionIndex;
  final String text;
  final bool isCorrect;
  final bool isSelected;
  final bool showResult;
  final Function(int, int) onAnswerSelected;

  const AnswerOptionWidget({
    super.key,
    required this.questionIndex,
    required this.optionIndex,
    required this.text,
    required this.isCorrect,
    required this.isSelected,
    required this.showResult,
    required this.onAnswerSelected,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: showResult
          ? null
          : () => onAnswerSelected(questionIndex, optionIndex),
      child: Container(
        padding: const EdgeInsets.all(QuizConstants.defaultPadding),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(QuizConstants.borderRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnswerIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: QuizConstants.answerOptionFontSize,
                  color: showResult && isCorrect ? Colors.green : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _getBackgroundColor() {
    if (showResult) {
      if (isCorrect) return Colors.green[50];
      if (isSelected && !isCorrect) return Colors.red[50];
    } else if (isSelected) {
      return Colors.blue[50];
    }
    return null;
  }

  Widget _buildAnswerIcon() {
    return Container(
      width: QuizConstants.iconSize,
      height: QuizConstants.iconSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[400]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: showResult
          ? Icon(
              isCorrect ? Icons.check : Icons.close,
              size: QuizConstants.tabIconSize,
              color: isCorrect ? Colors.green : Colors.red,
            )
          : null,
    );
  }
}

/// Widget for displaying answer feedback
class AnswerFeedbackWidget extends StatelessWidget {
  final AnswerFeedback feedback;

  const AnswerFeedbackWidget({
    super.key,
    required this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: feedback.isCorrect
            ? Colors.green.withValues(alpha: QuizConstants.correctAnswerOpacity)
            : Colors.red.withValues(alpha: QuizConstants.wrongAnswerOpacity),
        borderRadius: BorderRadius.circular(QuizConstants.borderRadius),
        border: Border.all(
          color: feedback.isCorrect ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            feedback.feedbackText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: feedback.isCorrect ? Colors.green : Colors.red,
            ),
          ),
          Text(
            feedback.correctAnswerText,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (feedback.explanation != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                feedback.explanation!,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}

/// Complete question view widget
class QuestionViewWidget extends StatelessWidget {
  final int questionIndex;
  final Question question;
  final Map<int, int> selectedAnswers;
  final Map<int, bool> checkedQuestions;
  final Function(int, int) onAnswerSelected;
  final bool Function(int) isAnswerCorrect;
  final bool isQuiz;

  const QuestionViewWidget({
    super.key,
    required this.questionIndex,
    required this.question,
    required this.selectedAnswers,
    required this.checkedQuestions,
    required this.onAnswerSelected,
    required this.isAnswerCorrect,
    required this.isQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final isChecked = checkedQuestions[questionIndex] ?? false;

    return Container(
      padding: const EdgeInsets.all(QuizConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionHeaderWidget(
            questionIndex: questionIndex,
            isQuiz: isQuiz,
            questionContent: question.content,
            question: question, // Pass the question object
          ),
          const SizedBox(height: QuizConstants.defaultPadding),
          if (question.imageUrl?.isNotEmpty == true)
            Base64ImageWidget(base64String: question.imageUrl!),
          Expanded(
            child: ListView(
              children: [
                ..._buildAnswerOptions(),
                const SizedBox(height: 20),
                if (isChecked) _buildFeedback(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnswerOptions() {
    return List.generate(
      question.answers.length,
      (index) => AnswerOptionWidget(
        questionIndex: questionIndex,
        optionIndex: index,
        text: question.answers[index].answerContent,
        isCorrect: question.answers[index].isCorrect,
        isSelected: selectedAnswers[questionIndex] == index,
        showResult: checkedQuestions[questionIndex] ?? false,
        onAnswerSelected: onAnswerSelected,
      ),
    );
  }

  Widget _buildFeedback() {
    final feedback = QuizLogicService.getAnswerFeedback(
      isCorrect: isAnswerCorrect(questionIndex),
      question: question,
    );

    return AnswerFeedbackWidget(feedback: feedback);
  }
}
