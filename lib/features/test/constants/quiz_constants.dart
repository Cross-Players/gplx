/// Constants for quiz screen
class QuizConstants {
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double buttonPadding = 12.0;
  static const double borderRadius = 8.0;
  static const double iconSize = 24.0;
  static const double tabIconSize = 16.0;
  static const double questionImageHeight = 150.0;
  static const double bottomSheetHeight = 0.5; // 50% of screen height

  // Grid Configuration
  static const int questionGridCrossAxisCount = 6;
  static const double questionGridSpacing = 8.0;
  static const double questionGridChildAspectRatio = 1.0;

  // Timer Configuration
  static const int timerUpdateIntervalSeconds = 1;

  // Quiz Configuration
  static const double passPercentage = 84.0;
  static const int maxAnswerOptions = 4;

  // Animation Configuration
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration tabAnimationDuration = Duration(milliseconds: 200);

  // Text Styles
  static const double questionHeaderFontSize = 18.0;
  static const double questionContentFontSize = 18.0;
  static const double answerOptionFontSize = 16.0;
  static const double timerFontSize = 20.0;
  static const double counterFontSize = 18.0;

  // Colors
  static const double correctAnswerOpacity = 0.2;
  static const double wrongAnswerOpacity = 0.2;
  static const double selectedAnswerOpacity = 0.2;

  // SharedPreferences Keys
  static const String quizProgressPrefix = 'quiz_progress_';

  // Error Messages
  static const String loadingErrorMessage =
      'Error loading Test set and questions: ';
  static const String saveProgressErrorMessage = 'Error saving quiz progress: ';
  static const String loadProgressErrorMessage =
      'Error loading saved quiz progress: ';
  static const String clearProgressErrorMessage =
      'Error clearing saved quiz progress: ';
  static const String saveResultErrorMessage = 'Error saving test result: ';

  // UI Text
  static const String loadingTitle = 'Đang tải bài quiz ...';
  static const String noQuestionsMessage =
      'Không có câu hỏi nào cho bài quiz này';
  static const String backButtonText = 'Quay lại';
  static const String completeButtonText = 'Hoàn thành';
  static const String confirmSubmitTitle = 'Bạn chắc chắn muốn nộp bài không?';
  static const String cancelButtonText = 'Hủy';
  static const String submitButtonText = 'Nộp bài';
  static const String correctFeedback = 'Chính xác!';
  static const String wrongFeedback = 'Sai rồi!';
  static const String correctAnswerPrefix = 'Đáp án đúng: ';
  static const String explanationPrefix = 'Giải thích: ';
  static const String questionPrefix = 'CÂU HỎI ';
  static const String questionTabPrefix = 'Câu ';

  // JSON Keys for saving/loading
  static const String selectedAnswersKey = 'selectedAnswers';
  static const String checkedQuestionsKey = 'checkedQuestions';
  static const String quizResultKey = 'quizResult';
  static const String lastSavedKey = 'lastSaved';
  static const String quizIdKey = 'quizId';
  static const String quizTitleKey = 'quizTitle';
  static const String totalQuestionsKey = 'totalQuestions';
  static const String correctAnswersKey = 'correctAnswers';
  static const String wrongAnswersKey = 'wrongAnswers';
  static const String attemptDateKey = 'attemptDate';
  static const String failedCriticalQuestionKey = 'failedCriticalQuestion';
  static const String timeTakenKey = 'timeTaken';
  static const String minPointKey = 'minPoint';
  static const String isPassedKey = 'isPassed';
}
