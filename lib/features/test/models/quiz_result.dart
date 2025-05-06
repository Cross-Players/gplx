class QuizResult {
  final String quizId;
  final String quizTitle;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final DateTime attemptDate;

  QuizResult({
    required this.quizId,
    required this.quizTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.attemptDate,
  });

  // Simple manual implementation of copyWith (replaces freezed-generated version)
  QuizResult copyWith({
    String? quizId,
    String? quizTitle,
    int? totalQuestions,
    int? correctAnswers,
    int? wrongAnswers,
    DateTime? attemptDate,
  }) {
    return QuizResult(
      quizId: quizId ?? this.quizId,
      quizTitle: quizTitle ?? this.quizTitle,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      attemptDate: attemptDate ?? this.attemptDate,
    );
  }

  // Simple manual implementation of toJson (replaces freezed-generated version)
  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'quizTitle': quizTitle,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'attemptDate': attemptDate.toIso8601String(),
    };
  }

  // Simple manual implementation of fromJson (replaces freezed-generated version)
  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      quizId: json['quizId'] as String,
      quizTitle: json['quizTitle'] as String,
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      wrongAnswers: json['wrongAnswers'] as int,
      attemptDate: DateTime.parse(json['attemptDate'] as String),
    );
  }
}
