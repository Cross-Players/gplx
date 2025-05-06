import 'package:flutter/material.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/features/test/models/quiz_result.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:intl/intl.dart';

/// Filter enum for question filtering
enum QuestionFilter {
  all,
  correct,
  wrong,
  skipped,
}

/// A widget to display the summary of a completed quiz
class QuizResultSummary extends StatefulWidget {
  final QuizResult quizResult;
  final List<Question> questions;
  final Map<int, int> selectedAnswers;
  final VoidCallback onBackPressed;
  final VoidCallback onRetakeQuiz;

  const QuizResultSummary({
    required this.quizResult,
    required this.questions,
    required this.selectedAnswers,
    required this.onBackPressed,
    required this.onRetakeQuiz,
    super.key,
  });

  @override
  State<QuizResultSummary> createState() => _QuizResultSummaryState();
}

class _QuizResultSummaryState extends State<QuizResultSummary> {
  QuestionFilter activeFilter = QuestionFilter.all;

  @override
  Widget build(BuildContext context) {
    final percentCorrect = widget.quizResult.totalQuestions > 0
        ? (widget.quizResult.correctAnswers /
                widget.quizResult.totalQuestions) *
            100
        : 0.0;

    final isPassed = percentCorrect >= 80; // 80% to pass

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status banner (pass/fail)
            _buildStatusBanner(isPassed),

            // Timer and score display
            _buildTimerAndScoreRow(),

            // Stats summary
            _buildStatsSummary(),

            // Question grid
            _buildQuestionGrid(),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: widget.onRetakeQuiz,
                icon: const Icon(Icons.restart_alt),
                label: const Text(
                  'Làm lại bài quiz',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  backgroundColor: AppStyles.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Red or green banner showing pass/fail status
  Widget _buildStatusBanner(bool isPassed) {
    final String message =
        isPassed ? 'ĐẠT: Chúc mừng bạn!' : 'KHÔNG ĐẠT: Số câu đúng không đủ!';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: isPassed ? Colors.green[100] : Colors.red[100],
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isPassed ? Colors.green[800] : Colors.red[800],
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  // Row with timer icon, time taken, and score
  Widget _buildTimerAndScoreRow() {
    // If we have actual time data, we could use it here
    final timeString = DateFormat('mm:ss').format(
      DateTime.fromMillisecondsSinceEpoch(
        widget.quizResult.attemptDate.millisecond,
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Timer section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: const Icon(Icons.timer, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 8),
              Text(
                timeString,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          // Score section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check, color: Colors.green),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.quizResult.correctAnswers}/${widget.quizResult.totalQuestions}',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Percentage indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${(widget.quizResult.correctAnswers / widget.quizResult.totalQuestions * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Stats summary showing total, correct, wrong, and skipped questions
  Widget _buildStatsSummary() {
    final skippedCount = widget.quizResult.totalQuestions -
        widget.quizResult.correctAnswers -
        widget.quizResult.wrongAnswers;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Total questions
          _buildStatItem(
            '∑ ${widget.quizResult.totalQuestions}',
            Colors.blue,
            Icons.article,
            'Tổng số câu',
            QuestionFilter.all,
            widget.quizResult.totalQuestions > 0,
          ),

          // Correct answers
          _buildStatItem(
            '${widget.quizResult.correctAnswers}',
            Colors.green,
            Icons.check_circle_outline,
            'Đúng',
            QuestionFilter.correct,
            widget.quizResult.correctAnswers > 0,
          ),

          // Wrong answers
          _buildStatItem(
            '${widget.quizResult.wrongAnswers}',
            Colors.red,
            Icons.cancel_outlined,
            'Sai',
            QuestionFilter.wrong,
            widget.quizResult.wrongAnswers > 0,
          ),

          // Skipped questions
          _buildStatItem(
            '$skippedCount',
            Colors.orange,
            Icons.help_outline,
            'Bỏ qua',
            QuestionFilter.skipped,
            skippedCount > 0,
          ),
        ],
      ),
    );
  }

  // Individual stat item with icon and count
  Widget _buildStatItem(String count, Color color, IconData icon,
      String tooltip, QuestionFilter filter, bool isEnabled) {
    // Check if this filter is currently active
    final bool isActive = activeFilter == filter;

    // Make the item look disabled if it's not clickable (e.g., no items in that category)
    final opacity = isEnabled ? 1.0 : 0.5;

    return InkWell(
      onTap: isEnabled
          ? () {
              setState(() {
                activeFilter = filter;
              });
            }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Tooltip(
          message: tooltip,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: color.withOpacity(opacity)),
                  const SizedBox(width: 4),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                      color: color.withOpacity(opacity),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Highlight the active filter with a thicker line
              Container(
                width: 60,
                height: isActive ? 8 : 5,
                decoration: BoxDecoration(
                  color: color.withOpacity(isActive ? 0.7 : 0.3),
                  borderRadius: isActive ? BorderRadius.circular(4) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Grid of question buttons
  Widget _buildQuestionGrid() {
    // Map the selected answers to a question results map similar to TestResultScreen
    final Map<int, bool> questionResults = {};
    for (int i = 0; i < widget.questions.length; i++) {
      final selectedAnswerIndex = widget.selectedAnswers[i];
      if (selectedAnswerIndex != null) {
        final isCorrect =
            selectedAnswerIndex == widget.questions[i].correctOptionIndex;
        questionResults[i] = isCorrect;
      }
    }

    // Get all question indices based on the filter
    final List<int> questionsToShow = [];

    // Apply filtering based on the active filter
    switch (activeFilter) {
      case QuestionFilter.all:
        // Show all questions
        questionsToShow
            .addAll(List.generate(widget.questions.length, (index) => index));
        break;
      case QuestionFilter.correct:
        // Show only correctly answered questions
        questionsToShow.addAll(questionResults.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList());
        break;
      case QuestionFilter.wrong:
        // Show only incorrectly answered questions
        questionsToShow.addAll(questionResults.entries
            .where((entry) => entry.value == false)
            .map((entry) => entry.key)
            .toList());
        break;
      case QuestionFilter.skipped:
        // Show only skipped questions (not in questionResults)
        for (int i = 0; i < widget.questions.length; i++) {
          if (!questionResults.containsKey(i)) {
            questionsToShow.add(i);
          }
        }
        break;
    }

    // Handle empty state
    if (questionsToShow.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Icon(Icons.info_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _getEmptyStateMessage(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter indicator
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              _getFilterTitle(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Question grid
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1.0,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: questionsToShow.length,
            itemBuilder: (context, index) {
              final questionIndex = questionsToShow[index];
              final bool isAnswered =
                  questionResults.containsKey(questionIndex);
              final bool isCorrect =
                  isAnswered ? questionResults[questionIndex]! : false;

              Color backgroundColor;
              Widget? icon;

              if (isAnswered) {
                if (isCorrect) {
                  // Correct answer - green
                  backgroundColor = Colors.green[200]!;
                  icon = const Icon(Icons.check, color: Colors.green, size: 18);
                } else {
                  // Wrong answer - red
                  backgroundColor = Colors.red[200]!;
                  icon = const Icon(Icons.close, color: Colors.red, size: 18);
                }
              } else {
                // Unanswered/skipped question - gray/blue
                backgroundColor = Colors.blue[50]!;
                icon = const Icon(Icons.help_outline,
                    color: Colors.orange, size: 18);
              }

              return InkWell(
                onTap: () {
                  _showQuestionDetail(context, questionIndex);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Question number
                      Center(
                        child: Text(
                          'Câu ${questionIndex + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isAnswered
                                ? (isCorrect
                                    ? Colors.green[800]
                                    : Colors.red[800])
                                : Colors.black87,
                          ),
                        ),
                      ),

                      // Result icon at bottom
                      Positioned(
                        bottom: 4,
                        right: 0,
                        left: 0,
                        child: Center(child: icon),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper method to get filter title
  String _getFilterTitle() {
    switch (activeFilter) {
      case QuestionFilter.all:
        return 'Tất cả câu hỏi';
      case QuestionFilter.correct:
        return 'Các câu trả lời đúng';
      case QuestionFilter.wrong:
        return 'Các câu trả lời sai';
      case QuestionFilter.skipped:
        return 'Các câu bỏ qua';
    }
  }

  // Helper method to get empty state message
  String _getEmptyStateMessage() {
    switch (activeFilter) {
      case QuestionFilter.all:
        return 'Không có câu hỏi nào';
      case QuestionFilter.correct:
        return 'Không có câu trả lời đúng nào';
      case QuestionFilter.wrong:
        return 'Không có câu trả lời sai nào';
      case QuestionFilter.skipped:
        return 'Không có câu hỏi nào bị bỏ qua';
    }
  }

  void _showQuestionDetail(BuildContext context, int questionIndex) {
    final question = widget.questions[questionIndex];
    final selectedAnswerIndex = widget.selectedAnswers[questionIndex];
    final isAnswered = selectedAnswerIndex != null;
    final isCorrect =
        isAnswered && selectedAnswerIndex == question.correctOptionIndex;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isAnswered
                          ? (isCorrect
                              ? Colors.green.shade100
                              : Colors.red.shade100)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Câu ${questionIndex + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isAnswered
                            ? (isCorrect
                                ? Colors.green.shade800
                                : Colors.red.shade800)
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                question.questionTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (question.imageUrl != null && question.imageUrl!.isNotEmpty)
                Container(
                  height: 150,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: question.imageUrl!.startsWith('http')
                      ? Image.network(
                          question.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported, size: 50),
                        )
                      : Image.asset(
                          question.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported, size: 50),
                        ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: question.options.length,
                  itemBuilder: (context, index) {
                    final bool isCorrectOption =
                        index == question.correctOptionIndex;
                    final bool isSelected = selectedAnswerIndex == index;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: _getAnswerBackgroundColor(
                            isSelected, isCorrectOption),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getAnswerBorderColor(
                              isSelected, isCorrectOption),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getAnswerCircleColor(
                                  isSelected, isCorrectOption),
                              border: isSelected || isCorrectOption
                                  ? null
                                  : Border.all(color: Colors.grey),
                            ),
                            child: Center(
                              child:
                                  _getAnswerIcon(isSelected, isCorrectOption),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              question.options[index],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected || isCorrectOption
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCorrectOption
                                    ? Colors.green.shade800
                                    : (isSelected && !isCorrectOption
                                        ? Colors.red.shade800
                                        : Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper methods for question detail styling
  Color _getAnswerBackgroundColor(bool isSelected, bool isCorrect) {
    if (isCorrect) {
      return Colors.green.shade50;
    } else if (isSelected) {
      return Colors.red.shade50;
    }
    return Colors.grey.shade50;
  }

  Color _getAnswerBorderColor(bool isSelected, bool isCorrect) {
    if (isCorrect) {
      return Colors.green;
    } else if (isSelected) {
      return Colors.red;
    }
    return Colors.grey.shade300;
  }

  Color _getAnswerCircleColor(bool isSelected, bool isCorrect) {
    if (isCorrect) {
      return Colors.green;
    } else if (isSelected) {
      return Colors.red;
    }
    return Colors.transparent;
  }

  Widget? _getAnswerIcon(bool isSelected, bool isCorrect) {
    if (isCorrect) {
      return const Icon(Icons.check, color: Colors.white, size: 20);
    } else if (isSelected) {
      return const Icon(Icons.close, color: Colors.white, size: 20);
    }
    return null;
  }
}
