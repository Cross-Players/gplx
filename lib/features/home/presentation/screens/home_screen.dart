import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/services/firebase/auth_services.dart';
import 'package:gplx/features/exercise/views/exercise_screen.dart';
import 'package:gplx/core/routes/app_routes.dart';
import 'package:gplx/features/test/controllers/questions_repository.dart';
import 'package:gplx/features/test/controllers/vehicle_repository.dart';
import 'package:gplx/features/test/providers/vehicle_provider.dart';
import 'package:gplx/features/test/views/quiz_screen.dart';
import 'package:gplx/features/test_sets/providers/test_sets_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(selectedVehicleTypeProvider);
    final vehicleType = vehicle.vehicleType;
    final vehicleTotalQuestions =
        VehicleRepository().getTotalQuestions(vehicleType);
    final deadPointsLength =
        VehicleRepository().getDeadPointQuestions(vehicleType).length;
    final deadpointsId = 'deadpoints-$vehicleType';
    final wrongAnswerQuestions =
        QuestionRepository().fetchQuestionsByIsCorrect(vehicleType);

    bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    Future<void> navigateToRandomTest() async {
      try {
        final repository = ref.read(testSetRepositoryProvider);
        final testSets = await repository.getTestSets(vehicleType);
        if (testSets.isEmpty) {
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
        // Chọn ngẫu nhiên một Test set
        final random = Random();
        final randomTestSet = testSets[random.nextInt(testSets.length)];
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(testSetId: randomTestSet.id),
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
        leading: RotatedBox(
          quarterTurns: 2,
          child: IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              try {
                await authServices.value.signOut();
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
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
        title: Text('Hạng $vehicleType - $vehicleTotalQuestions câu 2025'),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: isPortrait ? 2 : 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildFeatureButton(
            context,
            icon: Icons.shuffle,
            label: 'Đề ngẫu nhiên',
            color: Colors.orange,
            onTap: () => navigateToRandomTest(),
          ),
          _buildFeatureButton(
            context,
            icon: Icons.assignment,
            label: 'Thi theo bộ đề',
            color: Colors.red,
            onTap: () => Navigator.pushNamed(context, '/test-sets'),
          ),
          _buildFeatureButton(
            context,
            icon: Icons.person_outline,
            label: 'Xem câu bị sai',
            color: Colors.green,
            onTap: () async {
              try {
                if (context.mounted) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.wrongAnswers,
                    arguments: {
                      'title': 'Các câu bị sai',
                      'questions': wrongAnswerQuestions,
                    },
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
            },
          ),
          _buildFeatureButton(
            context,
            icon: Icons.book,
            label: 'Ôn tập câu hỏi',
            color: Colors.teal,
            onTap: () => Navigator.pushNamed(context, AppRoutes.allChapters),
          ),
          _buildFeatureButton(
            context,
            icon: Icons.traffic,
            label: 'Các biển báo',
            color: Colors.blue,
            onTap: () => Navigator.pushNamed(context, AppRoutes.signs),
          ),
          _buildFeatureButton(
            context,
            icon: Icons.extension,
            label: 'Mẹo ghi nhớ',
            color: Colors.purple,
            onTap: () => Navigator.pushNamed(context, AppRoutes.tips),
          ),
          _buildFeatureButton(
            context,
            icon: Icons.timer,
            label: '$deadPointsLength Câu điểm liệt',
            color: Colors.brown,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.deadpointQuestions,
                arguments: deadpointsId,
              );
            },
          ),
          _buildFeatureButton(
            context,
            icon: Icons.star,
            label: 'Top 50 câu hay sai',
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
