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
  Future<List<Question>> getQuestionsBySet(String quizId) async {
    try {
      final querySnapshot = await _firestore
          .collection('questions')
          .where('quizId', isEqualTo: quizId)
          .get();

      return querySnapshot.docs
          .map((doc) => Question.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      debugPrint('Error fetching questions for quiz $quizId: $e');
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

  /// Add a question to Firestore
  Future<void> addQuestion(Question question) async {
    try {
      await _firestore
          .collection('questions')
          .doc(question.id)
          .set(question.toJson());
    } catch (e) {
      debugPrint('Error adding question: $e');
      rethrow;
    }
  }

  /// Get the next available question ID
  Future<int> getNextQuestionId() async {
    try {
      // Get the last question to determine the next ID
      final querySnapshot = await _firestore
          .collection('questions')
          .orderBy('id', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return 1; // Start with ID 1 if no questions exist
      }

      // Get the highest ID and increment by 1
      final lastQuestionId = querySnapshot.docs.first.id;

      // Try to parse the ID as int, default to 1 if parsing fails
      try {
        final idNumber = int.parse(lastQuestionId);
        return idNumber + 1;
      } catch (e) {
        debugPrint('Error parsing question ID: $e');
        return 1;
      }
    } catch (e) {
      debugPrint('Error getting next question ID: $e');
      return 1; // Default to 1 in case of errors
    }
  }
}
