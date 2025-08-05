import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/features/test/models/vehicle.dart';
import 'package:gplx/features/test/providers/quiz_providers.dart';
import 'package:gplx/features/test/providers/vehicle_provider.dart';
import 'package:gplx/features/test_sets/providers/answered_questions_provider.dart';
import 'package:gplx/features/exercise/views/exercise_screen.dart';

class AllChapterScreen extends ConsumerStatefulWidget {
  const AllChapterScreen({super.key});

  @override
  ConsumerState<AllChapterScreen> createState() => _AllChapterScreenState();
}

class _AllChapterScreenState extends ConsumerState<AllChapterScreen> {
  late TextEditingController searchController;

  @override
  void initState() {
    searchController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(selectedVehicleTypeProvider);
    final vehicleType = vehicle.vehicleType;
    final questionLength = ref
        .watch(vehicleRepositoryProvider)
        .getAllQuestions(vehicleType)
        .length;

    final allChapters =
        ref.watch(vehicleRepositoryProvider).getAllChapters(vehicle);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hạng $vehicleType - Ôn $questionLength câu'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: TextField(
                      onSubmitted: (searchText) {
                        if (searchText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập từ khóa tìm kiếm'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        searchText.toLowerCase();
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) {
                            return ExerciseScreen(
                              questions: ref
                                  .read(questionRepositoryProvider)
                                  .fetchQuestionsByName(searchText),
                              title: 'Kết quả tìm kiếm cho "$searchText"',
                            );
                          },
                        ));
                      },
                      decoration: InputDecoration(
                        alignLabelWithHint: true,
                        contentPadding: const EdgeInsets.all(0),
                        hintText: 'Tìm kiếm câu hỏi...',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                Divider(
                  height: 0.5,
                  thickness: 1,
                  color: Colors.grey[400],
                ),
              ],
            ),
            _customListTile(
              title: 'Toàn bộ $questionLength câu hỏi của Hạng $vehicleType',
              subtitle: '$questionLength câu hỏi từ bộ 600 câu',
              total: questionLength,
              completed:
                  ref.watch(answeredQuestionsProvider)['all-$vehicleType'] ?? 0,
              context: context,
              testSetId: 'all-$vehicleType',
              ref: ref,
            ),
            ListView.builder(
              padding: const EdgeInsets.all(0.0),
              itemCount: allChapters.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final chapter = allChapters[index];
                final chapterKey = vehicle.chapters.entries
                    .firstWhere((entry) => entry.value == chapter,
                        orElse: () => MapEntry('unknown', chapter))
                    .key;
                final testSetId = 'practice-$chapterKey-$vehicleType';

                // Get the answered count from the provider
                final answeredCount =
                    ref.watch(answeredQuestionsProvider)[testSetId] ?? 0;

                return _customListTile(
                  title: chapter.chapterName,
                  subtitle: '${chapter.getQuestionCount()} câu hỏi',
                  total: chapter.getQuestionCount(),
                  completed: answeredCount,
                  context: context,
                  testSetId: testSetId,
                  ref: ref,
                );
              },
            ),
            _customListTile(
              title:
                  '${vehicle.deadPointQuestions.length} câu hỏi về xử lý tình huống mất an toàn giao thông nghiêm trọng',
              subtitle:
                  '${vehicle.deadPointQuestions.length} câu điểm liệt bắt buộc phải trả lời đúng',
              total: vehicle.deadPointQuestions.length,
              completed: ref.watch(
                      answeredQuestionsProvider)['deadpoints-$vehicleType'] ??
                  0,
              context: context,
              testSetId: 'deadpoints-$vehicleType',
              ref: ref,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _customListTile({
  required String title,
  required String subtitle,
  required BuildContext context,
  required int completed,
  required int total,
  required String testSetId,
  required WidgetRef ref,
}) {
  String titleBasedOnChapterType(String vehicleType) {
    switch (vehicleType) {
      case 'Chapter 1':
        return 'Chương I. Khái niệm và quy tắc giao thông đường bộ';
      case 'Chapter 2':
        return 'Chương II. Nghiệp vụ vận tải';
      case 'Chapter 3':
        return 'Chương III. Văn hóa, đạo đức người lái xe';
      case 'Chapter 4':
        return 'Chương IV. Kỹ thuật lái xe';
      case 'Chapter 5':
        return 'Chương V. Cấu tạo và sửa chữa xe';
      case 'Chapter 6':
        return 'Chương VI. Biển báo hiệu đường bộ';
      case 'Chapter 7':
        return 'Chương VII. Giải các thế sa hình và kỹ năng xử lý tình huống giao thông';
      default:
        return title;
    }
  }

  return GestureDetector(
    onTap: () {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ExerciseScreen(
                    testSetId: testSetId,
                    title: titleBasedOnChapterType(title),
                  ))).then((_) {
        // Refresh the page when coming back from ExerciseScreen
        if (context.mounted) {
          // Invalidate the answeredQuestionsProvider to make sure we get fresh data
          ref.invalidate(answeredQuestionsProvider);
          // Then rebuild the widget
          (context as Element).markNeedsBuild();
        }
      });
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(titleBasedOnChapterType(title)),
          titleTextStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
          subtitle: Text(subtitle),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: _buildProgressBar(completed, total),
        ),
        Divider(
          indent: 20,
          endIndent: 20,
          height: 0.5,
          thickness: 1,
          color: Colors.grey[300],
        ),
      ],
    ),
  );
}

Widget _buildProgressBar(int completed, int total) {
  final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

  return Row(
    children: [
      Expanded(
        flex: 2,
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          minHeight: 4.0,
          borderRadius: BorderRadius.circular(3.0),
        ),
      ),
      const SizedBox(width: AppStyles.horizontalSpace / 2),
      Text(
        '$completed/$total',
        style: const TextStyle(
          color: Colors.green,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
