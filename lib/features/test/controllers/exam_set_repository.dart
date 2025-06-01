import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/providers/vehicle_provider.dart';
import 'package:gplx/features/test_sets/models/exam_set.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider cho ExamSetRepository
final examSetRepositoryProvider = Provider<ExamSetRepository>((ref) {
  return ExamSetRepository(ref);
});

// Provider cho danh sách ExamSets theo vehicleType
final examSetsProvider = FutureProvider.family<List<ExamSet>, String>((
  ref,
  vehicleType,
) async {
  return ref.read(examSetRepositoryProvider).getExamSets(vehicleType);
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

  // Cache để lưu trữ danh sách ExamSet theo vehicleType
  final Map<String, List<ExamSet>> _examSetsCache = {};

  ExamSetRepository(this._ref);

  // Tạo mới hoặc lấy danh sách ExamSet cho một loại class
  Future<List<ExamSet>> getExamSets(String vehicleType) async {
    // Kiểm tra cache trước
    if (_examSetsCache.containsKey(vehicleType)) {
      return _examSetsCache[vehicleType]!;
    }

    // Thử tải từ SharedPreferences
    final savedSets = await _loadSavedExamSets(vehicleType);
    if (savedSets.isNotEmpty) {
      _examSetsCache[vehicleType] = savedSets;
      return savedSets;
    }

    // Nếu không có, tạo mới
    final examSets = await _generateExamSets(vehicleType);
    _examSetsCache[vehicleType] = examSets;

    // Lưu vào SharedPreferences
    await saveExamSets(vehicleType, examSets);

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
      final vehicleType = key.substring('exam_sets_'.length);
      final examSets = await getExamSets(vehicleType);
      final examSet = examSets.where((set) => set.id == examSetId).firstOrNull;
      if (examSet != null) {
        return examSet;
      }
    }

    return null;
  }

  // Tạo mới danh sách các ExamSet cho một loại class
  Future<List<ExamSet>> _generateExamSets(String vehicleType) async {
    const numberOfSets = 20; // Mặc định tạo 10 bộ đề
    final repository = _ref.read(vehicleRepositoryProvider);
    final examQuestionsList = repository.generateMultipleExamSets(
      vehicleType,
      numberOfSets,
    );
    final result = <ExamSet>[];
    for (int i = 0; i < examQuestionsList.length; i++) {
      // Format ID theo dạng: Số thứ tự đề - Tên hạng xe (ví dụ: 01-A1)
      final formattedIndex = (i + 1).toString().padLeft(
            2,
            '0',
          ); // Đảm bảo luôn có 2 chữ số
      final id = '$formattedIndex-$vehicleType';
      result.add(
        ExamSet(
          id: id,
          title: 'Đề số ${i + 1}',
          vehicleType: vehicleType,
          questionNumbers: examQuestionsList[i],
          createdAt: DateTime.now(),
          description: 'Bộ đề thi thử $vehicleType với 25 câu hỏi',
        ),
      );
    }

    return result;
  }

  // Tải danh sách ExamSet đã lưu
  Future<List<ExamSet>> _loadSavedExamSets(String vehicleType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'exam_sets_$vehicleType';
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
  Future<void> saveExamSets(String vehicleType, List<ExamSet> examSets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'exam_sets_$vehicleType';
      final jsonList = examSets.map((set) => set.toJson()).toList();
      await prefs.setString(key, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving exam sets: $e');
    }
  }

  // Làm mới danh sách ExamSet cho một loại class
  Future<List<ExamSet>> refreshExamSets(String vehicleType) async {
    _examSetsCache.remove(vehicleType);
    final examSets = await _generateExamSets(vehicleType);
    _examSetsCache[vehicleType] = examSets;
    await saveExamSets(vehicleType, examSets);
    return examSets;
  }

  
}
