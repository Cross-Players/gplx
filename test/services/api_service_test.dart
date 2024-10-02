// import 'package:gh247_user/core/services/api/api_service.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart';

// ignore_for_file: unused_local_variable

// // Tạo mock cho Dio
import 'package:gh247_user/core/services/api/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// TODO(anyone): implement test case
class MockDio extends Mock implements Dio {}

void main() {
  group('ApiService', () {
    Dio mockDio;
    ApiService apiService;

    setUp(() {
      mockDio = MockDio(); // Khởi tạo Dio giả
      apiService = ApiService(); // Truyền mockDio vào ApiService
    });

//     test('fetchPosts returns list of posts', () async {
//       // Dữ liệu giả lập trả về khi gọi API
//       final mockResponseData = [
//         {'id': 1, 'title': 'Post 1', 'body': 'Body 1'},
//         {'id': 2, 'title': 'Post 2', 'body': 'Body 2'}
//       ];

//       final mockResponse = Response(
//         data: mockResponseData,
//         statusCode: 200,
//         requestOptions: RequestOptions(path: '/posts'),
//       );

//       when(mockDio.get('/posts')).thenAnswer((_) async => mockResponse);

//       final result = await apiService.fetchPosts();

//       expect(result, mockResponseData);
//     });

//     test('fetchPosts throws an exception when Dio request fails', () async {
//
//       when(mockDio.get('/posts')).thenThrow(DioException(
//         requestOptions: RequestOptions(path: '/posts'),
//         error: 'Network error',
//       ));

//
//       expect(() => apiService.fetchPosts(), throwsException);
//     });
  });
}
