import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/controllers/class_data_repository.dart';
import 'package:gplx/features/test/models/class_data.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String selectedQuestionSet = '600 câu hỏi (Thử nghiệm)';
  @override
  Widget build(BuildContext context) {
    final classDataRepository = ref.watch(classDataRepositoryProvider);
    final availableClassData = classDataRepository.getAllClassData();

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

          // Display ClassData from ClassDataRepository or loading indicator
          ListView.builder(
            itemCount: availableClassData.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final classData = availableClassData[index];
              // Fix the comparison in the ListView.builder
              return _ClassDataOption(
                classData: classData,
                isSelected: ref.watch(selectedClassTypeProvider).classType ==
                    classData.classType,
                onTap: () {
                  // Save selected ClassData to provider
                  ref.read(selectedClassTypeProvider.notifier).state =
                      classData;
                  print('Selected class type: ${classData.classType}');
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

class _ClassDataOption extends StatelessWidget {
  final ClassData classData;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClassDataOption({
    required this.classData,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(classData.classType),
      subtitle: Text(
        classData.description,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: onTap,
    );
  }
}
