import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for tracking answered questions by chapter
class AnsweredQuestionsNotifier extends StateNotifier<Map<String, int>> {
  AnsweredQuestionsNotifier() : super({});

  // Load progress from SharedPreferences
  Future<void> loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressMap = <String, int>{};

      for (String key in prefs.getKeys()) {
        if (key.startsWith('chapter_progress_')) {
          final chapter = key.replaceFirst('chapter_progress_', '');
          final count = prefs.getInt(key) ?? 0;
          progressMap[chapter] = count;
        }
      }

      state = progressMap;
    } catch (e) {
      print('Error loading chapter progress: $e');
    }
  }

  // Update progress for a specific chapter
  Future<void> updateChapterProgress(String chapter, int answeredCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('chapter_progress_$chapter', answeredCount);

      state = {...state, chapter: answeredCount};
    } catch (e) {
      print('Error updating chapter progress: $e');
    }
  }

  // Increment answered count for a chapter
  Future<void> incrementChapterProgress(String chapter) async {
    final currentCount = state[chapter] ?? 0;
    await updateChapterProgress(chapter, currentCount + 1);
  }

  // Record answered questions for a specific session/test
  Future<void> recordAnsweredQuestions(
    Map<int, String> questionNumberToChapter,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chapterCounts = <String, Set<String>>{};

      // Load existing answered questions for each chapter
      for (String key in prefs.getKeys()) {
        if (key.startsWith('answered_questions_')) {
          final chapter = key.replaceFirst('answered_questions_', '');
          final answeredQuestionsJson = prefs.getStringList(key) ?? [];
          chapterCounts[chapter] = Set<String>.from(answeredQuestionsJson);
        }
      }

      // Add new answered questions using question numbers
      for (final entry in questionNumberToChapter.entries) {
        final questionNumber = entry.key.toString();
        final chapter = entry.value;

        if (chapter.isNotEmpty) {
          chapterCounts[chapter] ??= <String>{};
          chapterCounts[chapter]!.add(questionNumber);
        }
      }

      // Save updated lists and update progress counts
      final newState = <String, int>{};
      for (final entry in chapterCounts.entries) {
        final chapter = entry.key;
        final questions = entry.value.toList();

        await prefs.setStringList('answered_questions_$chapter', questions);
        await prefs.setInt('chapter_progress_$chapter', questions.length);

        newState[chapter] = questions.length;
      }

      state = {...state, ...newState};
    } catch (e) {
      print('Error recording answered questions: $e');
    }
  }

  // Get progress for a specific chapter
  int getChapterProgress(String chapter) {
    return state[chapter] ?? 0;
  }
}

// Provider instance
final answeredQuestionsProgressProvider =
    StateNotifierProvider<AnsweredQuestionsNotifier, Map<String, int>>(
      (ref) => AnsweredQuestionsNotifier(),
    );
