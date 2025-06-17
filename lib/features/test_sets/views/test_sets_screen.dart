import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/features/test/controllers/vehicle_repository.dart';
import 'package:gplx/features/test/models/quiz_result.dart';
import 'package:gplx/features/test/models/vehicle.dart';
import 'package:gplx/features/test/providers/quiz_providers.dart';
import 'package:gplx/features/test/providers/quiz_results_provider.dart';
import 'package:gplx/features/test/providers/vehicle_provider.dart';
import 'package:gplx/features/test/views/quiz_result_summary.dart';
import 'package:gplx/features/test/views/quiz_screen.dart';
import 'package:gplx/features/test_sets/models/test_set.dart';
import 'package:gplx/features/test_sets/providers/test_sets_provider.dart';
import 'package:gplx/features/test_sets/views/components/test_set_card.dart';

class TestSetsScreen extends ConsumerStatefulWidget {
  const TestSetsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TestSetsScreenState();
}

class _TestSetsScreenState extends ConsumerState<TestSetsScreen> {
  static const int _defaultNumberOfSets = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _generateTestSets();
    });
  }

  // Core business logic methods
  Future<void> _generateTestSets() async {
    try {
      final vehicle = ref.read(selectedVehicleTypeProvider);
      final repository = ref.read(testSetRepositoryProvider);

      final savedTestSets = await repository.getTestSets(vehicle.vehicleType);

      if (savedTestSets.isNotEmpty) {
        await _loadExistingTestSets(savedTestSets);
      } else {
        await _createAndSaveNewTestSets(vehicle, repository);
      }
    } catch (e) {
      _showError('Có lỗi khi tải đề thi: $e');
    }
  }

  Future<void> _loadExistingTestSets(List<TestSet> savedTestSets) async {
    final questionsList =
        savedTestSets.map((testSet) => testSet.questionNumbers).toList();

    ref.read(generatedTestSetsProvider.notifier).state = questionsList;
  }

  Future<void> _createAndSaveNewTestSets(
    Vehicle vehicle,
    dynamic repository,
  ) async {
    final questionsList = VehicleRepository().generateMultipleTestSets(
      vehicle.vehicleType,
      _defaultNumberOfSets,
    );

    ref.read(generatedTestSetsProvider.notifier).state = questionsList;

    final testSets = _createTestSetsFromQuestionsList(
      questionsList,
      vehicle.vehicleType,
    );

    await repository.saveTestSets(vehicle.vehicleType, testSets);
  }

  List<TestSet> _createTestSetsFromQuestionsList(
    List<List<int>> questionsList,
    String vehicleType,
  ) {
    return List.generate(questionsList.length, (index) {
      final formattedIndex = (index + 1).toString().padLeft(2, '0');
      final id = '$formattedIndex-$vehicleType';

      return TestSet(
        id: id,
        title: 'Đề số ${index + 1}',
        vehicleType: vehicleType,
        questionNumbers: questionsList[index],
      );
    });
  }

  Future<void> _refreshTestSets() async {
    try {
      _showLoadingSnackBar('Đang tạo bộ đề mới...');

      final vehicle = ref.read(selectedVehicleTypeProvider);
      final repository = ref.read(testSetRepositoryProvider);

      final questionsList = VehicleRepository().generateMultipleTestSets(
        vehicle.vehicleType,
        _defaultNumberOfSets,
      );

      ref.read(generatedTestSetsProvider.notifier).state = questionsList;

      final testSets = _createTestSetsFromQuestionsList(
        questionsList,
        vehicle.vehicleType,
      );

      await repository.saveTestSets(vehicle.vehicleType, testSets);

      if (mounted) {
        _showSuccessSnackBar('Đã tạo bộ đề mới thành công!');
      }
    } catch (e) {
      _showError('Có lỗi khi tạo bộ đề mới: $e');
    }
  }

  // Navigation and quiz handling methods
  Future<void> _handleTestSetTap({
    required QuizResult? quizResult,
    required String testSetId,
    required int testNumber,
    required int questionCount,
    required Vehicle vehicle,
  }) async {
    final isCompleted = quizResult != null;
    final hasSelectedAnswers = _hasValidSelectedAnswers(quizResult);

    if (isCompleted && hasSelectedAnswers) {
      await _showQuizResult(quizResult, testSetId);
    } else {
      _showStartQuizDialog(
        testNumber: testNumber,
        questionCount: questionCount,
        vehicle: vehicle,
        onStart: () => _navigateToQuiz(testSetId),
      );
    }
  }

  bool _hasValidSelectedAnswers(QuizResult? quizResult) {
    return quizResult?.selectedAnswers != null &&
        quizResult!.selectedAnswers!.isNotEmpty;
  }

  Future<void> _showQuizResult(QuizResult quizResult, String testSetId) async {
    try {
      final questions = await ref.read(
        quizQuestionsProvider(testSetId).future,
      );

      if (!mounted) return;

      final selectedAnswers = _convertSelectedAnswersFromStorage(
        quizResult.selectedAnswers,
      );

      _navigateToQuizResultSummary(
        quizResult: quizResult,
        questions: questions,
        selectedAnswers: selectedAnswers,
        testSetId: testSetId,
      );
    } catch (e) {
      _showError('Có lỗi khi tải kết quả: $e');
    }
  }

  Map<int, int> _convertSelectedAnswersFromStorage(
    Map<String, int>? selectedAnswersFromStorage,
  ) {
    final selectedAnswers = <int, int>{};
    selectedAnswersFromStorage?.forEach((key, value) {
      selectedAnswers[int.parse(key)] = value;
    });
    return selectedAnswers;
  }

  void _navigateToQuizResultSummary({
    required QuizResult quizResult,
    required dynamic questions,
    required Map<int, int> selectedAnswers,
    required String testSetId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultSummary(
          quizResult: quizResult,
          questions: questions,
          selectedAnswers: selectedAnswers,
          timeTaken: quizResult.timeTaken ?? Duration.zero,
          onBackPressed: () => Navigator.pop(context),
          onRetakeQuiz: () {
            Navigator.pop(context);
            _navigateToQuiz(testSetId);
          },
        ),
      ),
    );
  }

  void _navigateToQuiz(String testSetId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(testSetId: testSetId),
      ),
    );
  }

  // Dialog methods
  void _showRefreshConfirmationDialog() {
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
            onPressed: () {
              Navigator.pop(context);
              _refreshTestSets();
            },
            child: const Text(
              'TẠO MỚI',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showStartQuizDialog({
    required int testNumber,
    required int questionCount,
    required Vehicle vehicle,
    required VoidCallback onStart,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đề thi số $testNumber'),
        content: _buildQuizDialogContent(
          testNumber: testNumber,
          questionCount: questionCount,
          vehicle: vehicle,
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

  Widget _buildQuizDialogContent({
    required int testNumber,
    required int questionCount,
    required Vehicle vehicle,
  }) {
    return Column(
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
        _buildInfoRow(
          icon: Icons.quiz,
          text: 'Số câu hỏi: $questionCount câu',
        ),
        _buildInfoRow(
          icon: Icons.timer,
          text: 'Thời gian: ${vehicle.minutes} phút',
        ),
        const SizedBox(height: 16),
        const Text(
          'Trong quá trình làm bài, bạn có thể:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._buildInstructionList(),
      ],
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  List<Widget> _buildInstructionList() {
    const instructions = [
      '• Chọn một đáp án và kiểm tra ngay kết quả',
      '• Xem lại các câu đã làm và chưa làm',
      '• Nộp bài bất cứ lúc nào',
    ];

    return instructions.map((instruction) => Text(instruction)).toList();
  }

  void _showDeleteConfirmationDialog() {
    final vehicle = ref.read(selectedVehicleTypeProvider);

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
            onPressed: () => _deleteResults(vehicle.vehicleType),
            child: const Text('XÓA', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteResults(String vehicleType) async {
    try {
      await ref
          .read(quizResultsNotifierProvider.notifier)
          .clearResultsForVehicleType(vehicleType);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Có lỗi khi xóa kết quả: $e');
    }
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _generateTestSetId(int index, String vehicleType) {
    final formattedIndex = (index + 1).toString().padLeft(2, '0');
    return '$formattedIndex-$vehicleType';
  }

  @override
  Widget build(BuildContext context) {
    final testResults = ref.watch(quizResultsNotifierProvider);
    final vehicle = ref.watch(selectedVehicleTypeProvider);
    final testSets = ref.watch(generatedTestSetsProvider);

    return Scaffold(
      appBar: _buildAppBar(vehicle),
      body: _buildBody(testSets, testResults, vehicle),
    );
  }

  PreferredSizeWidget _buildAppBar(Vehicle vehicle) {
    return AppBar(
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
          onPressed: _showRefreshConfirmationDialog,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _showDeleteConfirmationDialog,
        ),
      ],
    );
  }

  Widget _buildBody(
    List<List<int>> testSets,
    dynamic testResults,
    Vehicle vehicle,
  ) {
    if (testSets.isEmpty) {
      return _buildLoadingState();
    }

    return Column(
      children: [
        Expanded(
          child: _buildTestSetsGrid(testSets, testResults, vehicle),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang tạo đề thi...'),
        ],
      ),
    );
  }

  Widget _buildTestSetsGrid(
    List<List<int>> testSets,
    dynamic testResults,
    Vehicle vehicle,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: testSets.length,
      itemBuilder: (context, index) => _buildTestSetItem(
        index: index,
        testSet: testSets[index],
        testResults: testResults,
        vehicle: vehicle,
      ),
    );
  }

  Widget _buildTestSetItem({
    required int index,
    required List<int> testSet,
    required dynamic testResults,
    required Vehicle vehicle,
  }) {
    final testNumber = index + 1;
    final testSetId = _generateTestSetId(index, vehicle.vehicleType);

    final quizResult = testResults.results
        .where((result) => result.quizId == testSetId)
        .firstOrNull;

    final isCompleted = quizResult != null;
    final correct = isCompleted ? quizResult.correctAnswers : 0;
    final wrong = isCompleted ? quizResult.wrongAnswers : 0;

    return TestSetCard(
      testNumber: testNumber,
      questionCount: testSet.length,
      correct: correct,
      wrong: wrong,
      isCompleted: isCompleted,
      isPassed: quizResult?.isPassed,
      onTap: () => _handleTestSetTap(
        quizResult: quizResult,
        testSetId: testSetId,
        testNumber: testNumber,
        questionCount: testSet.length,
        vehicle: vehicle,
      ),
    );
  }
}
