import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/routes/app_routes.dart';
import 'package:gplx/features/exercise/views/exercise_screen.dart';
import 'package:gplx/features/test/models/license_data.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test_sets/controllers/test_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider to fetch and group questions by chapter with caching
final allChaptersProvider =
    FutureProvider.autoDispose<Map<String, List<Question>>>((ref) async {
  final licenseType = ref.watch(licenseTypeProvider);
  final cacheKey = 'cached_questions_${licenseType.name}';

  try {
    // Try to load from cache first
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      debugPrint('Loading questions from cache for ${licenseType.name}');
      final Map<String, dynamic> decodedData = jsonDecode(cachedData);
      final Map<String, List<Question>> chapterMap = {};

      decodedData.forEach((chapter, questionsJson) {
        final List<dynamic> questionsList = questionsJson as List<dynamic>;
        chapterMap[chapter] = questionsList
            .map(
              (json) => Question.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      });

      return chapterMap;
    }
  } catch (e) {
    debugPrint('Failed to load from cache: $e');
  }

  // If cache failed or doesn't exist, fetch from network
  debugPrint('Fetching questions from network for ${licenseType.name}');
  final controller = TestController();
  final allQuestions = <Question>[];
  final totalTestSets = numberOfTestSetsBasedOnLicense(licenseType);

  for (int testNumber = 1; testNumber <= totalTestSets; testNumber++) {
    try {
      final questions = await controller.fetchQuestionsByTestSets(
        licenseType,
        testNumber,
      );
      allQuestions.addAll(questions);
    } catch (e) {
      // Continue with next test set if one fails
      debugPrint('Failed to fetch test set $testNumber: $e');
    }
  }

  // Also fetch dead point questions
  try {
    final deadPointQuestions = await controller.fetchDeadPointQuestions(
      licenseType,
    );
    allQuestions.addAll(deadPointQuestions);
  } catch (e) {
    debugPrint('Failed to fetch dead point questions: $e');
  }

  // Group questions by chapter
  final chapterMap = <String, List<Question>>{};
  for (final question in allQuestions) {
    final chapter = question.chapter ?? 'Không xác định';
    if (!chapterMap.containsKey(chapter)) {
      chapterMap[chapter] = [];
    }
    chapterMap[chapter]!.add(question);
  }

  // Cache the result
  try {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> cacheData = {};
    chapterMap.forEach((chapter, questions) {
      cacheData[chapter] = questions.map((q) => q.toJson()).toList();
    });
    await prefs.setString(cacheKey, jsonEncode(cacheData));
    debugPrint('Successfully cached questions for ${licenseType.name}');
  } catch (e) {
    debugPrint('Failed to cache questions: $e');
  }

  return chapterMap;
});

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

  // Function to remove duplicate questions based on question.number
  List<Question> _removeDuplicateQuestions(List<Question> questions) {
    final seen = <int>{};
    final uniqueQuestions = <Question>[];

    for (final question in questions) {
      final questionNumber = question.number;

      if (questionNumber != null && !seen.contains(questionNumber)) {
        seen.add(questionNumber);
        uniqueQuestions.add(question);
      } else if (questionNumber == null) {
        // Keep questions without number
        uniqueQuestions.add(question);
      }
      // Skip duplicate questions (when questionNumber != null && seen.contains(questionNumber))
    }

    return uniqueQuestions;
  }

  @override
  Widget build(BuildContext context) {
    final licenseType = ref.watch(licenseTypeProvider);
    final chaptersAsync = ref.watch(allChaptersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hạng ${licenseType.name} - Ôn tập theo chương'),
      ),
      body: chaptersAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải câu hỏi...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(allChaptersProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (chapterMap) {
          // Remove duplicates from each chapter
          final cleanedChapterMap = <String, List<Question>>{};
          for (final entry in chapterMap.entries) {
            cleanedChapterMap[entry.key] = _removeDuplicateQuestions(
              entry.value,
            );
          }

          // Get total questions after removing duplicates
          final totalQuestions = cleanedChapterMap.values.fold<int>(
            0,
            (sum, questions) => sum + questions.length,
          );

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 10.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: TextField(
                            onSubmitted: (searchText) {
                              if (searchText.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Vui lòng nhập từ khóa tìm kiếm',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              searchText.toLowerCase();

                              // Search through all questions
                              final allQuestions = chapterMap.values
                                  .expand((questions) => questions)
                                  .toList();
                              final searchResults =
                                  allQuestions.where((question) {
                                final content =
                                    question.content?.toLowerCase() ?? '';
                                return content.contains(
                                  searchText.toLowerCase(),
                                );
                              }).toList();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return ExerciseScreen(
                                      questions: Future.value(searchResults),
                                      title:
                                          'Kết quả tìm kiếm cho "$searchText"',
                                    );
                                  },
                                ),
                              );
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
                    title:
                        'Toàn bộ $totalQuestions câu hỏi của Hạng ${licenseType.name}',
                    subtitle: '$totalQuestions câu hỏi từ bộ 600 câu',
                    total: totalQuestions,
                    // completed: 0,
                    completed: 0, // Progress tracking disabled
                    context: context,
                    questions: cleanedChapterMap.values
                        .expand((questions) => questions)
                        .toList(),
                    ref: ref,
                  ),
                  ListView.builder(
                    padding: const EdgeInsets.all(0.0),
                    itemCount: cleanedChapterMap.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      // Sort chapters by number (1, 2, 3, etc.)
                      final sortedEntries = cleanedChapterMap.entries.toList()
                        ..sort((a, b) {
                          // Extract chapter numbers for sorting
                          getChapterNumber(String chapter) {
                            // Try to parse the chapter as a number directly
                            final directNumber = int.tryParse(chapter);
                            if (directNumber != null) return directNumber;

                            // If not a direct number, try to extract from "Chapter X" format
                            final match = RegExp(
                              r'Chapter (\d+)',
                            ).firstMatch(chapter);
                            if (match != null) {
                              return int.parse(match.group(1)!);
                            }

                            // If still no match, put at the end
                            return 999;
                          }

                          return getChapterNumber(
                            a.key,
                          ).compareTo(getChapterNumber(b.key));
                        });

                      final entry = sortedEntries[index];
                      final chapter = entry.key;
                      final questions = entry.value;

                      return _customListTile(
                        title: chapter,
                        subtitle: '${questions.length} câu hỏi',
                        total: questions.length,
                        // completed: 0,
                        completed: 0, // Progress tracking disabled
                        context: context,
                        questions: questions,
                        ref: ref,
                      );
                    },
                  ),
                  // Add dead point questions section
                  _customListTile(
                    title: 'Câu hỏi điểm liệt',
                    subtitle: 'Các câu hỏi bắt buộc phải trả lời đúng',
                    total: 0,
                    completed: 0,
                    context: context,
                    questions: [],
                    ref: ref,
                    isDeadPoint: true,
                  ),
                ],
              ),
            ),
          );
        },
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
  required List<Question> questions,
  required WidgetRef ref,
  bool isDeadPoint = false,
}) {
  String titleBasedOnChapterType(String vehicleType) {
    switch (vehicleType) {
      case '1':
        return 'Chương I. Khái niệm và quy tắc giao thông đường bộ';
      case '2':
        return 'Chương II. Nghiệp vụ vận tải';
      case '3':
        return 'Chương III. Văn hóa, đạo đức người lái xe';
      case '4':
        return 'Chương IV. Kỹ thuật lái xe';
      case '5':
        return 'Chương V. Cấu tạo và sửa chữa xe';
      case '6':
        return 'Chương VI. Biển báo hiệu đường bộ';
      case '7':
        return 'Chương VII. Giải các thế sa hình và kỹ năng xử lý tình huống giao thông';
      default:
        return title;
    }
  }

  return GestureDetector(
    onTap: () {
      if (isDeadPoint) {
        Navigator.pushNamed(context, AppRoutes.deadpointQuestions, arguments: {
          'title': title,
          'testSetId': 'deadpoints-${ref.read(licenseTypeProvider).name}',
        });
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseScreen(
              questions: Future.value(questions),
              title: titleBasedOnChapterType(title),
            ),
          ),
        );
      }
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(titleBasedOnChapterType(title)),
                      titleTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      subtitle: Text(subtitle),
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                    //   child: _buildProgressBar(completed, total),
                    // ),
                  ],
                ),
              ),
              Text('Làm ngay', style: TextStyle(color: Colors.blue[700])),
              const SizedBox(width: 16),
            ],
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
    ),
  );
}

// Widget _buildProgressBar(int completed, int total) {
//   final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

//   return Row(
//     children: [
//       Expanded(
//         flex: 2,
//         child: LinearProgressIndicator(
//           value: progress,
//           backgroundColor: Colors.grey[300],
//           valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
//           minHeight: 4.0,
//           borderRadius: BorderRadius.circular(3.0),
//         ),
//       ),
//       const SizedBox(width: AppStyles.horizontalSpace / 2),
//       Text(
//         '$completed/$total',
//         style: const TextStyle(
//           color: Colors.green,
//           fontSize: 14,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     ],
//   );
// }
