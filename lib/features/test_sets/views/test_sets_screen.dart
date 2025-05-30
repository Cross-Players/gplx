import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/features/test/controllers/class_data_repository.dart';
import 'package:gplx/features/test/controllers/exam_set_repository.dart';
import 'package:gplx/features/test/models/class_data.dart';
import 'package:gplx/features/test/views/quiz_screen.dart';
import 'package:gplx/features/test_sets/controllers/test_results_provider.dart';
import 'package:gplx/features/test_sets/models/exam_set.dart';

// Provider để lưu trữ các đề thi đã được generate
final generatedExamSetsProvider = StateProvider<List<List<int>>>((ref) => []);

class TestSetsScreen extends ConsumerStatefulWidget {
  final ClassData classData;

  const TestSetsScreen({super.key, required this.classData});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TestSetsScreenState();
}

class _TestSetsScreenState extends ConsumerState<TestSetsScreen> {
  int numberOfSets = 20; // Default number of exam sets
  @override
  void initState() {
    super.initState();
    // Schedule the state update for after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await generateExamSets();
    });
  }

  Future<void> generateExamSets() async {
    final repository = ref.read(examSetRepositoryProvider);

    // Thử tải các ExamSets đã lưu từ repository
    final savedExamSets = await repository.getExamSets(
      widget.classData.classType,
    );

    if (savedExamSets.isNotEmpty) {
      // Nếu đã có đề thi được lưu, sử dụng chúng
      final questionsList =
          savedExamSets.map((examSet) => examSet.questionNumbers).toList();
      ref.read(generatedExamSetsProvider.notifier).state = questionsList;
    } else {
      // Nếu chưa có, tạo mới và lưu trữ
      final questionsList = ClassDataRepository.generateMultipleRandomExamSets(
        widget.classData.classType,
        numberOfSets,
      );

      // Lưu vào state provider (cho ListView hiển thị)
      ref.read(generatedExamSetsProvider.notifier).state = questionsList;

      // Chuyển đổi List<List<int>> thành List<ExamSet> với ID định dạng
      final examSets = <ExamSet>[];
      for (int i = 0; i < questionsList.length; i++) {
        final formattedIndex = (i + 1).toString().padLeft(2, '0');
        final id = '$formattedIndex-${widget.classData.classType}';

        examSets.add(
          ExamSet(
            id: id,
            title: 'Đề số ${i + 1}',
            classType: widget.classData.classType,
            questionNumbers: questionsList[i],
            createdAt: DateTime.now(),
            description:
                'Bộ đề thi thử ${widget.classData.classType} với ${questionsList[i].length} câu hỏi',
          ),
        );
      }

      // Lưu danh sách ExamSets vào repository
      await repository.saveExamSets(widget.classData.classType, examSets);
    }
  }

  @override
  Widget build(BuildContext context) {
    final testResults = ref.watch(testResultsNotifierProvider);
    final classData = ref.watch(selectedClassTypeProvider);
    final examSets = ref.watch(generatedExamSetsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Đề thi hạng ${classData.classType}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Hiển thị hộp thoại xác nhận trước khi tạo bộ đề mới
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Tạo bộ đề mới?'),
                  content: const Text(
                    'Bạn có chắc chắn muốn tạo bộ đề thi mới? Các đề thi hiện tại sẽ bị thay thế.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('HỦY'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);

                        // Hiển thị loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đang tạo bộ đề mới...'),
                            duration: Duration(seconds: 1),
                          ),
                        );

                        // Tạo các đề thi mới
                        final repository = ref.read(
                          examSetRepositoryProvider,
                        );
                        final questionsList =
                            ClassDataRepository.generateMultipleRandomExamSets(
                          widget.classData.classType,
                          numberOfSets,
                        );

                        // Lưu vào state provider
                        ref.read(generatedExamSetsProvider.notifier).state =
                            questionsList;

                        // Chuyển đổi thành danh sách ExamSet
                        final examSets = <ExamSet>[];
                        for (int i = 0; i < questionsList.length; i++) {
                          final formattedIndex = (i + 1).toString().padLeft(
                                2,
                                '0',
                              );
                          final id =
                              '$formattedIndex-${widget.classData.classType}';

                          examSets.add(
                            ExamSet(
                              id: id,
                              title: 'Đề số ${i + 1}',
                              classType: widget.classData.classType,
                              questionNumbers: questionsList[i],
                              createdAt: DateTime.now(),
                              description:
                                  'Bộ đề thi thử ${widget.classData.classType} với ${questionsList[i].length} câu hỏi',
                            ),
                          );
                        }

                        // Lưu danh sách mới vào repository
                        await repository.saveExamSets(
                          widget.classData.classType,
                          examSets,
                        );

                        // Thông báo thành công
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã tạo bộ đề mới thành công!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'TẠO MỚI',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _showDeleteConfirmationDialog(context, ref);
            },
          ),
        ],
      ),
      body: examSets.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tạo đề thi...'),
                ],
              ),
            )
          : Column(
              children: [
                // Nút làm đề ngẫu nhiên
                // Padding(
                //   padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                //   child: ElevatedButton.icon(
                //     icon: const Icon(Icons.shuffle),
                //     label: const Text('LÀM ĐỀ NGẪU NHIÊN'),
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.green,
                //       foregroundColor: Colors.white,
                //       minimumSize: const Size.fromHeight(45),
                //     ),
                //     onPressed: () async {
                //       // Lấy repository
                //       final repository = ref.read(examSetRepositoryProvider);

                //       // Tạo ID cho đề ngẫu nhiên
                //       final examSetId = '00-${widget.classData.classType}';

                //       // Kiểm tra xem đã có đề ngẫu nhiên này chưa
                //       final existingExamSet = await repository.getExamSetById(
                //         examSetId,
                //       );

                //       if (existingExamSet == null) {
                //         // Nếu chưa có, tạo mới đề ngẫu nhiên
                //         final questionNumbers =
                //             ClassDataRepository.generateRandomExamSet(
                //               widget.classData.classType,
                //             );

                //         // Tạo ExamSet mới
                //         final randomExamSet = ExamSet(
                //           id: examSetId,
                //           title: 'Đề ngẫu nhiên',
                //           classType: widget.classData.classType,
                //           questionNumbers: questionNumbers,
                //           createdAt: DateTime.now(),
                //           description:
                //               'Bộ đề thi thử ${widget.classData.classType} ngẫu nhiên với ${questionNumbers.length} câu hỏi',
                //         );

                //         // Lưu ExamSet vào SharedPreferences
                //         await repository.saveExamSets('random', [
                //           randomExamSet,
                //         ]);
                //       }

                //       // Hiển thị dialog xác nhận
                //       _showStartQuizDialog(context, 0, 25, () {
                //         // Chuyển đến màn hình quiz với ID đề thi
                //         Navigator.push(
                //           context,
                //           MaterialPageRoute(
                //             builder:
                //                 (context) => QuizScreen(examSetId: examSetId),
                //           ),
                //         );
                //       });
                //     },
                //   ),
                // ),

                // GridView hiển thị các đề thi
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: examSets.length,
                    itemBuilder: (context, index) {
                      final examSet =
                          examSets[index]; // List of question numbers
                      final testNumber = index + 1;

                      // Format ID theo dạng: Số thứ tự đề - Tên hạng xe (ví dụ: 01-A1)
                      final formattedIndex = (index + 1).toString().padLeft(
                            2,
                            '0',
                          );
                      final examSetId =
                          '$formattedIndex-${widget.classData.classType}';

                      // Để tương thích với ID cũ cho việc tìm kiếm kết quả
                      final quizId =
                          'test_${widget.classData.classType}_$testNumber';

                      // Find the result for this quiz if it exists
                      final quizResult = testResults.results
                          .where(
                            (result) =>
                                result.quizId == quizId ||
                                _extractTestNumber(
                                      result.quizId,
                                      result.quizTitle,
                                    ) ==
                                    testNumber,
                          )
                          .firstOrNull;

                      // Use saved result data if available, otherwise use default values
                      final isCompleted = quizResult != null;
                      final correct =
                          isCompleted ? quizResult.correctAnswers : 0;
                      final wrong = isCompleted ? quizResult.wrongAnswers : 0;

                      return _TestSetCard(
                        testNumber: testNumber,
                        questionCount: examSet.length,
                        correct: correct,
                        wrong: wrong,
                        isCompleted: isCompleted,
                        isPassed: quizResult?.isPassed,
                        onTap: () {
                          _showStartQuizDialog(
                            context,
                            testNumber,
                            examSet.length,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      QuizScreen(examSetId: examSetId),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _showStartQuizDialog(
    BuildContext context,
    int testNumber,
    int questionCount,
    VoidCallback onStart,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đề thi số $testNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn sắp làm đề thi số $testNumber',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.quiz, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Số câu hỏi: $questionCount câu',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.timer, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Thời gian: ${widget.classData.classType == 'A1' ? '19' : '21'} phút',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Trong quá trình làm bài, bạn có thể:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Chọn một đáp án và kiểm tra ngay kết quả'),
            const Text('• Xem lại các câu đã làm và chưa làm'),
            const Text('• Nộp bài bất cứ lúc nào'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onStart();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('BẮT ĐẦU'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả kết quả?'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả kết quả bài thi không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY'),
          ),
          TextButton(
            onPressed: () {
              // Clear all saved test results using the notifier
              ref
                  .read(testResultsNotifierProvider.notifier)
                  .clearResults()
                  .then((_) {
                Navigator.pop(context);
              });
            },
            child: const Text('XÓA', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  int _extractTestNumber(String id, String title) {
    // Extract test number from the quiz ID or title
    final RegExp regExp = RegExp(r'(\d+)');
    final match = regExp.firstMatch(id) ?? regExp.firstMatch(title);
    return match != null ? int.tryParse(match.group(0) ?? '0') ?? 0 : 0;
  }
}

class _TestSetCard extends StatelessWidget {
  final int testNumber;
  final int questionCount;
  final int correct;
  final int wrong;
  final bool isCompleted;
  final bool? isPassed;
  final VoidCallback onTap;

  const _TestSetCard({
    required this.testNumber,
    required this.questionCount,
    required this.correct,
    required this.wrong,
    required this.isCompleted,
    required this.onTap,
    required this.isPassed,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isCompleted
        ? (isPassed == false ? AppStyles.errorColor : Colors.green[700])
        : Colors.grey[200];

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            const Spacer(),
            Text(
              'ĐỀ THI SỐ $testNumber',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCompleted ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              '$questionCount câu hỏi',
              style: TextStyle(
                fontSize: 12,
                color: isCompleted ? Colors.white70 : Colors.black54,
              ),
            ),
            const Spacer(),
            if (isCompleted) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: Colors.grey[300]),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: AppStyles.iconSizeM,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$correct',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: AppStyles.fontSizeL,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.cancel,
                      color: Colors.red[700],
                      size: AppStyles.iconSizeM,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$wrong',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: AppStyles.fontSizeL,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
