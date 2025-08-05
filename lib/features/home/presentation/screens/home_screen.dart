import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/routes/app_routes.dart';
import 'package:gplx/features/home/presentation/widgets/feature_button.dart';
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
          FeatureButton(
            icon: Icons.shuffle,
            label: 'Đề ngẫu nhiên',
            color: AppHomeColors.orange,
            onTap: () => navigateToRandomTest(),
          ),
          FeatureButton(
            icon: Icons.assignment,
            label: 'Thi theo bộ đề',
            color: AppHomeColors.red,
            onTap: () => Navigator.pushNamed(context, '/test-sets'),
          ),
          FeatureButton(
            icon: Icons.person_outline,
            label: 'Xem câu bị sai',
            color: AppHomeColors.green,
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
          FeatureButton(
            icon: Icons.book,
            label: 'Ôn tập câu hỏi',
            color: AppHomeColors.teal,
            onTap: () => Navigator.pushNamed(context, AppRoutes.allChapters),
          ),
          FeatureButton(
            icon: Icons.traffic,
            label: 'Các biển báo',
            color: AppHomeColors.blue,
            onTap: () => Navigator.pushNamed(context, AppRoutes.signs),
          ),
          FeatureButton(
            icon: Icons.extension,
            label: 'Mẹo ghi nhớ',
            color: AppHomeColors.purple,
            onTap: () => Navigator.pushNamed(context, AppRoutes.tips),
          ),
          FeatureButton(
            icon: Icons.timer,
            label: '$deadPointsLength Câu điểm liệt',
            color: AppHomeColors.brown,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.deadpointQuestions,
                arguments: deadpointsId,
              );
            },
          ),
          FeatureButton(
            icon: Icons.star,
            label: 'Top 50 câu hay sai',
            color: AppHomeColors.blueGrey,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
