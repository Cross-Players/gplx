// class TestSetResult {
//   final int testNumber;
//   final int correctAnswers;
//   final int wrongAnswers;
//   final String date;
//   final bool isPassed;
//   final Duration duration;

//   const TestSetResult({
//     required this.testNumber,
//     required this.correctAnswers,
//     required this.wrongAnswers,
//     required this.date,
//     required this.isPassed,
//     required this.duration,
//   });

//   // Convert to JSON for storage
//   Map<String, dynamic> toJson() {
//     return {
//       'testNumber': testNumber,
//       'correctAnswers': correctAnswers,
//       'wrongAnswers': wrongAnswers,
//       'date': date,
//       'isPassed': isPassed,
//       'durationInSeconds': duration.inSeconds,
//     };
//   }

//   // Create from JSON
//   factory TestSetResult.fromJson(Map<String, dynamic> json) {
//     return TestSetResult(
//       testNumber: json['testNumber'] as int,
//       correctAnswers: json['correctAnswers'] as int,
//       wrongAnswers: json['wrongAnswers'] as int,
//       date: json['date'] as String,
//       isPassed: json['isPassed'] as bool,
//       duration: Duration(seconds: json['durationInSeconds'] as int),
//     );
//   }
// }
