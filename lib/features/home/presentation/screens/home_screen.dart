import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/controllers/exam_set_repository.dart';
import 'package:gplx/features/test/controllers/vehicle_repository.dart';
import 'package:gplx/features/test/providers/vehicle_provider.dart';
import 'package:gplx/features/test/views/quiz_screen.dart';
import 'package:gplx/features/test_sets/views/test_sets_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(selectedVehicleTypeProvider);
    final vehicleType = vehicle.vehicleType;
    final classTotalQuestions =
        VehicleRepository.getTotalQuestions(vehicleType);
    final deadPointsLength =
        VehicleRepository.getDeadPointQuestions(vehicleType).length;
    final deadpointsId = 'deadpoints-$vehicleType';

    Future<void> navigateToRandomExam() async {
      try {
        final repository = ref.read(examSetRepositoryProvider);
        final examSets = await repository.getExamSets(vehicleType);
        if (examSets.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Không có đề thi nào để thực hiện. Vui lòng tạo đề thi mới.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
        // Chọn ngẫu nhiên một exam set
        final random = Random();
        final randomExamSet = examSets[random.nextInt(examSets.length)];
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(examSetId: randomExamSet.id),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Có lỗi xảy ra: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
        title: Text('Hạng $vehicleType - $classTotalQuestions câu 2025'),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildFeatureButton(
            context,
            icon: Icons.shuffle,
            label: 'Đề ngẫu nhiên',
            color: Colors.orange,
            onTap: () => navigateToRandomExam(),
          ),
          _buildFeatureButton(
            context,
            icon: Icons.assignment,
            label: 'Thi theo bộ đề',
            color: Colors.red,
            // onTap: () => Navigator.pushNamed(context, '/test-sets'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TestSetsScreen(vehicle: vehicle)),
              );
            },
          ),
          _buildFeatureButton(
            context,
            icon: Icons.person_outline,
            label: 'Xem câu bị sai',
            color: Colors.green,
            onTap: () {},
          ),
          _buildFeatureButton(
            context,
            icon: Icons.book,
            label: 'Ôn tập câu hỏi',
            color: Colors.teal,
            onTap: () {},
          ),
          _buildFeatureButton(
            context,
            icon: Icons.traffic,
            label: 'Các biển báo',
            color: Colors.blue,
            onTap: () => Navigator.pushNamed(context, '/signs'),
          ),
          _buildFeatureButton(
            context,
            icon: Icons.extension,
            label: 'Mẹo ghi nhớ',
            color: Colors.purple,
            onTap: () {},
          ),
          _buildFeatureButton(
            context,
            icon: Icons.timer,
            label: '$deadPointsLength Câu điểm liệt',
            color: Colors.brown,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(examSetId: deadpointsId),
                ),
              );
            },
          ),
          _buildFeatureButton(
            context,
            icon: Icons.star,
            label: 'Top 50 câu sai',
            color: Colors.blueGrey,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
