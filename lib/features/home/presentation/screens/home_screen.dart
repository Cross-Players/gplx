import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/routes/app_routes.dart';
import 'package:gplx/features/home/controllers/dead_point_questions_count_provider.dart';
import 'package:gplx/features/home/presentation/widgets/feature_button.dart';
import 'package:gplx/features/settings/presentation/screens/settings_screen.dart';
import 'package:gplx/features/test/models/license_data.dart';
import 'package:gplx/features/test/views/quiz_screen.dart';
import 'package:gplx/features/test_sets/views/test_sets_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licenseType = ref.watch(licenseTypeProvider);
    final deadPointQuestionsCount = ref.watch(deadPointQuestionsCountProvider);

    bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    Future<void> navigateToRandomTest() async {
      try {
        final currentLicenseType = ref.read(licenseTypeProvider);
        final totalTestSets = numberOfTestSetsBasedOnLicense(
          currentLicenseType,
        );

        if (totalTestSets <= 0) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không có đề thi nào cho hạng xe này.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        final random = Random();
        final randomTestNumber = random.nextInt(totalTestSets) + 1;
        final testSetId = '$randomTestNumber-${currentLicenseType.name}';
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(testSetId: testSetId),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
        title: Text(
          'Hạng ${licenseType.name} 2025',
        ),
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TestSetsScreen()),
            ),
          ),
          // FeatureButton(
          //   icon: Icons.person_outline,
          //   label: 'Xem câu bị sai',
          //   color: AppHomeColors.green,
          //   onTap: () async {
          //     try {
          //       if (context.mounted) {
          //         Navigator.pushNamed(
          //           context,
          //           AppRoutes.wrongAnswers,
          //           arguments: {
          //             'title': 'Các câu bị sai',
          //             'questions': wrongAnswerQuestions,
          //           },
          //         );
          //       }
          //     } catch (e) {
          //       if (context.mounted) {
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           SnackBar(
          //             content: Text('Có lỗi xảy ra: $e'),
          //             duration: const Duration(seconds: 3),
          //           ),
          //         );
          //       }
          //     }
          //   },
          // ),
          FeatureButton(
            icon: Icons.book,
            label: 'Ôn tập câu hỏi',
            color: AppHomeColors.teal,
            onTap: () => Navigator.pushNamed(context, AppRoutes.allChapters),
          ),
          FeatureButton(
            icon: Icons.timer,
            label: deadPointQuestionsCount.when(
              data: (count) => '$count Câu điểm liệt',
              loading: () => 'Đang tải...',
              error: (_, __) => '0 Câu điểm liệt',
            ),
            color: AppHomeColors.brown,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.deadpointQuestions,
                  arguments: {
                    'title': 'Câu điểm liệt của hạng ${licenseType.name}',
                    'testSetId': 'deadpoints-${licenseType.name}',
                  });
            },
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

          // FeatureButton(
          //   icon: Icons.star,
          //   label: 'Top 50 câu hay sai',
          //   color: AppHomeColors.blueGrey,
          //   onTap: () {},
          // ),
        ],
      ),
    );
  }
}
