import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/features/test/models/quiz.dart';
import 'package:gplx/features/test/providers/firestore_providers.dart';

class AddQuizScreen extends ConsumerStatefulWidget {
  const AddQuizScreen({super.key});

  @override
  ConsumerState<AddQuizScreen> createState() => _AddQuizScreenState();
}

class _AddQuizScreenState extends ConsumerState<AddQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _categoryIDController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final _titleController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _categoryIDController.dispose();
    _timeLimitController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Parse the timeLimit to an integer
        final timeLimit = int.parse(_timeLimitController.text.trim());

        // Create the quiz
        final quiz = Quiz(
          id: _idController.text.trim(),
          categoryID: _categoryIDController.text.trim(),
          timeLimit: timeLimit,
          title: _titleController.text.trim(),
        );

        // Save to Firestore
        await ref.read(quizzesNotifierProvider.notifier).addQuiz(quiz);

        // Refresh the quizzes list
        await ref.read(quizzesNotifierProvider.notifier).refreshQuizzes();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bài quiz đã được lưu thành công')),
          );

          // Reset the form
          _formKey.currentState!.reset();
          _idController.clear();
          _categoryIDController.clear();
          _timeLimitController.clear();
          _titleController.clear();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm bài quiz mới'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ID
                    TextFormField(
                      controller: _idController,
                      decoration: InputDecoration(
                        labelText: 'ID',
                        hintText: 'Nhập ID của bài quiz (ví dụ: quiz1)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập ID của bài quiz';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category ID
                    TextFormField(
                      controller: _categoryIDController,
                      decoration: InputDecoration(
                        labelText: 'Category ID',
                        hintText: 'Nhập loại bằng lái (ví dụ: A1, B2)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập loại bằng lái';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Time Limit
                    TextFormField(
                      controller: _timeLimitController,
                      decoration: InputDecoration(
                        labelText: 'Time Limit (phút)',
                        hintText: 'Nhập thời gian làm bài (phút)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập thời gian làm bài';
                        }

                        final timeLimit = int.tryParse(value);
                        if (timeLimit == null || timeLimit <= 0) {
                          return 'Thời gian phải là một số nguyên dương';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'Nhập tiêu đề bài quiz (ví dụ: "Đề 1")',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tiêu đề bài quiz';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Lưu bài quiz',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
