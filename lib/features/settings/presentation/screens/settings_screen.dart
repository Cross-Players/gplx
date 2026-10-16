import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
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
  late LicenseType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = ref.read(licenseTypeProvider);
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
            backgroundColor: AppPalette.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa bộ nhớ đệm: $e'),
            backgroundColor: AppPalette.danger,
          ),
        );
      }
    }
  }

  void _save() {
    ref.read(licenseTypeProvider.notifier).setLicenseType(_selectedType);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: const Text('Thiết lập'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Xong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, 24 + MediaQuery.of(context).padding.bottom),
        children: [
          const _SectionHeader(title: 'Hạng bằng lái'),
          for (final vehicle in allVehicles) ...[
            _VehicleOption(
              vehicle: vehicle,
              isSelected: _selectedType == vehicle.vehicleType,
              onTap: () {
                setState(() {
                  _selectedType = vehicle.vehicleType;
                });
              },
            ),
            const SizedBox(height: 10),
          ],
          const _SectionHeader(title: 'Dữ liệu'),
          _ActionTile(
            icon: Icons.cleaning_services_rounded,
            title: 'Xóa bộ nhớ đệm',
            subtitle: 'Tải lại câu hỏi từ máy chủ',
            onTap: _showClearCacheDialog,
          ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: AppPalette.inkMuted,
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
    return Material(
      color: isSelected ? AppPalette.primarySoft : AppPalette.surface,
      borderRadius: BorderRadius.circular(AppPalette.radiusM),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppPalette.radiusM),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppPalette.radiusM),
            border: Border.all(
              color: isSelected ? AppPalette.primary : AppPalette.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppPalette.primary
                      : AppPalette.background,
                  borderRadius: BorderRadius.circular(AppPalette.radiusS),
                ),
                child: Text(
                  vehicle.vehicleType.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppPalette.ink,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hạng ${vehicle.vehicleType.name}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      vehicle.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppPalette.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                        key: ValueKey(true), color: AppPalette.primary)
                    : const Icon(Icons.circle_outlined,
                        key: ValueKey(false), color: AppPalette.border),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppPalette.primarySoft,
            borderRadius: BorderRadius.circular(AppPalette.radiusS),
          ),
          child: Icon(icon, color: AppPalette.primary, size: 22),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
