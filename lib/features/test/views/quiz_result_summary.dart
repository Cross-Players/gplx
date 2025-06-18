import 'package:flutter/material.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/widgets/base64_image_widget.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test/models/quiz_result.dart';

enum QuestionFilter {
  all,
  correct,
  wrong,
  skipped,
}

class QuizResultSummary extends StatefulWidget {
  final QuizResult quizResult;
  final List<Question> questions;
  final Map<int, int> selectedAnswers;
  final VoidCallback onBackPressed;
  final VoidCallback onRetakeQuiz;
  final Duration timeTaken;

  const QuizResultSummary({
    required this.quizResult,
    required this.questions,
    required this.selectedAnswers,
    required this.onBackPressed,
    required this.onRetakeQuiz,
    required this.timeTaken,
    super.key,
  });

  @override
  State<QuizResultSummary> createState() => _QuizResultSummaryState();
}

class _QuizResultSummaryState extends State<QuizResultSummary> {
  QuestionFilter activeFilter = QuestionFilter.all;

  @override
  Widget build(BuildContext context) {
    final bool passedCriticalQuestions =
        widget.quizResult.failedCriticalQuestion != true;
    final bool isAboveMinScore =
        widget.quizResult.correctAnswers >= widget.quizResult.minPoint;

    final isPassed = passedCriticalQuestions && isAboveMinScore;

    return Scaffold(
      appBar: AppBar(
        title: Text('Kết quả - ${widget.quizResult.quizTitle}'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.share))],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusBanner(isPassed),
            _buildTimerAndScoreRow(),
            _buildStatsSummary(),
            _buildQuestionGrid(),
            _buildRetakeTestButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRetakeTestButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: widget.onRetakeQuiz,
        icon: const Icon(Icons.restart_alt),
        label: const Text(
          'Làm lại bài quiz',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(bool isPassed) {
    String message;

    if (isPassed) {
      message = 'ĐẠT: Chúc mừng bạn!';
    } else {
      if (widget.quizResult.failedCriticalQuestion == true) {
        message = 'KHÔNG ĐẠT: Câu điểm liệt sai!';
      } else {
        message = 'KHÔNG ĐẠT: Không đủ số lượng câu đúng.';
      }
    }

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

  Widget _buildTimerAndScoreRow() {
    final minutes = widget.timeTaken.inMinutes;
    final seconds = widget.timeTaken.inSeconds % 60;
    final timeString = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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

  Widget _buildStatsSummary() {
    final skippedCount = widget.quizResult.totalQuestions -
        widget.quizResult.correctAnswers -
        widget.quizResult.wrongAnswers;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            '∑ ${widget.quizResult.totalQuestions}',
            Colors.blue,
            Icons.article,
            'Tổng số câu',
            QuestionFilter.all,
            widget.quizResult.totalQuestions > 0,
          ),
          _buildStatItem(
            '${widget.quizResult.correctAnswers}',
            Colors.green,
            Icons.check_circle_outline,
            'Đúng',
            QuestionFilter.correct,
            widget.quizResult.correctAnswers > 0,
          ),
          _buildStatItem(
            '${widget.quizResult.wrongAnswers}',
            Colors.red,
            Icons.cancel_outlined,
            'Sai',
            QuestionFilter.wrong,
            widget.quizResult.wrongAnswers > 0,
          ),
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

  Widget _buildStatItem(String count, Color color, IconData icon,
      String tooltip, QuestionFilter filter, bool isEnabled) {
    final bool isActive = activeFilter == filter;

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
                  Icon(icon, color: color.withValues(alpha: opacity)),
                  const SizedBox(width: 4),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                      color: color.withValues(alpha: opacity),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: 60,
                height: isActive ? 8 : 5,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isActive ? 0.7 : 0.3),
                  borderRadius: isActive ? BorderRadius.circular(4) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionGrid() {
    final Map<int, bool> questionResults = {};
    for (int i = 0; i < widget.questions.length; i++) {
      final selectedAnswerIndex = widget.selectedAnswers[i];
      if (selectedAnswerIndex != null) {
        final isCorrect = selectedAnswerIndex >= 0 &&
            selectedAnswerIndex < widget.questions[i].answers.length &&
            widget.questions[i].answers[selectedAnswerIndex].isCorrect;
        questionResults[i] = isCorrect;
      }
    }

    final List<int> questionsToShow = [];

    switch (activeFilter) {
      case QuestionFilter.all:
        questionsToShow
            .addAll(List.generate(widget.questions.length, (index) => index));
        break;
      case QuestionFilter.correct:
        questionsToShow.addAll(questionResults.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList());
        break;
      case QuestionFilter.wrong:
        questionsToShow.addAll(questionResults.entries
            .where((entry) => entry.value == false)
            .map((entry) => entry.key)
            .toList());
        break;
      case QuestionFilter.skipped:
        for (int i = 0; i < widget.questions.length; i++) {
          if (!questionResults.containsKey(i)) {
            questionsToShow.add(i);
          }
        }
        break;
    }

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
                  backgroundColor = Colors.green[200]!;
                  icon = const Icon(Icons.check, color: Colors.green, size: 18);
                } else {
                  backgroundColor = Colors.red[200]!;
                  icon = const Icon(Icons.close, color: Colors.red, size: 18);
                }
              } else {
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
                      Positioned(
                        bottom: 4,
                        right: 0,
                        left: 0,
                        child: Center(child: icon),
                      ),
                      if (widget.questions[questionIndex].isDeadPoint == true)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
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

    final isCorrect = isAnswered &&
        selectedAnswerIndex >= 0 &&
        selectedAnswerIndex < question.answers.length &&
        question.answers[selectedAnswerIndex].isCorrect;

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
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
                      if (question.isDeadPoint == true)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Câu điểm liệt',
                                style: TextStyle(
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                question.content,
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
                    child: Base64ImageWidget(
                      base64String: question.imageUrl!,
                    )),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: question.answers.length,
                itemBuilder: (context, index) {
                  final bool isCorrectOption =
                      question.answers[index].isCorrect;
                  final bool isSelected = selectedAnswerIndex == index;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: _getAnswerBackgroundColor(
                          isSelected, isCorrectOption),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            _getAnswerBorderColor(isSelected, isCorrectOption),
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
                            child: _getAnswerIcon(isSelected, isCorrectOption),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            question.answers[index].answerContent,
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
              if (question.explanation.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Giải thích:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question.explanation,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

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
