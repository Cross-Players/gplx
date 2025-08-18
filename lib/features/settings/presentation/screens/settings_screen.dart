import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String selectedQuestionSet = '600 câu hỏi (Thử nghiệm)';
  String selectedLicenseType = 'Bằng B2';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Thiết lập'),
        actions: [
          TextButton(
            onPressed: () {
              // Save settings
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
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
          _LicenseTypeOption(
            title: 'Bằng A2',
            subtitle: 'Xe mô tô 2 bánh có dung tích xy lanh từ 175 cm3 trở lên',
            isSelected: selectedLicenseType == 'Bằng A2',
            onTap: () => setState(() => selectedLicenseType = 'Bằng A2'),
          ),
          _LicenseTypeOption(
            title: 'Bằng A3',
            subtitle: 'Xe mô tô 3 bánh',
            isSelected: selectedLicenseType == 'Bằng A3',
            onTap: () => setState(() => selectedLicenseType = 'Bằng A3'),
          ),
          _LicenseTypeOption(
            title: 'Bằng A4',
            subtitle: 'Xe máy kéo nhỏ có trọng tải đến 1000kg',
            isSelected: selectedLicenseType == 'Bằng A4',
            onTap: () => setState(() => selectedLicenseType = 'Bằng A4'),
          ),
          _LicenseTypeOption(
            title: 'Bằng B1',
            subtitle:
                'Không hành nghề lái xe, xe đến 9 chỗ ngồi, xe trọng tải dưới 3.500kg',
            isSelected: selectedLicenseType == 'Bằng B1',
            onTap: () => setState(() => selectedLicenseType = 'Bằng B1'),
          ),
          _LicenseTypeOption(
            title: 'Bằng B2',
            subtitle:
                'Cho phép hành nghề lái xe, xe đến 9 chỗ ngồi, xe trọng tải dưới 3.500kg',
            isSelected: selectedLicenseType == 'Bằng B2',
            onTap: () => setState(() => selectedLicenseType = 'Bằng B2'),
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

class _LicenseTypeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LicenseTypeOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: onTap,
    );
  }
}
