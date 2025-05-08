import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gplx/features/test/models/category.dart';
import 'package:gplx/features/test/models/quiz.dart';

class FirestoreCategoriesRepository {
  final FirebaseFirestore _firestore;

  FirestoreCategoriesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch all categories from Firestore
  Future<List<Category>> getAllCategories() async {
    try {
      final querySnapshot = await _firestore.collection('categories').get();
      return querySnapshot.docs
          .map((doc) => Category.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  /// Fetch quizzes by category ID
  Future<List<Quiz>> getQuizzesByCategory(String categoryId) async {
    try {
      final querySnapshot = await _firestore
          .collection('quizzes')
          .where('categoryID', isEqualTo: categoryId)
          .get();

      return querySnapshot.docs
          .map((doc) => Quiz.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Error fetching quizzes by category: $e');
      rethrow;
    }
  }

  /// Add a new category to Firestore
  Future<void> addCategory(Category category) async {
    try {
      // Use the category.id as the document ID
      await _firestore
          .collection('categories')
          .doc(category.id)
          .set(category.toJson());
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }
}
