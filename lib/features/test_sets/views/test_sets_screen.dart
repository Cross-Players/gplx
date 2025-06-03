import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/features/test/controllers/vehicle_repository.dart';
import 'package:gplx/features/test/models/vehicle.dart';
import 'package:gplx/features/test/providers/quiz_results_provider.dart';
import 'package:gplx/features/test/providers/vehicle_provider.dart';
import 'package:gplx/features/test/views/quiz_screen.dart';
import 'package:gplx/features/test_sets/controllers/test_set_repository.dart';
import 'package:gplx/features/test_sets/models/test_set.dart';
import 'package:gplx/features/test_sets/providers/test_sets_provider.dart';

class TestSetsScreen extends ConsumerStatefulWidget {
  const TestSetsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TestSetsScreenState();
}

class _TestSetsScreenState extends ConsumerState<TestSetsScreen> {
  int numberOfSets = 20; // Default number of Test sets
  @override
  void initState() {
    super.initState();
    // Schedule the state update for after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await generateTestSets();
    });
  }

  Future<void> generateTestSets() async {
    final vehicle = ref.watch(selectedVehicleTypeProvider);

    final repository = ref.read(testSetRepositoryProvider);

    // Thử tải các TestSets đã lưu từ repository
    final savedTestSets = await repository.getTestSets(
      vehicle.vehicleType,
    );

    if (savedTestSets.isNotEmpty) {
      // Nếu đã có đề thi được lưu rồi thì dùng danh sách câu hỏi đã lưu
      final questionsList =
          savedTestSets.map((testSet) => testSet.questionNumbers).toList();
      ref.read(generatedTestSetsProvider.notifier).state = questionsList;
    } else {
      // Nếu chưa có, tạo mới và lưu trữ
      final questionsList = VehicleRepository().generateMultipleRandomTestSets(
        vehicle.vehicleType,
        numberOfSets,
      );

      // Lưu vào state provider (cho ListView hiển thị)
      ref.read(generatedTestSetsProvider.notifier).state = questionsList;

      // Chuyển đổi List<List<int>> thành List<TestSet> với ID định dạng
      final testSets = <TestSet>[];
      for (int i = 0; i < questionsList.length; i++) {
        final formattedIndex = (i + 1).toString().padLeft(2, '0');
        final id = '$formattedIndex-${vehicle.vehicleType}';

        testSets.add(
          TestSet(
            id: id,
            title: 'Đề số ${i + 1}',
            vehicleType: vehicle.vehicleType,
            questionNumbers: questionsList[i],
            description:
                'Bộ đề thi thử ${vehicle.vehicleType} với ${questionsList[i].length} câu hỏi',
          ),
        );
      }

      // Lưu danh sách TestSets vào repository
      await repository.saveTestSets(vehicle.vehicleType, testSets);
    }
  }

  @override
  Widget build(BuildContext context) {
    final testResults = ref.watch(quizResultsNotifierProvider);
    final vehicle = ref.watch(selectedVehicleTypeProvider);
    final testSets = ref.watch(generatedTestSetsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Đề thi hạng ${vehicle.vehicleType}'),
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
                          testSetRepositoryProvider,
                        );
                        final questionsList =
                            VehicleRepository().generateMultipleRandomTestSets(
                          vehicle.vehicleType,
                          numberOfSets,
                        );

                        // Lưu vào state provider
                        ref.read(generatedTestSetsProvider.notifier).state =
                            questionsList;

                        // Chuyển đổi thành danh sách TestSet
                        final testSets = <TestSet>[];
                        for (int i = 0; i < questionsList.length; i++) {
                          final formattedIndex = (i + 1).toString().padLeft(
                                2,
                                '0',
                              );
                          final id = '$formattedIndex-${vehicle.vehicleType}';

                          testSets.add(
                            TestSet(
                              id: id,
                              title: 'Đề số ${i + 1}',
                              vehicleType: vehicle.vehicleType,
                              questionNumbers: questionsList[i],
                              description:
                                  'Bộ đề thi thử ${vehicle.vehicleType} với ${questionsList[i].length} câu hỏi',
                            ),
                          );
                        }

                        // Lưu danh sách mới vào repository
                        await repository.saveTestSets(
                          vehicle.vehicleType,
                          testSets,
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
              _showDeleteConfirmationDialog(context, ref, vehicle);
            },
          ),
        ],
      ),
      body: testSets.isEmpty
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
                    itemCount: testSets.length,
                    itemBuilder: (context, index) {
                      final testSet =
                          testSets[index]; // List of question numbers
                      final testNumber = index + 1;

                      // Format ID theo dạng: Số thứ tự đề - Tên hạng xe (ví dụ: 01-A1)
                      final formattedIndex = (index + 1).toString().padLeft(
                            2,
                            '0',
                          );
                      final testSetId =
                          '$formattedIndex-${vehicle.vehicleType}';

                      // Find the result for this quiz by TestSetId only
                      final quizResult = testResults.results
                          .where((result) => result.quizId == testSetId)
                          .firstOrNull;

                      // Use saved result data if available, otherwise use default values
                      final isCompleted = quizResult != null;
                      final correct =
                          isCompleted ? quizResult.correctAnswers : 0;
                      final wrong = isCompleted ? quizResult.wrongAnswers : 0;

                      return _TestSetCard(
                        testNumber: testNumber,
                        questionCount: testSet.length,
                        correct: correct,
                        wrong: wrong,
                        isCompleted: isCompleted,
                        isPassed: quizResult?.isPassed,
                        onTap: () {
                          _showStartQuizDialog(
                            context,
                            testNumber,
                            testSet.length,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      QuizScreen(testSetId: testSetId),
                                ),
                              );
                            },
                            vehicle,
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
    Vehicle vehicle,
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
                  'Thời gian: ${vehicle.minutes} phút',
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

  void _showDeleteConfirmationDialog(
      BuildContext context, WidgetRef ref, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa kết quả hạng ${vehicle.vehicleType}?'),
        content: Text(
          'Bạn có chắc chắn muốn xóa tất cả kết quả bài thi hạng ${vehicle.vehicleType} không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY'),
          ),
          TextButton(
            onPressed: () {
              // Clear results for current Vehicle type only
              ref
                  .read(quizResultsNotifierProvider.notifier)
                  .clearResultsForVehicleType(vehicle.vehicleType)
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
