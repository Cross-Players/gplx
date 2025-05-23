// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
// import 'package:gplx/features/test/models/quiz.dart';

// class FirestoreQuizzesRepository {
//   final FirebaseFirestore _firestore;

//   FirestoreQuizzesRepository({FirebaseFirestore? firestore})
//       : _firestore = firestore ?? FirebaseFirestore.instance;

//   /// Fetch all quizzes from Firestore
//   Future<List<Quiz>> getAllQuizzes() async {
//     try {
//       final querySnapshot = await _firestore.collection('quizzes').get();
//       return querySnapshot.docs
//           .map((doc) => Quiz.fromJson({
//                 ...doc.data(),
//                 'id': doc.id,
//               }))
//           .toList();
//     } catch (e) {
//       debugPrint('Error fetching quizzes: $e');
//       rethrow;
//     }
//   }

//   /// Fetch a specific quiz by ID
//   Future<Quiz?> getQuizById(String quizId) async {
//     try {
//       final docSnapshot =
//           await _firestore.collection('quizzes').doc(quizId).get();

//       if (!docSnapshot.exists) {
//         return null;
//       }

//       return Quiz.fromJson({
//         ...docSnapshot.data()!,
//         'id': docSnapshot.id,
//       });
//     } catch (e) {
//       debugPrint('Error fetching quiz: $e');
//       rethrow;
//     }
//   }

//   /// Add a new quiz to Firestore
//   Future<void> addQuiz(Quiz quiz) async {
//     try {
//       // Use the quiz.id as the document ID instead of auto-generating one
//       await _firestore.collection('quizzes').doc(quiz.id).set(quiz.toJson());
//     } catch (e) {
//       debugPrint('Error adding quiz: $e');
//       rethrow;
//     }
//   }
// }
