/// Constants for test sets feature
class TestSetsConstants {
  // Default configuration
  static const int defaultNumberOfSets = 20;
  static const double gridChildAspectRatio = 1.5;
  static const double gridPadding = 16.0;
  static const double gridSpacing = 16.0;

  // Responsive breakpoints
  static const int mobileGridColumns = 2;
  static const int desktopGridColumns = 4;

  // Messages
  static const String loadingMessage = 'Đang tạo đề thi...';
  static const String successMessage = 'Đã tạo bộ đề mới thành công!';
  static const String creatingMessage = 'Đang tạo bộ đề mới...';
  static const String loadResultErrorMessage = 'Có lỗi khi tải kết quả: ';

  // Dialog titles and content
  static const String createNewTestSetsTitle = 'Tạo bộ đề mới?';
  static const String createNewTestSetsContent =
      'Bạn có chắc chắn muốn tạo bộ đề thi mới? Các đề thi hiện tại sẽ bị thay thế.';
  static const String deleteResultsTitle = 'Xóa kết quả hạng ';
  static const String deleteResultsContent =
      'Bạn có chắc chắn muốn xóa tất cả kết quả bài thi hạng ';

  // Button labels
  static const String cancelButton = 'HỦY';
  static const String startButton = 'BẮT ĐẦU';
  static const String createNewButton = 'TẠO MỚI';
  static const String deleteButton = 'XÓA';

  // Quiz instructions
  static const String quizInstructions = 'Trong quá trình làm bài, bạn có thể:';
  static const List<String> quizInstructionItems = [
    '• Chọn một đáp án và kiểm tra ngay kết quả',
    '• Xem lại các câu đã làm và chưa làm',
    '• Nộp bài bất cứ lúc nào',
  ];

  // Durations
  static const Duration loadingSnackBarDuration = Duration(seconds: 1);
  static const Duration successSnackBarDuration = Duration(seconds: 2);
}
