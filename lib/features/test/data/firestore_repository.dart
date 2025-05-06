import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test/models/quiz.dart';
import 'package:uuid/uuid.dart';

class FirestoreRepository {
  final FirebaseFirestore _firestore;

  FirestoreRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch all quizzes from Firestore
  Future<List<Quiz>> getAllQuizzes() async {
    try {
      final querySnapshot = await _firestore.collection('quizzes').get();
      return querySnapshot.docs
          .map((doc) => Quiz.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      debugPrint('Error fetching quizzes: $e');
      rethrow;
    }
  }

  /// Fetch a specific quiz by ID
  Future<Quiz?> getQuizById(String quizId) async {
    try {
      final docSnapshot =
          await _firestore.collection('quizzes').doc(quizId).get();

      if (!docSnapshot.exists) {
        return null;
      }

      return Quiz.fromJson({
        ...docSnapshot.data()!,
        'id': docSnapshot.id,
      });
    } catch (e) {
      debugPrint('Error fetching quiz: $e');
      rethrow;
    }
  }

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

  /// Get questions for a specific quiz
  Future<List<Question>> getQuestionsByQuizId(String quizId) async {
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
      debugPrint('Error fetching questions for quiz: $e');
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

  /// Add a new question to Firestore
  Future<void> addQuestion(Question question) async {
    try {
      // Generate a random ID for the question if not provided
      final questionToSave = question.id == null || question.id!.isEmpty
          ? question.copyWith(id: const Uuid().v4())
          : question;

      await _firestore.collection('questions').add(questionToSave.toJson());
    } catch (e) {
      debugPrint('Error adding question: $e');
      rethrow;
    }
  }

  /// Add a new quiz to Firestore
  Future<void> addQuiz(Quiz quiz) async {
    try {
      // Use the quiz.id as the document ID instead of auto-generating one
      await _firestore.collection('quizzes').doc(quiz.id).set(quiz.toJson());
    } catch (e) {
      debugPrint('Error adding quiz: $e');
      rethrow;
    }
  }

  /// Get the highest question ID to generate the next ID
  Future<int> getNextQuestionId() async {
    try {
      final querySnapshot = await _firestore
          .collection('questions')
          .orderBy('id', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return 1; // Start with 1 if no questions exist
      }

      // Try to parse the ID from the last document
      final lastDoc = querySnapshot.docs.first;
      final lastId = lastDoc.data()['id'];

      if (lastId is int) {
        return lastId + 1;
      } else if (lastId is String) {
        // Try to parse as integer if it's a string
        return int.tryParse(lastId) != null ? int.parse(lastId) + 1 : 1;
      }

      return 1; // Default to 1 if parsing fails
    } catch (e) {
      debugPrint('Error getting next question ID: $e');
      return 1; // Default to 1 on error
    }
  }
}
