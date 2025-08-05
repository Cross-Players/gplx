import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/providers/vehicle_provider.dart';
import 'package:gplx/features/test_sets/models/test_set.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestSetRepository {
  final Ref _ref;

  // Cache để lưu trữ danh sách TestSet theo vehicleType
  final Map<String, List<TestSet>> _testSetsCache = {};

  TestSetRepository(this._ref);

  // Tạo mới hoặc lấy danh sách TestSet cho một loại Vehicle
  Future<List<TestSet>> getTestSets(String vehicleType) async {
    // Kiểm tra cache trước
    if (_testSetsCache.containsKey(vehicleType)) {
      return _testSetsCache[vehicleType]!;
    }

    // Thử tải từ SharedPreferences
    final savedSets = await _loadSavedTestSets(vehicleType);
    if (savedSets.isNotEmpty) {
      _testSetsCache[vehicleType] = savedSets;
      return savedSets;
    }

    // Nếu không có, tạo mới
    final testSets = await _generateTestSets(vehicleType);
    _testSetsCache[vehicleType] = testSets;

    // Lưu vào SharedPreferences
    await saveTestSets(vehicleType, testSets);

    return testSets;
  }

  // Lấy một TestSet theo ID
  Future<TestSet?> getTestSetById(String testSetId) async {
    // Tìm trong cache trước
    for (final setList in _testSetsCache.values) {
      final testSet = setList.where((set) => set.id == testSetId).firstOrNull;
      if (testSet != null) {
        return testSet;
      }
    }

    // Nếu không tìm thấy, tải tất cả và tìm
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('test_sets_'));

    for (final key in keys) {
      final vehicleType = key.substring('test_sets_'.length);
      final testSets = await getTestSets(vehicleType);
      final testSet = testSets.where((set) => set.id == testSetId).firstOrNull;
      if (testSet != null) {
        return testSet;
      }
    }

    return null;
  }

  // Tạo mới danh sách các TestSet cho một loại Vehicle
  Future<List<TestSet>> _generateTestSets(String vehicleType) async {
    const numberOfSets = 20; // Mặc định tạo 10 bộ đề
    final repository = _ref.read(vehicleRepositoryProvider);
    final testQuestionsList = repository.generateMultipleTestSets(
      vehicleType,
      numberOfSets,
    );
    final result = <TestSet>[];
    for (int i = 0; i < testQuestionsList.length; i++) {
      // Format ID theo dạng: Số thứ tự đề - Tên hạng xe (ví dụ: 01-A1)
      final formattedIndex = (i + 1).toString().padLeft(
            2,
            '0',
          ); // Đảm bảo luôn có 2 chữ số
      final id = '$formattedIndex-$vehicleType';
      result.add(
        TestSet(
          id: id,
          title: 'Đề số ${i + 1}',
          vehicleType: vehicleType,
          questionNumbers: testQuestionsList[i],
        ),
      );
    }

    return result;
  }

  // Tải danh sách TestSet đã lưu
  Future<List<TestSet>> _loadSavedTestSets(String vehicleType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'Test_sets_$vehicleType';
      final jsonString = prefs.getString(key);

      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => TestSet.fromJson(json)).toList();
    } catch (e) {
      print('Error loading Test sets: $e');
      return [];
    }
  }

  // Lưu danh sách TestSet
  Future<void> saveTestSets(String vehicleType, List<TestSet> testSets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'Test_sets_$vehicleType';
      final jsonList = testSets.map((set) => set.toJson()).toList();
      await prefs.setString(key, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving Test sets: $e');
    }
  }

  // Làm mới danh sách TestSet cho một loại Vehicle
  Future<List<TestSet>> refreshTestSets(String vehicleType) async {
    _testSetsCache.remove(vehicleType);
    final testSets = await _generateTestSets(vehicleType);
    _testSetsCache[vehicleType] = testSets;
    await saveTestSets(vehicleType, testSets);
    return testSets;
  }
}
