import 'package:flutter/material.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/widgets/base64_image_widget.dart';
import 'package:gplx/features/test/constants/quiz_constants.dart';
import 'package:gplx/features/test/models/answer.dart';
import 'package:gplx/features/test/models/question.dart';
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
    final style = _style();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: style.background,
        borderRadius: BorderRadius.circular(AppPalette.radiusM),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppPalette.radiusM),
          onTap: showResult
              ? null
              : () => onAnswerSelected(questionIndex, optionIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppPalette.radiusM),
              border: Border.all(
                color: style.border,
                width: style.emphasized ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnswerBadge(style),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: QuizConstants.answerOptionFontSize,
                        height: 1.4,
                        fontWeight: style.emphasized
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: style.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _AnswerStyle _style() {
    if (showResult && isCorrect) {
      return const _AnswerStyle(
        background: AppPalette.successSoft,
        border: AppPalette.success,
        accent: AppPalette.success,
        text: Color(0xFF14532D),
        emphasized: true,
      );
    }
    if (showResult && isSelected) {
      return const _AnswerStyle(
        background: AppPalette.dangerSoft,
        border: AppPalette.danger,
        accent: AppPalette.danger,
        text: Color(0xFF7F1D1D),
        emphasized: true,
      );
    }
    if (isSelected) {
      return const _AnswerStyle(
        background: AppPalette.primarySoft,
        border: AppPalette.primary,
        accent: AppPalette.primary,
        text: AppPalette.ink,
        emphasized: true,
      );
    }
    return const _AnswerStyle(
      background: AppPalette.surface,
      border: AppPalette.border,
      accent: AppPalette.inkMuted,
      text: AppPalette.ink,
      emphasized: false,
    );
  }

  Widget _buildAnswerBadge(_AnswerStyle style) {
    final filled = style.emphasized;
    final Widget child = showResult && (isCorrect || isSelected)
        ? Icon(
            isCorrect ? Icons.check_rounded : Icons.close_rounded,
            size: 16,
            color: Colors.white,
          )
        : Text(
            String.fromCharCode(65 + optionIndex),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: filled ? Colors.white : AppPalette.inkMuted,
            ),
          );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? style.accent : AppPalette.background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: child,
    );
  }
}

class _AnswerStyle {
  final Color background;
  final Color border;
  final Color accent;
  final Color text;
  final bool emphasized;

  const _AnswerStyle({
    required this.background,
    required this.border,
    required this.accent,
    required this.text,
    required this.emphasized,
  });
}

/// Widget for displaying answer feedback
class AnswerFeedbackWidget extends StatelessWidget {
  final AnswerFeedback feedback;

  const AnswerFeedbackWidget({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: feedback.isCorrect
            ? AppPalette.successSoft
            : AppPalette.dangerSoft,
        borderRadius: BorderRadius.circular(AppPalette.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            feedback.feedbackText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: feedback.isCorrect
                  ? AppPalette.success
                  : AppPalette.danger,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Container(
                padding: const EdgeInsets.all(QuizConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuestionHeaderWidget(
                      questionIndex: questionIndex,
                      isQuiz: isQuiz,
                      questionContent: question.content ?? '',
                      question: question,
                    ),
                    const SizedBox(height: QuizConstants.defaultPadding),
                    if (question.imageUrl?.isNotEmpty == true)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppPalette.surface,
                          borderRadius:
                              BorderRadius.circular(AppPalette.radiusM),
                          border: Border.all(color: AppPalette.border),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppPalette.radiusS),
                          child: Center(
                            child: Base64ImageWidget(
                              base64String: question.imageUrl!,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: QuizConstants.defaultPadding),
                    // Answer options and feedback
                    _buildAnswerOptions(),
                    const SizedBox(height: 20),
                    // if (isChecked) _buildFeedback(),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnswerOptions() {
    final answers = question.answers ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(
        answers.length,
        (index) => AnswerOptionWidget(
          questionIndex: questionIndex,
          optionIndex: index,
          text: answers[index].content,
          isCorrect: answers[index].isCorrect,
          isSelected: selectedAnswers[questionIndex] == index,
          showResult: checkedQuestions[questionIndex] ?? false,
          onAnswerSelected: onAnswerSelected,
        ),
      ),
    );
  }
}
