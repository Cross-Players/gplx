import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/widgets/gradient_app_bar.dart';
import 'package:gplx/features/exercise/controllers/deadpoint_questions_provider.dart';
import 'package:gplx/features/exercise/views/exercise_screen.dart';
import 'package:gplx/features/test/models/license_data.dart';
import 'package:gplx/features/test/models/question.dart';

// Provider to fetch and group questions by chapter from local assets
final allChaptersProvider =
    FutureProvider.autoDispose<Map<String, List<Question>>>((ref) async {
  final licenseType = ref.watch(licenseTypeProvider);

  final String prefix;
  if (licenseType == LicenseType.A1 || licenseType == LicenseType.A) {
    prefix = 'A1';
  } else if (licenseType == LicenseType.B1) {
    prefix = licenseType.name;
  } else {
    prefix = 'overall';
  }

  final chapterMap = <String, List<Question>>{};

  final chapterFiles = [
    'chapter1',
    'chapter2',
    'chapter3',
    'chapter4',
    'chapter5',
    'chapter6',
  ];

  for (final chapterFile in chapterFiles) {
    try {
      final assetPath = 'assets/question_data/${prefix}_$chapterFile.json';
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);

      // Extract questions array from the JSON object
      final List<dynamic> jsonList = jsonData['questions'] as List<dynamic>;

      final questions = jsonList
          .map((json) => Question.fromJson(json as Map<String, dynamic>))
          .toList();

      if (questions.isNotEmpty) {
        final chapterNumber = chapterFile.replaceAll('chapter', '');
        final chapterName = chapterNumber;
        chapterMap[chapterName] = questions;
      }
    } catch (e) {
      debugPrint('Skipping $chapterFile: $e');
    }
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
    final deadpointAsync = ref.watch(deadpointQuestionsProvider);

    return Scaffold(
      appBar: GradientAppBar(
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
              const Icon(Icons.cloud_off_rounded,
                  size: 64, color: AppPalette.danger),
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

          final allQuestionsFromChapters = _removeDuplicateQuestions(
            cleanedChapterMap.values.expand((questions) => questions).toList(),
          );

          // Get total questions after removing duplicates
          final totalQuestions = allQuestionsFromChapters.length;

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: SizedBox(
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
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              hintText: 'Tìm kiếm câu hỏi...',
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: AppPalette.inkFaint,
                              ),
                            ),
                          ),
                        ),
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
                    questions: allQuestionsFromChapters,
                    ref: ref,
                  ),
                  ListView.builder(
                    padding: EdgeInsets.zero,
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
                  deadpointAsync.when(
                    loading: () => const ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('Câu hỏi điểm liệt'),
                      subtitle: Text('Đang tải...'),
                    ),
                    error: (error, stack) => ListTile(
                      leading: const Icon(Icons.error_outline_rounded,
                          color: AppPalette.danger),
                      title: const Text('Câu hỏi điểm liệt'),
                      subtitle: Text('Lỗi: $error'),
                    ),
                    data: (deadpointQuestions) {
                      final cleanedDeadpointQuestions =
                          _removeDuplicateQuestions(deadpointQuestions);
                      return _customListTile(
                        title: 'Câu hỏi điểm liệt',
                        subtitle:
                            'Các câu hỏi bắt buộc phải trả lời đúng (${cleanedDeadpointQuestions.length} câu)',
                        total: cleanedDeadpointQuestions.length,
                        completed: 0,
                        context: context,
                        questions: cleanedDeadpointQuestions,
                        ref: ref,
                        isDeadPoint:
                            false, // Sử dụng ExerciseScreen thay vì navigate khác
                      );
                    },
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

  final chapterNumber = int.tryParse(title);
  final Color accent = isDeadPoint || title == 'Câu hỏi điểm liệt'
      ? AppPalette.danger
      : AppPalette.primary;

  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
    child: Material(
      color: AppPalette.surface,
      borderRadius: BorderRadius.circular(AppPalette.radiusM),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppPalette.radiusM),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseScreen(
                questions: Future.value(questions),
                title: titleBasedOnChapterType(title),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppPalette.radiusM),
            border: Border.all(color: AppPalette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppPalette.radiusS),
                ),
                child: chapterNumber != null
                    ? Text(
                        '$chapterNumber',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      )
                    : Icon(
                        accent == AppPalette.danger
                            ? Icons.warning_amber_rounded
                            : Icons.library_books_rounded,
                        color: accent,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleBasedOnChapterType(title),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.3,
                        color: AppPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppPalette.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppPalette.inkFaint),
            ],
          ),
        ),
      ),
    ),
  );
}
