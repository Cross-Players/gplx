import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/routes/app_routes.dart';
import 'package:gplx/core/services/firebase/auth_services.dart';
import 'package:gplx/core/widgets/gradient_app_bar.dart';
import 'package:gplx/features/test/models/license_data.dart';
import 'package:gplx/features/test/models/vehicle.dart';
import 'package:gplx/features/test_sets/controllers/test_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // String selectedQuestionSet = '600 câu hỏi (Thử nghiệm)';
  late LicenseType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = ref.read(licenseTypeProvider);
  }

  Future<void> _showDeleteAccountDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xóa tài khoản'),
          content: const Text(
            'Bạn có chắc chắn muốn xóa tài khoản không?\n\n'
            'Hành động này không thể hoàn tác và tất cả dữ liệu của bạn sẽ bị xóa vĩnh viễn.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteAccount();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Xóa tài khoản'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showClearCacheDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xóa bộ nhớ đệm'),
          content: const Text(
            'Bạn có muốn xóa bộ nhớ đệm câu hỏi điểm liệt không?\n\n'
            'Dữ liệu sẽ được tải lại từ máy chủ lần tới.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _clearCache();
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearCache() async {
    try {
      await TestController.clearAllCache();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa bộ nhớ đệm thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa bộ nhớ đệm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    try {
      await authServices.value.deleteAccount();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.login, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa tài khoản: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: const Text('Thiết lập'),
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(licenseTypeProvider.notifier)
                  .setLicenseType(_selectedType);
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
          const _SectionHeader(title: 'CÁC LOẠI BẰNG LÁI XE'),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allVehicles.length,
            itemBuilder: (context, index) {
              final vehicle = allVehicles[index];
              return _VehicleOption(
                vehicle: vehicle,
                isSelected: _selectedType == vehicle.vehicleType,
                onTap: () {
                  setState(() {
                    _selectedType = vehicle.vehicleType;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 16),
          const LogoutButton(),
          const SizedBox(height: 16),
          ClearCacheButton(
            onPressed: _showClearCacheDialog,
          ),
          const SizedBox(height: 16),
          DeleteAccountButton(
            onPressed: _showDeleteAccountDialog,
          ),
          const SizedBox(height: 16),
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
      child: Text(title, style: AppSettingsTextStyles.section),
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
      title: Text(vehicle.vehicleType.name),
      subtitle: Text(
        vehicle.description,
        style: AppSettingsTextStyles.vehicleDesc,
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check,
              color: AppSettingsColors.vehicleSelected,
            )
          : null,
      onTap: onTap,
    );
  }
}

class DeleteAccountButton extends StatelessWidget {
  final VoidCallback onPressed;

  const DeleteAccountButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: AppSettingsPaddings.logout,
        margin: AppSettingsPaddings.logoutMargin,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Xóa tài khoản',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.delete_forever,
              color: Colors.red[700],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class ClearCacheButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ClearCacheButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: AppSettingsPaddings.logout,
        margin: AppSettingsPaddings.logoutMargin,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Xóa bộ nhớ đệm',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.cleaning_services,
              color: Colors.blue[700],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
