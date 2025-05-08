import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/admin/add_category_screen.dart';
import 'package:gplx/admin/firestore_questions_screen.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/features/test/models/category.dart';
import 'package:gplx/features/test/providers/firestore_providers.dart';

class FirestoreCategoriesScreen extends ConsumerStatefulWidget {
  const FirestoreCategoriesScreen({super.key});

  @override
  ConsumerState<FirestoreCategoriesScreen> createState() =>
      _FirestoreCategoriesScreenState();
}

class _FirestoreCategoriesScreenState
    extends ConsumerState<FirestoreCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch all categories when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoriesNotifierProvider.notifier).refreshCategories();
    });
  }

  void _navigateToQuestionsByCategory(Category category) {
    // Navigate to FirestoreQuestionsScreen when a category is tapped
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FirestoreQuestionsScreen(
          categoryId: category.id,
          categoryName: category.name,
        ),
      ),
    );
  }

  void _navigateToAddCategory() {
    // Navigate to AddCategoryScreen when the FAB is tapped
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCategoryScreen(),
      ),
    ).then((_) {
      // Refresh categories when returning from the add screen
      ref.read(categoriesNotifierProvider.notifier).refreshCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách loại bài thi'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(categoriesNotifierProvider.notifier).refreshCategories();
            },
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _buildCategoriesView(categoriesAsync),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCategory,
        backgroundColor: AppStyles.primaryColor,
        tooltip: 'Thêm loại bài thi mới',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoriesView(AsyncValue<List<Category>> categoriesAsync) {
    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Lỗi khi tải danh sách loại: ${error.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(categoriesNotifierProvider.notifier)
                    .refreshCategories();
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Chưa có loại bài thi nào. Vui lòng thêm loại mới!',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _navigateToAddCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thêm loại bài thi mới'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryCard(category);
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToQuestionsByCategory(category),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.description,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final quizzesAsync =
                          ref.watch(quizzesByCategoryProvider(category.id));
                      return quizzesAsync.when(
                        loading: () => const Text('Đang đếm...'),
                        error: (_, __) => const Text('0 bài quiz'),
                        data: (quizzes) => Text(
                          '${quizzes.length} bài quiz',
                          style: const TextStyle(
                            color: AppStyles.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  TextButton.icon(
                    onPressed: () => _navigateToQuestionsByCategory(category),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Xem chi tiết'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppStyles.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
