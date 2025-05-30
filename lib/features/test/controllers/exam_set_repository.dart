import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/controllers/class_data_repository.dart';
import 'package:gplx/features/test_sets/models/exam_set.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider cho ExamSetRepository
final examSetRepositoryProvider = Provider<ExamSetRepository>((ref) {
  return ExamSetRepository(ref);
});

// Provider cho danh sách ExamSets theo classType
final examSetsProvider = FutureProvider.family<List<ExamSet>, String>((
  ref,
  classType,
) async {
  return ref.read(examSetRepositoryProvider).getExamSets(classType);
});

// Provider cho một ExamSet cụ thể theo ID
final examSetByIdProvider = FutureProvider.family<ExamSet?, String>((
  ref,
  examSetId,
) async {
  return ref.read(examSetRepositoryProvider).getExamSetById(examSetId);
});

class ExamSetRepository {
  final Ref _ref;

  // Cache để lưu trữ danh sách ExamSet theo classType
  final Map<String, List<ExamSet>> _examSetsCache = {};

  ExamSetRepository(this._ref);

  // Tạo mới hoặc lấy danh sách ExamSet cho một loại class
  Future<List<ExamSet>> getExamSets(String classType) async {
    // Kiểm tra cache trước
    if (_examSetsCache.containsKey(classType)) {
      return _examSetsCache[classType]!;
    }

    // Thử tải từ SharedPreferences
    final savedSets = await _loadSavedExamSets(classType);
    if (savedSets.isNotEmpty) {
      _examSetsCache[classType] = savedSets;
      return savedSets;
    }

    // Nếu không có, tạo mới
    final examSets = await _generateExamSets(classType);
    _examSetsCache[classType] = examSets;

    // Lưu vào SharedPreferences
    await saveExamSets(classType, examSets);

    return examSets;
  }

  // Lấy một ExamSet theo ID
  Future<ExamSet?> getExamSetById(String examSetId) async {
    // Tìm trong cache trước
    for (final setList in _examSetsCache.values) {
      final examSet = setList.where((set) => set.id == examSetId).firstOrNull;
      if (examSet != null) {
        return examSet;
      }
    }

    // Nếu không tìm thấy, tải tất cả và tìm
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('exam_sets_'));

    for (final key in keys) {
      final classType = key.substring('exam_sets_'.length);
      final examSets = await getExamSets(classType);
      final examSet = examSets.where((set) => set.id == examSetId).firstOrNull;
      if (examSet != null) {
        return examSet;
      }
    }

    return null;
  }

  // Tạo mới danh sách các ExamSet cho một loại class
  Future<List<ExamSet>> _generateExamSets(String classType) async {
    const numberOfSets = 20; // Mặc định tạo 10 bộ đề
    final repository = _ref.read(classDataRepositoryProvider);
    final examQuestionsList = repository.generateMultipleExamSets(
      classType,
      numberOfSets,
    );
    final result = <ExamSet>[];
    for (int i = 0; i < examQuestionsList.length; i++) {
      // Format ID theo dạng: Số thứ tự đề - Tên hạng xe (ví dụ: 01-A1)
      final formattedIndex = (i + 1).toString().padLeft(
            2,
            '0',
          ); // Đảm bảo luôn có 2 chữ số
      final id = '$formattedIndex-$classType';
      result.add(
        ExamSet(
          id: id,
          title: 'Đề số ${i + 1}',
          classType: classType,
          questionNumbers: examQuestionsList[i],
          createdAt: DateTime.now(),
          description: 'Bộ đề thi thử $classType với 25 câu hỏi',
        ),
      );
    }

    return result;
  }

  // Tải danh sách ExamSet đã lưu
  Future<List<ExamSet>> _loadSavedExamSets(String classType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'exam_sets_$classType';
      final jsonString = prefs.getString(key);

      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => ExamSet.fromJson(json)).toList();
    } catch (e) {
      print('Error loading exam sets: $e');
      return [];
    }
  }

  // Lưu danh sách ExamSet
  Future<void> saveExamSets(String classType, List<ExamSet> examSets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'exam_sets_$classType';
      final jsonList = examSets.map((set) => set.toJson()).toList();
      await prefs.setString(key, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving exam sets: $e');
    }
  }

  // Làm mới danh sách ExamSet cho một loại class
  Future<List<ExamSet>> refreshExamSets(String classType) async {
    _examSetsCache.remove(classType);
    final examSets = await _generateExamSets(classType);
    _examSetsCache[classType] = examSets;
    await saveExamSets(classType, examSets);
    return examSets;
  }
}
