import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gplx/features/test/models/question.dart';

class FirestoreQuestionsRepository {
  final FirebaseFirestore _firestore;

  FirestoreQuestionsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get all questions from Firestore
  Future<List<Question>> getAllQuestions() async {
    try {
      final querySnapshot = await _firestore.collection('questions').get();
      return querySnapshot.docs
          .map((doc) => Question.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      rethrow;
    }
  }

  /// Get a specific question set by ID or name
  Future<List<Question>> getQuestionsBySet(String setId) async {
    try {
      final querySnapshot = await _firestore
          .collection('questions')
          .where('setId', isEqualTo: setId)
          .get();

      return querySnapshot.docs
          .map((doc) => Question.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      debugPrint('Error fetching question set: $e');
      rethrow;
    }
  }

  /// Get a specific number of random questions
  Future<List<Question>> getRandomQuestions(int count) async {
    try {
      // Firestore doesn't support random querying natively
      // So first we fetch all documents, then randomly select from them
      final querySnapshot = await _firestore.collection('questions').get();
      final allQuestions = querySnapshot.docs;

      // If there are fewer questions than requested, return all
      if (allQuestions.length <= count) {
        return allQuestions
            .map((doc) => Question.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList();
      }

      // Randomly select questions
      allQuestions.shuffle();
      final selectedQuestions = allQuestions.take(count).toList();

      return selectedQuestions
          .map((doc) => Question.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      debugPrint('Error fetching random questions: $e');
      rethrow;
    }
  }
}
