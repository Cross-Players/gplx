import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test/models/quiz.dart';
import 'package:gplx/features/test/presentation/screens/add_question_screen.dart';
import 'package:gplx/features/test/presentation/screens/add_quiz_screen.dart';
import 'package:gplx/features/test/providers/firestore_providers.dart';

class FirestoreQuestionsScreen extends ConsumerStatefulWidget {
  const FirestoreQuestionsScreen({super.key});

  @override
  ConsumerState<FirestoreQuestionsScreen> createState() =>
      _FirestoreQuestionsScreenState();
}

class _FirestoreQuestionsScreenState
    extends ConsumerState<FirestoreQuestionsScreen> {
  String? selectedQuizId;
  bool showingRandomQuestions = false;
  bool showingQuestions = false;

  @override
  void initState() {
    super.initState();
    // Fetch all quizzes when the screen loads instead of all questions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizzesNotifierProvider.notifier).refreshQuizzes();
    });
  }

  void _viewQuestionsForQuiz(String quizId) {
    setState(() {
      selectedQuizId = quizId;
      showingQuestions = true;
      showingRandomQuestions = false;
    });
    ref.read(questionsProvider.notifier).fetchQuestionsByQuizId(quizId);
  }

  void _backToQuizzes() {
    setState(() {
      showingQuestions = false;
      selectedQuizId = null;
      showingRandomQuestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizzesAsync = ref.watch(quizzesNotifierProvider);
    final questionsAsync = ref.watch(questionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            showingQuestions ? 'Câu hỏi trong bài quiz' : 'Danh sách bài quiz'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (showingQuestions)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _backToQuizzes,
              tooltip: 'Quay lại danh sách quiz',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (showingQuestions && selectedQuizId != null) {
                ref
                    .read(questionsProvider.notifier)
                    .fetchQuestionsByQuizId(selectedQuizId!);
              } else if (showingRandomQuestions) {
                ref.read(questionsProvider.notifier).fetchRandomQuestions(10);
              } else {
                ref.read(quizzesNotifierProvider.notifier).refreshQuizzes();
              }
            },
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: showingQuestions
          ? _buildQuestionsView(questionsAsync)
          : _buildQuizzesView(quizzesAsync),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Add Quiz Button
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddQuizScreen(),
                ),
              ).then((_) {
                // Refresh quizzes when returning from add quiz screen
                ref.read(quizzesNotifierProvider.notifier).refreshQuizzes();
              });
            },
            heroTag: 'addQuiz',
            backgroundColor: Colors.amber[700],
            label: const Text('Thêm Quiz'),
            icon: const Icon(Icons.quiz),
          ),
          const SizedBox(height: 16),
          // Add Question Button
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddQuestionScreen(),
                ),
              ).then((_) {
                // Refresh questions if we're showing questions
                if (showingQuestions && selectedQuizId != null) {
                  ref
                      .read(questionsProvider.notifier)
                      .fetchQuestionsByQuizId(selectedQuizId!);
                }
              });
            },
            heroTag: 'addQuestion',
            backgroundColor: AppStyles.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesView(AsyncValue<List<Quiz>> quizzesAsync) {
    return quizzesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error loading quizzes: ${error.toString()}'),
      ),
      data: (quizzes) {
        if (quizzes.isEmpty) {
          return const Center(
            child: Text(
              'Chưa có bài quiz nào. Hãy tạo bài quiz mới!',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quizzes.length,
          itemBuilder: (context, index) {
            final quiz = quizzes[index];
            return _buildQuizCard(quiz);
          },
        );
      },
    );
  }

  Widget _buildQuestionsView(AsyncValue<List<Question>> questionsAsync) {
    return Column(
      children: [
        if (selectedQuizId != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Bài quiz: $selectedQuizId',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Expanded(
          child: questionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Text('Error: ${error.toString()}'),
            ),
            data: (questions) {
              if (questions.isEmpty) {
                return const Center(
                  child: Text(
                    'Chưa có câu hỏi nào trong quiz này',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return _buildQuestionCard(question);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuizCard(Quiz quiz) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 's10'.startsWith('s') ? 2 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewQuestionsForQuiz(quiz.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Đề ${quiz.title}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      quiz.categoryID,
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.timer, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${quiz.timeLimit} phút',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _viewQuestionsForQuiz(quiz.id),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Xem câu hỏi'),
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

  Widget _buildQuestionCard(Question question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question title
            Text(
              question.questionTitle,
              style: AppStyles.textBold.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Question image if available
            if (question.imageUrl != null && question.imageUrl!.isNotEmpty)
              Container(
                height: 150,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.network(
                  question.imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.image_not_supported,
                        color: Colors.grey[400]),
                  ),
                ),
              ),

            // Answer options
            ...List.generate(
              question.options.length,
              (i) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: i == question.correctOptionIndex
                      ? Colors.green[50]
                      : Colors.grey[50],
                  border: Border.all(
                    color: i == question.correctOptionIndex
                        ? Colors.green
                        : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == question.correctOptionIndex
                            ? Colors.green
                            : Colors.transparent,
                        border: Border.all(
                          color: i == question.correctOptionIndex
                              ? Colors.green
                              : Colors.grey[400]!,
                        ),
                      ),
                      child: i == question.correctOptionIndex
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        question.options[i],
                        style: TextStyle(
                          color: i == question.correctOptionIndex
                              ? Colors.green[800]
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quiz ID indicator if available
            if (question.quizId != null && question.quizId!.isNotEmpty)
              Align(
                alignment: Alignment.bottomRight,
                child: Chip(
                  label: Text(
                    'Đề ${question.quizId}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.blue[50],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
