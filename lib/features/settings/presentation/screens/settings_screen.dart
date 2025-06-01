import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/data/local_storage.dart';
import 'package:gplx/features/test/models/vehicle.dart';
import 'package:gplx/features/test/providers/vehicle_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String selectedQuestionSet = '600 câu hỏi (Thử nghiệm)';
  @override
  Widget build(BuildContext context) {
    final vehicleRepository = ref.watch(vehicleRepositoryProvider);
    final availableVehicle = vehicleRepository.getAllVehicle();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết lập'),
        actions: [
          TextButton(
            onPressed: () {
              // Save settings
              Navigator.pop(context);
            },
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'BỘ ĐỀ THI'),
          RadioListTile(
            title: const Text('450 câu hỏi'),
            value: '450 câu hỏi',
            groupValue: selectedQuestionSet,
            onChanged: (value) {
              setState(() {
                selectedQuestionSet = value.toString();
              });
            },
          ),
          RadioListTile(
            title: const Text('600 câu hỏi (Thử nghiệm)'),
            value: '600 câu hỏi (Thử nghiệm)',
            groupValue: selectedQuestionSet,
            onChanged: (value) {
              setState(() {
                selectedQuestionSet = value.toString();
              });
            },
          ),
          const _SectionHeader(title: 'LOẠI BẰNG LÁI XE Ô TÔ'),
          ListView.builder(
            itemCount: availableVehicle.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final vehicle = availableVehicle[index];
              return _VehicleOption(
                vehicle: vehicle,
                isSelected:
                    ref.watch(selectedVehicleTypeProvider).vehicleType ==
                        vehicle.vehicleType,
                onTap: () {
                  // Update state
                  ref.read(selectedVehicleTypeProvider.notifier).state =
                      vehicle;

                  // Save to SharedPreferences
                  ref
                      .read(localStorageProvider)
                      .saveSelectedVehicleType(vehicle.vehicleType);
                  print(
                      'Selected vehicle type: ${vehicle.vehicleType} - Saved to preferences');
                },
              );
            },
          )
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.grey[100],
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class _VehicleOption extends StatelessWidget {
  final Vehicle vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleOption({
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(vehicle.vehicleType),
      subtitle: Text(
        vehicle.description,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: onTap,
    );
  }
}
