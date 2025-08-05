import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/data/local_storage.dart';
import 'package:gplx/core/routes/app_routes.dart';
import 'package:gplx/core/services/firebase/auth_services.dart';
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
                  // ignore: avoid_print
                  print(
                      'Selected vehicle type: ${vehicle.vehicleType} - Saved to preferences');
                },
              );
            },
          ),
          const SizedBox(height: 16),
          const LogoutButton(),
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
      padding: AppSettingsPaddings.section,
      color: AppSettingsColors.sectionBg,
      child: Text(
        title,
        style: AppSettingsTextStyles.section,
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          await authServices.value.signOut();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.login, (route) => false);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi khi đăng xuất: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: AppSettingsPaddings.logout,
        margin: AppSettingsPaddings.logoutMargin,
        decoration: BoxDecoration(
          color: AppSettingsColors.logoutBg,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Đăng xuất', style: AppSettingsTextStyles.logout),
            SizedBox(width: 8),
            Icon(Icons.logout, color: AppSettingsColors.logoutIcon, size: 18),
          ],
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
      subtitle:
          Text(vehicle.description, style: AppSettingsTextStyles.vehicleDesc),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppSettingsColors.vehicleSelected)
          : null,
      onTap: onTap,
    );
  }
}
