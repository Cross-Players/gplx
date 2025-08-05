import 'package:gplx/features/test/constants/quiz_constants.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test/models/quiz_result.dart';

/// Service for quiz business logic
class QuizLogicService {
  /// Check if an answer is correct
  static bool isAnswerCorrect({
    required List<Question> questions,
    required int questionIndex,
    required Map<int, int> selectedAnswers,
  }) {
    if (!selectedAnswers.containsKey(questionIndex)) return false;

    final selectedAnswerIndex = selectedAnswers[questionIndex]!;
    final question = questions[questionIndex];

    if (selectedAnswerIndex >= question.answers.length) return false;

    return question.answers[selectedAnswerIndex].isCorrect;
  }

  /// Check if critical questions failed
  static bool checkCriticalQuestionsFailed({
    required List<Question> questions,
    required Map<int, int> selectedAnswers,
  }) {
    // Check answered critical questions
    for (final entry in selectedAnswers.entries) {
      final questionIndex = entry.key;
      final question = questions[questionIndex];

      if ((question.isDeadPoint ?? false) &&
          !isAnswerCorrect(
            questions: questions,
            questionIndex: questionIndex,
            selectedAnswers: selectedAnswers,
          )) {
        return true;
      }
    }

    // Check unanswered critical questions
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final isCritical = question.isDeadPoint ?? false;
      final isAnswered = selectedAnswers.containsKey(i);

      if (isCritical && !isAnswered) {
        return true;
      }
    }

    return false;
  }

  /// Calculate quiz score percentage
  static double calculatePercentage({
    required int correctAnswers,
    required int totalQuestions,
  }) {
    return totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;
  }

  /// Determine if quiz is passed
  static bool determinePassStatus({
    required double percentCorrect,
    required bool failedCriticalQuestion,
  }) {
    final passedCriticalQuestions = !failedCriticalQuestion;
    final passedScoreThreshold = percentCorrect >= QuizConstants.passPercentage;
    return passedCriticalQuestions && passedScoreThreshold;
  }

  /// Process unprocessed answers and update quiz result
  static QuizResult processUnprocessedAnswers({
    required List<Question> questions,
    required Map<int, int> selectedAnswers,
    required Map<int, bool> checkedQuestions,
    required QuizResult currentResult,
  }) {
    int correctCount = currentResult.correctAnswers;
    int wrongCount = currentResult.wrongAnswers;

    selectedAnswers.forEach((questionIndex, selectedAnswerIndex) {
      if (!(checkedQuestions[questionIndex] ?? false)) {
        final isCorrect = isAnswerCorrect(
          questions: questions,
          questionIndex: questionIndex,
          selectedAnswers: selectedAnswers,
        );

        if (isCorrect) {
          correctCount++;
        } else {
          wrongCount++;
        }
      }
    });

    return currentResult.copyWith(
      correctAnswers: correctCount,
      wrongAnswers: wrongCount,
    );
  }

  /// Convert selected answers for saving
  static Map<String, int> convertSelectedAnswersForSaving(
      Map<int, int> selectedAnswers) {
    final result = <String, int>{};
    selectedAnswers.forEach((key, value) {
      result[key.toString()] = value;
    });
    return result;
  }

  /// Get answer feedback color and text
  static AnswerFeedback getAnswerFeedback({
    required bool isCorrect,
    required Question question,
  }) {
    final correctAnswer = question.answers.firstWhere(
      (a) => a.isCorrect,
      orElse: () => question.answers.first,
    );

    return AnswerFeedback(
      isCorrect: isCorrect,
      feedbackText: isCorrect
          ? QuizConstants.correctFeedback
          : QuizConstants.wrongFeedback,
      correctAnswerText:
          '${QuizConstants.correctAnswerPrefix}${correctAnswer.answerContent}',
      explanation: question.explanation.isNotEmpty
          ? '${QuizConstants.explanationPrefix}${question.explanation}'
          : null,
    );
  }

  /// Check if question is answered
  static bool isQuestionAnswered(
      int questionIndex, Map<int, int> selectedAnswers) {
    return selectedAnswers.containsKey(questionIndex);
  }

  /// Check if question is checked
  static bool isQuestionChecked(
      int questionIndex, Map<int, bool> checkedQuestions) {
    return checkedQuestions[questionIndex] ?? false;
  }

  /// Get next unanswered question index
  static int? getNextUnansweredQuestion({
    required int totalQuestions,
    required Map<int, int> selectedAnswers,
    int? currentIndex,
  }) {
    final startIndex = currentIndex != null ? currentIndex + 1 : 0;

    for (int i = startIndex; i < totalQuestions; i++) {
      if (!selectedAnswers.containsKey(i)) {
        return i;
      }
    }

    // If no unanswered question after current, check from beginning
    if (currentIndex != null) {
      for (int i = 0; i < currentIndex; i++) {
        if (!selectedAnswers.containsKey(i)) {
          return i;
        }
      }
    }

    return null;
  }
}

/// Data class for answer feedback
class AnswerFeedback {
  final bool isCorrect;
  final String feedbackText;
  final String correctAnswerText;
  final String? explanation;

  const AnswerFeedback({
    required this.isCorrect,
    required this.feedbackText,
    required this.correctAnswerText,
    this.explanation,
  });
}
