import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/models/vehicle.dart';
import 'package:gplx/features/test/providers/quiz_results_provider.dart';
import 'package:gplx/features/test_sets/constants/test_sets_constants.dart';

/// Dialog for confirming deletion of quiz results
class DeleteResultsDialog extends StatelessWidget {
  final Vehicle vehicle;
  final WidgetRef ref;

  const DeleteResultsDialog({
    super.key,
    required this.vehicle,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          '${TestSetsConstants.deleteResultsTitle}${vehicle.vehicleType}?'),
      content: Text(
        '${TestSetsConstants.deleteResultsContent}${vehicle.vehicleType} không?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(TestSetsConstants.cancelButton),
        ),
        TextButton(
          onPressed: () {
            ref
                .read(quizResultsNotifierProvider.notifier)
                .clearResultsForVehicleType(vehicle.vehicleType)
                .then((_) {
              if (context.mounted) {
                Navigator.pop(context);
              }
            });
          },
          child: const Text(
            TestSetsConstants.deleteButton,
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
