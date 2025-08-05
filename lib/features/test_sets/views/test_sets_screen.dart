import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/features/test/controllers/vehicle_repository.dart';
import 'package:gplx/features/test/models/vehicle.dart';
import 'package:gplx/features/test/providers/vehicle_provider.dart';
import 'package:gplx/features/test_sets/constants/test_sets_constants.dart';
import 'package:gplx/features/test_sets/models/test_set.dart';
import 'package:gplx/features/test_sets/providers/test_sets_provider.dart';
import 'package:gplx/features/test_sets/utils/test_sets_utils.dart';
import 'package:gplx/features/test_sets/views/components/create_new_test_sets_dialog.dart';
import 'package:gplx/features/test_sets/views/components/delete_results_dialog.dart';
import 'package:gplx/features/test_sets/views/components/test_sets_grid.dart';

class TestSetsScreen extends ConsumerStatefulWidget {
  const TestSetsScreen({super.key});

  @override
  ConsumerState<TestSetsScreen> createState() => _TestSetsScreenState();
}

class _TestSetsScreenState extends ConsumerState<TestSetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeTestSets());
  }

  /// Initialize test sets on screen load
  Future<void> _initializeTestSets() async {
    try {
      await _generateTestSets();
    } catch (e) {
      if (mounted) {
        TestSetsUtils.showErrorSnackBar(context, 'Lỗi khi khởi tạo đề thi: $e');
      }
    }
  }

  /// Generate or load existing test sets
  Future<void> _generateTestSets() async {
    final vehicle = ref.read(selectedVehicleTypeProvider);
    final repository = ref.read(testSetRepositoryProvider);

    final savedTestSets = await repository.getTestSets(vehicle.vehicleType);

    if (savedTestSets.isNotEmpty) {
      _loadExistingTestSets(savedTestSets);
    } else {
      await _createNewTestSets(vehicle, repository);
    }
  }

  /// Load existing test sets from repository
  void _loadExistingTestSets(List<TestSet> savedTestSets) {
    final questionsList =
        savedTestSets.map((testSet) => testSet.questionNumbers).toList();
    ref.read(generatedTestSetsProvider.notifier).state = questionsList;
  }

  /// Create new test sets and save to repository
  Future<void> _createNewTestSets(Vehicle vehicle, repository) async {
    final questionsList = VehicleRepository().generateMultipleTestSets(
      vehicle.vehicleType,
      TestSetsConstants.defaultNumberOfSets,
    );

    ref.read(generatedTestSetsProvider.notifier).state = questionsList;

    final testSets = _convertToTestSets(questionsList, vehicle.vehicleType);
    await repository.saveTestSets(vehicle.vehicleType, testSets);
  }

  /// Convert questions list to TestSet objects
  List<TestSet> _convertToTestSets(
      List<List<int>> questionsList, String vehicleType) {
    return questionsList.asMap().entries.map((entry) {
      final index = entry.key;
      final questions = entry.value;
      final id = TestSetsUtils.formatTestSetId(index, vehicleType);

      return TestSet(
        id: id,
        title: 'Đề số ${index + 1}',
        vehicleType: vehicleType,
        questionNumbers: questions,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final vehicle = ref.watch(selectedVehicleTypeProvider);
        final testSets = ref.watch(generatedTestSetsProvider);

        return Scaffold(
          appBar: _buildAppBar(vehicle),
          body: _buildBody(testSets, vehicle),
        );
      },
    );
  }

  /// Build optimized app bar
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
          onPressed: () => _showCreateNewTestSetsDialog(vehicle),
          tooltip: 'Tạo bộ đề mới',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _showDeleteResultsDialog(vehicle),
          tooltip: 'Xóa kết quả',
        ),
      ],
    );
  }

  /// Build main body with loading state
  Widget _buildBody(List<List<int>> testSets, Vehicle vehicle) {
    if (testSets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(TestSetsConstants.loadingMessage),
          ],
        ),
      );
    }

    return TestSetsGrid(testSets: testSets, vehicle: vehicle);
  }

  /// Show create new test sets dialog
  void _showCreateNewTestSetsDialog(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => CreateNewTestSetsDialog(
        vehicle: vehicle,
        ref: ref,
      ),
    );
  }

  /// Show delete results dialog
  void _showDeleteResultsDialog(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => DeleteResultsDialog(
        vehicle: vehicle,
        ref: ref,
      ),
    );
  }
}
