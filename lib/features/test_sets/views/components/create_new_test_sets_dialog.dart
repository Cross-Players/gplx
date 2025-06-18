import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/controllers/vehicle_repository.dart';
import 'package:gplx/features/test/models/vehicle.dart';
import 'package:gplx/features/test_sets/constants/test_sets_constants.dart';
import 'package:gplx/features/test_sets/models/test_set.dart';
import 'package:gplx/features/test_sets/providers/test_sets_provider.dart';
import 'package:gplx/features/test_sets/utils/test_sets_utils.dart';

/// Dialog for confirming creation of new test sets
class CreateNewTestSetsDialog extends StatelessWidget {
  final Vehicle vehicle;
  final WidgetRef ref;

  const CreateNewTestSetsDialog({
    super.key,
    required this.vehicle,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(TestSetsConstants.createNewTestSetsTitle),
      content: const Text(TestSetsConstants.createNewTestSetsContent),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(TestSetsConstants.cancelButton),
        ),
        TextButton(
          onPressed: () => _createNewTestSets(context),
          child: const Text(
            TestSetsConstants.createNewButton,
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Future<void> _createNewTestSets(BuildContext context) async {
    Navigator.pop(context);

    // Show loading
    TestSetsUtils.showLoadingSnackBar(
      context,
      TestSetsConstants.creatingMessage,
    );

    try {
      // Generate new test sets
      final repository = ref.read(testSetRepositoryProvider);
      final questionsList = VehicleRepository().generateMultipleTestSets(
        vehicle.vehicleType,
        TestSetsConstants.defaultNumberOfSets,
      );

      // Update state
      ref.read(generatedTestSetsProvider.notifier).state = questionsList;

      // Convert to TestSet objects
      final testSets = <TestSet>[];
      for (int i = 0; i < questionsList.length; i++) {
        final id = TestSetsUtils.formatTestSetId(i, vehicle.vehicleType);
        testSets.add(
          TestSet(
            id: id,
            title: 'Đề số ${i + 1}',
            vehicleType: vehicle.vehicleType,
            questionNumbers: questionsList[i],
          ),
        );
      }

      // Save to repository
      await repository.saveTestSets(vehicle.vehicleType, testSets);

      // Show success message
      if (context.mounted) {
        TestSetsUtils.showSuccessSnackBar(
          context,
          TestSetsConstants.successMessage,
        );
      }
    } catch (e) {
      if (context.mounted) {
        TestSetsUtils.showErrorSnackBar(
          context,
          'Có lỗi khi tạo đề thi: $e',
        );
      }
    }
  }
}
