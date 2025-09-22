class QuizResult {
  final String quizId;
  final String quizTitle;
  final int totalQuestions;
  final int minPoint;
  final int correctAnswers;
  final int wrongAnswers;
  final DateTime attemptDate;
  final bool? isPassed;
  final Duration? timeTaken;
  final bool? failedCriticalQuestion;
  final Map<String, int>? selectedAnswers;

  QuizResult({
    required this.quizId,
    required this.quizTitle,
    required this.totalQuestions,
    required this.minPoint,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.attemptDate,
    this.isPassed,
    this.timeTaken,
    this.failedCriticalQuestion,
    this.selectedAnswers,
  });

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'quizTitle': quizTitle,
      'totalQuestions': totalQuestions,
      'minPoint': minPoint,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'attemptDate': attemptDate.toIso8601String(),
      'isPassed': isPassed,
      'timeTaken': timeTaken?.inSeconds,
      'failedCriticalQuestion': failedCriticalQuestion,
      'selectedAnswers': selectedAnswers,
    };
  }

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      quizId: json['quizId'] as String,
      quizTitle: json['quizTitle'] as String,
      totalQuestions: json['totalQuestions'] as int,
      minPoint: json['minPoint'] as int,
      correctAnswers: json['correctAnswers'] as int,
      wrongAnswers: json['wrongAnswers'] as int,
      attemptDate: DateTime.parse(json['attemptDate'] as String),
      isPassed: json['isPassed'] as bool?,
      timeTaken:
          json['timeTaken'] != null
              ? Duration(seconds: json['timeTaken'] as int)
              : null,
      failedCriticalQuestion: json['failedCriticalQuestion'] as bool?,
      selectedAnswers: (json['selectedAnswers'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as int),
      ),
    );
  }
}
