import 'package:flutter/material.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/widgets/base64_image_widget.dart';
import 'package:gplx/core/widgets/gradient_app_bar.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test/models/quiz_result.dart';
import 'package:gplx/features/test/views/quiz_screen.dart';

enum QuestionFilter { all, correct, wrong, skipped }

class QuizResultSummary extends StatefulWidget {
  final QuizResult quizResult;
  final List<Question> questions;
  final Map<int, int> selectedAnswers;
  final VoidCallback onBackPressed;
  final Future<String> Function() onRetakeQuiz;
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
      appBar: GradientAppBar(
        title: Text('Kết quả - ${widget.quizResult.quizTitle}'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
            _buildStatusBanner(isPassed),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            try {
              // Call the callback to get testSetId and clear data
              final testSetId = await widget.onRetakeQuiz();

              if (!mounted) return;

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => QuizScreen(testSetId: testSetId),
                ),
              );
            } catch (e) {
              debugPrint('Error retaking quiz: $e');
            }
          },
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Làm lại bài thi'),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(bool isPassed) {
    String message;

    if (isPassed) {
      message = 'Chúc mừng, bạn đã vượt qua bài thi!';
    } else {
      if (widget.quizResult.failedCriticalQuestion == true) {
        message = 'Bạn đã trả lời sai câu điểm liệt.';
      } else {
        message = 'Chưa đủ số câu đúng tối thiểu.';
      }
    }

    final total = widget.quizResult.totalQuestions;
    final correct = widget.quizResult.correctAnswers;
    final ratio = total == 0 ? 0.0 : correct / total;
    final minutes = widget.timeTaken.inMinutes;
    final seconds = widget.timeTaken.inSeconds % 60;
    final timeString = '$minutes:${seconds.toString().padLeft(2, '0')}';

    final gradient = isPassed
        ? const LinearGradient(
            colors: [Color(0xFF22C55E), Color(0xFF15803D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFFB7185), Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppPalette.radiusL),
        boxShadow: AppPalette.softShadow(gradient.colors.last),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$correct/$total',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${(ratio * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPassed ? 'ĐẠT' : 'KHÔNG ĐẠT',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 15, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        timeString,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
        children: [
          _buildStatItem(
            '${widget.quizResult.totalQuestions}',
            AppPalette.primary,
            Icons.article_rounded,
            'Tất cả',
            QuestionFilter.all,
            widget.quizResult.totalQuestions > 0,
          ),
          const SizedBox(width: 8),
          _buildStatItem(
            '${widget.quizResult.correctAnswers}',
            AppPalette.success,
            Icons.check_circle_rounded,
            'Đúng',
            QuestionFilter.correct,
            widget.quizResult.correctAnswers > 0,
          ),
          const SizedBox(width: 8),
          _buildStatItem(
            '${widget.quizResult.wrongAnswers}',
            AppPalette.danger,
            Icons.cancel_rounded,
            'Sai',
            QuestionFilter.wrong,
            widget.quizResult.wrongAnswers > 0,
          ),
          const SizedBox(width: 8),
          _buildStatItem(
            '$skippedCount',
            AppPalette.warning,
            Icons.help_rounded,
            'Bỏ qua',
            QuestionFilter.skipped,
            skippedCount > 0,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String count,
    Color color,
    IconData icon,
    String label,
    QuestionFilter filter,
    bool isEnabled,
  ) {
    final bool isActive = activeFilter == filter;

    return Expanded(
      child: Opacity(
        opacity: isEnabled ? 1 : 0.45,
        child: Material(
          color: isActive ? color : AppPalette.surface,
          borderRadius: BorderRadius.circular(AppPalette.radiusM),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppPalette.radiusM),
            onTap: isEnabled
                ? () {
                    setState(() {
                      activeFilter = filter;
                    });
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppPalette.radiusM),
                border: Border.all(
                  color: isActive ? color : AppPalette.border,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon,
                      size: 20, color: isActive ? Colors.white : color),
                  const SizedBox(height: 4),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isActive ? Colors.white : AppPalette.ink,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppPalette.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
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
            selectedAnswerIndex < widget.questions[i].answers!.length &&
            widget.questions[i].answers![selectedAnswerIndex].isCorrect;
        questionResults[i] = isCorrect;
      }
    }

    final List<int> questionsToShow = [];

    switch (activeFilter) {
      case QuestionFilter.all:
        questionsToShow.addAll(
          List.generate(widget.questions.length, (index) => index),
        );
        break;
      case QuestionFilter.correct:
        questionsToShow.addAll(
          questionResults.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key)
              .toList(),
        );
        break;
      case QuestionFilter.wrong:
        questionsToShow.addAll(
          questionResults.entries
              .where((entry) => entry.value == false)
              .map((entry) => entry.key)
              .toList(),
        );
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
              const Icon(Icons.inbox_rounded,
                  size: 48, color: AppPalette.inkFaint),
              const SizedBox(height: 16),
              Text(
                _getEmptyStateMessage(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, color: AppPalette.inkMuted),
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
                fontWeight: FontWeight.w800,
                color: AppPalette.ink,
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
              final bool isAnswered = questionResults.containsKey(
                questionIndex,
              );
              final bool isCorrect =
                  isAnswered ? questionResults[questionIndex]! : false;

              Color backgroundColor;
              Widget? icon;

              if (isAnswered) {
                if (isCorrect) {
                  backgroundColor = AppPalette.successSoft;
                  icon = const Icon(Icons.check_rounded,
                      color: AppPalette.success, size: 16);
                } else {
                  backgroundColor = AppPalette.dangerSoft;
                  icon = const Icon(Icons.close_rounded,
                      color: AppPalette.danger, size: 16);
                }
              } else {
                backgroundColor = AppPalette.warningSoft;
                icon = const Icon(
                  Icons.remove_rounded,
                  color: AppPalette.warning,
                  size: 16,
                );
              }

              return InkWell(
                borderRadius: BorderRadius.circular(AppPalette.radiusS),
                onTap: () {
                  _showQuestionDetail(context, questionIndex);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(AppPalette.radiusS),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '${questionIndex + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: isAnswered
                                ? (isCorrect
                                    ? AppPalette.success
                                    : AppPalette.danger)
                                : const Color(0xFFB45309),
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
                            Icons.priority_high_rounded,
                            color: AppPalette.danger,
                            size: 14,
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
        selectedAnswerIndex < question.answers!.length &&
        question.answers![selectedAnswerIndex].isCorrect;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
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
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isAnswered
                              ? (isCorrect
                                  ? AppPalette.successSoft
                                  : AppPalette.dangerSoft)
                              : AppPalette.warningSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Câu ${questionIndex + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isAnswered
                                ? (isCorrect
                                    ? AppPalette.success
                                    : AppPalette.danger)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                      if (question.isDeadPoint == true)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppPalette.danger,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Câu điểm liệt',
                                style: TextStyle(
                                  color: AppPalette.danger,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.content!,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (question.imageUrl != null &&
                          question.imageUrl!.isNotEmpty)
                        Container(
                          height: 150,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Base64ImageWidget(
                              base64String: question.imageUrl!),
                        ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: question.answers!.length,
                        itemBuilder: (context, index) {
                          final bool isCorrectOption =
                              question.answers![index].isCorrect;
                          final bool isSelected = selectedAnswerIndex == index;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _getAnswerBackgroundColor(
                                isSelected,
                                isCorrectOption,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppPalette.radiusM),
                              border: Border.all(
                                color: _getAnswerBorderColor(
                                  isSelected,
                                  isCorrectOption,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9),
                                    color: _getAnswerCircleColor(
                                      isSelected,
                                      isCorrectOption,
                                    ),
                                    border: isSelected || isCorrectOption
                                        ? null
                                        : Border.all(color: AppPalette.border),
                                  ),
                                  child: Center(
                                    child: _getAnswerIcon(
                                        isSelected, isCorrectOption),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    question.answers![index].content,
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.4,
                                      fontWeight: isSelected || isCorrectOption
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isCorrectOption
                                          ? const Color(0xFF14532D)
                                          : (isSelected && !isCorrectOption
                                              ? const Color(0xFF7F1D1D)
                                              : AppPalette.ink),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getAnswerBackgroundColor(bool isSelected, bool isCorrect) {
    if (isCorrect) {
      return AppPalette.successSoft;
    } else if (isSelected) {
      return AppPalette.dangerSoft;
    }
    return AppPalette.surface;
  }

  Color _getAnswerBorderColor(bool isSelected, bool isCorrect) {
    if (isCorrect) {
      return AppPalette.success;
    } else if (isSelected) {
      return AppPalette.danger;
    }
    return AppPalette.border;
  }

  Color _getAnswerCircleColor(bool isSelected, bool isCorrect) {
    if (isCorrect) {
      return AppPalette.success;
    } else if (isSelected) {
      return AppPalette.danger;
    }
    return AppPalette.background;
  }

  Widget? _getAnswerIcon(bool isSelected, bool isCorrect) {
    if (isCorrect) {
      return const Icon(Icons.check_rounded, color: Colors.white, size: 18);
    } else if (isSelected) {
      return const Icon(Icons.close_rounded, color: Colors.white, size: 18);
    }
    return null;
  }
}
