import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/widgets/base64_image_widget.dart';
import 'package:gplx/core/widgets/countdown_timer.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test/models/quiz_result.dart';
import 'package:gplx/features/test/providers/quiz_providers.dart';
import 'package:gplx/features/test/providers/quiz_results_provider.dart';
import 'package:gplx/features/test/providers/vehicle_provider.dart';
import 'package:gplx/features/test/views/quiz_result_summary.dart';
import 'package:gplx/features/test_sets/models/test_set.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String testSetId;

  const QuizScreen({required this.testSetId, super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with TickerProviderStateMixin {
  List<Question> _questions = [];
  bool _isLoading = true;
  bool _quizCompleted = false;
  TestSet? _testSet;

  late int _remainingTimeInSeconds;
  Timer? _timer;

  DateTime? _startTime;

  late TabController _tabController;

  final Map<int, int> _selectedAnswers = {};
  final Map<int, bool> _checkedQuestions = {};

  int get _answeredCount => _selectedAnswers.length;

  int currentIndex = 0;
  int? selectedAnswer;
  bool _questionsLoaded = false;

  late QuizResult _quizResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadTestSetAndQuestions();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final testTime = ref.watch(selectedVehicleTypeProvider).minutes;
    final minPoint = ref.watch(selectedVehicleTypeProvider).minPoint;
    _quizResult = QuizResult(
      quizId: widget.testSetId,
      quizTitle: 'Đang tải...',
      totalQuestions: 0,
      correctAnswers: 0,
      wrongAnswers: 0,
      minPoint: minPoint,
      attemptDate: DateTime.now(),
    );
    _remainingTimeInSeconds = testTime * 60;
  }

  Future<void> _loadTestSetAndQuestions() async {
    if (_isLoading && _questionsLoaded) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _testSet = await ref.read(testSetProvider(widget.testSetId).future);

      if (_testSet == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _quizResult = _quizResult.copyWith(quizTitle: _testSet!.title);

      final questions = await ref.read(
        quizQuestionsProvider(widget.testSetId).future,
      );
      final testTime = ref.watch(selectedVehicleTypeProvider).minutes;

      if (!mounted) return;

      _remainingTimeInSeconds = testTime * 60;
      _startTime = DateTime.now();

      setState(() {
        _questions = questions;
        _tabController.dispose();
        _tabController = TabController(length: questions.length, vsync: this);
        _tabController.addListener(() {
          if (_tabController.indexIsChanging) {
            setState(() {
              selectedAnswer = _selectedAnswers[_tabController.index];
            });
          }
        });
        _isLoading = false;
        _questionsLoaded = true;
        _startTimer();
        _loadSavedProgress();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      print('Error loading Test set and questions: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _startTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTimeInSeconds > 0) {
          _remainingTimeInSeconds--;
        } else {
          _timer?.cancel();
          _completeQuiz();
        }
      });
    });
  }

  Future<void> _loadSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedQuizJson = prefs.getString(
        'quiz_progress_${widget.testSetId}',
      );

      if (savedQuizJson != null) {
        final savedData = jsonDecode(savedQuizJson) as Map<String, dynamic>;

        if (savedData.containsKey('selectedAnswers')) {
          final selectedAnswersMap =
              savedData['selectedAnswers'] as Map<String, dynamic>;
          _selectedAnswers.clear();
          selectedAnswersMap.forEach((key, value) {
            _selectedAnswers[int.parse(key)] = value as int;
          });
        }

        if (savedData.containsKey('checkedQuestions')) {
          final checkedQuestionsMap =
              savedData['checkedQuestions'] as Map<String, dynamic>;
          _checkedQuestions.clear();
          checkedQuestionsMap.forEach((key, value) {
            _checkedQuestions[int.parse(key)] = value as bool;
          });
        }

        if (savedData.containsKey('quizResult')) {
          final quizResultMap = savedData['quizResult'] as Map<String, dynamic>;
          _quizResult = QuizResult(
            quizId: quizResultMap['quizId'] as String,
            quizTitle: quizResultMap['quizTitle'] as String,
            totalQuestions: quizResultMap['totalQuestions'] as int,
            correctAnswers: quizResultMap['correctAnswers'] as int,
            wrongAnswers: quizResultMap['wrongAnswers'] as int,
            attemptDate: DateTime.parse(quizResultMap['attemptDate'] as String),
            failedCriticalQuestion:
                quizResultMap['failedCriticalQuestion'] as bool?,
            timeTaken: quizResultMap['timeTaken'] != null
                ? Duration(seconds: quizResultMap['timeTaken'] as int)
                : null,
            minPoint: quizResultMap['minPoint'] as int? ?? 0,
            isPassed: quizResultMap['isPassed'] as bool?,
          );
        }
      }
    } catch (e) {
      print('Error loading saved quiz progress: $e');
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final selectedAnswersMap = <String, int>{};
      _selectedAnswers.forEach((key, value) {
        selectedAnswersMap[key.toString()] = value;
      });

      final checkedQuestionsMap = <String, bool>{};
      _checkedQuestions.forEach((key, value) {
        checkedQuestionsMap[key.toString()] = value;
      });

      final savedData = {
        'selectedAnswers': selectedAnswersMap,
        'checkedQuestions': checkedQuestionsMap,
        'quizResult': _quizResult.toJson(),
        'lastSaved': DateTime.now().toIso8601String(),
      };

      await prefs.setString(
        'quiz_progress_${widget.testSetId}',
        jsonEncode(savedData),
      );
    } catch (e) {
      print('Error saving quiz progress: $e');
    }
  }

  Future<void> _clearSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('quiz_progress_${widget.testSetId}');
    } catch (e) {
      print('Error clearing saved quiz progress: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    if (!_quizCompleted) {
      _saveProgress();
    }

    _tabController.dispose();
    super.dispose();
  }

  bool _isAnswerCorrect(int questionIndex) {
    if (!_selectedAnswers.containsKey(questionIndex)) return false;

    final selectedAnswerIndex = _selectedAnswers[questionIndex]!;
    final question = _questions[questionIndex];

    if (selectedAnswerIndex >= question.answers.length) {
      return false;
    }

    return question.answers[selectedAnswerIndex].isCorrect;
  }

  void _updateQuizResult(int questionIndex, bool isCorrect) {
    setState(() {
      if (isCorrect) {
        _quizResult = _quizResult.copyWith(
          correctAnswers: _quizResult.correctAnswers + 1,
        );
      } else {
        _quizResult = _quizResult.copyWith(
          wrongAnswers: _quizResult.wrongAnswers + 1,
        );
      }

      _saveProgress();
    });
  }

  void _completeQuiz() {
    final Duration timeTaken;
    final testTime = ref.watch(selectedVehicleTypeProvider).minutes;

    if (_startTime != null) {
      int totalSeconds = testTime * 60;
      int elapsedSeconds = totalSeconds - _remainingTimeInSeconds;
      timeTaken = Duration(seconds: elapsedSeconds);
    } else {
      timeTaken = Duration.zero;
    }

    setState(() {
      bool failedCriticalQuestion = false;

      _selectedAnswers.forEach((questionIndex, selectedAnswerIndex) {
        if (!(_checkedQuestions[questionIndex] ?? false)) {
          _checkedQuestions[questionIndex] = true;
          final isCorrect = _isAnswerCorrect(questionIndex);
          final isCritical = _questions[questionIndex].isDeadPoint ?? false;

          if (isCritical && !isCorrect) {
            failedCriticalQuestion = true;
          }

          if (isCorrect) {
            _quizResult = _quizResult.copyWith(
              correctAnswers: _quizResult.correctAnswers + 1,
            );
          } else {
            _quizResult = _quizResult.copyWith(
              wrongAnswers: _quizResult.wrongAnswers + 1,
            );
          }
        }
      });

      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final isChecked = _checkedQuestions[i] ?? false;

        if (isChecked && (question.isDeadPoint ?? false)) {
          final isCorrect = _isAnswerCorrect(i);
          if (!isCorrect) {
            failedCriticalQuestion = true;
            break;
          }
        }
      }

      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final isCritical = question.isDeadPoint ?? false;
        final isAnswered = _selectedAnswers.containsKey(i);

        if (isCritical && !isAnswered) {
          failedCriticalQuestion = true;
          break;
        }
      }

      _quizResult = _quizResult.copyWith(
        timeTaken: timeTaken,
        attemptDate: DateTime.now(),
        failedCriticalQuestion: failedCriticalQuestion,
        totalQuestions: _questions.length,
      );

      _quizCompleted = true;

      _timer?.cancel();

      _saveTestResult();

      _clearSavedProgress();
    });
  }

  Future<void> _saveTestResult() async {
    try {
      final percentCorrect = _quizResult.totalQuestions > 0
          ? (_quizResult.correctAnswers / _quizResult.totalQuestions) * 100
          : 0.0;
      final bool passedCriticalQuestions =
          _quizResult.failedCriticalQuestion != true;
      final bool passedScoreThreshold = percentCorrect >= 84;

      final isPassed = passedCriticalQuestions && passedScoreThreshold;
      final updatedQuizResult = _quizResult.copyWith(
        attemptDate: DateTime.now(),
        isPassed: isPassed,
      );

      await ref
          .read(quizResultsNotifierProvider.notifier)
          .addResult(updatedQuizResult);
    } catch (e) {
      print('Error saving test result: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final testTime = ref.watch(selectedVehicleTypeProvider).minutes;
    final minPoint = ref.watch(selectedVehicleTypeProvider).minPoint;
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Đang tải bài quiz ...'),
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_testSet == null || _questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Không có câu hỏi nào cho bài quiz này',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_quizCompleted) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Kết quả - ${_testSet!.title}'),
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.share), onPressed: () {}),
          ],
        ),
        body: QuizResultSummary(
          quizResult: _quizResult,
          questions: _questions,
          selectedAnswers: _selectedAnswers,
          timeTaken: _quizResult.timeTaken ?? Duration.zero,
          onBackPressed: () {
            final _ = ref.refresh(quizResultsProvider);
            Navigator.pop(context);
          },
          onRetakeQuiz: () {
            setState(() {
              _selectedAnswers.clear();
              _checkedQuestions.clear();
              _quizCompleted = false;
              _quizResult = QuizResult(
                quizId: widget.testSetId,
                quizTitle: _testSet!.title,
                totalQuestions: _questions.length,
                correctAnswers: 0,
                wrongAnswers: 0,
                attemptDate: DateTime.now(),
                minPoint: minPoint,
              );

              _startTime = DateTime.now();
              _remainingTimeInSeconds = testTime * 60;
              _tabController.index = 0;
              _startTimer();
            });
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        primary: true,
        backgroundColor: AppStyles.primaryColor,
        leading: Center(
          child: Container(
            margin: const EdgeInsets.only(left: 5.0),
            child: Text(
              '$_answeredCount/${_questions.length}',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
        title: CountdownTimer(
          duration: Duration(seconds: _remainingTimeInSeconds),
          textStyle: const TextStyle(color: Colors.white, fontSize: 20),
          onTimerComplete: () {
            _completeQuiz();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
              onPressed: _completeQuiz,
              child: Text(
                'Hoàn thành',
                style: AppStyles.textBold.copyWith(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorWeight: 3,
            indicatorColor: AppStyles.primaryColor,
            labelColor: AppStyles.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: List.generate(_questions.length, (index) {
              final isChecked = _checkedQuestions[index] ?? false;
              final hasSelection = _selectedAnswers.containsKey(index);
              final isCorrect = isChecked ? _isAnswerCorrect(index) : false;

              Color? backgroundColor;
              Color? textColor;
              if (isChecked) {
                backgroundColor = isCorrect
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2);
                textColor =
                    isCorrect ? Colors.green.shade700 : Colors.red.shade700;
              } else if (hasSelection) {
                backgroundColor = Colors.blue.withValues(alpha: 0.2);
                textColor = Colors.blue.shade700;
              }

              return Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Câu ${index + 1}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: hasSelection ? FontWeight.bold : null,
                    ),
                  ),
                ),
              );
            }),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_questions.length, (questionIndex) {
                final question = _questions[questionIndex];
                final isChecked = _checkedQuestions[questionIndex] ?? false;

                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CÂU HỎI ${questionIndex + 1}:',
                        style: AppStyles.textBold.copyWith(
                          fontSize: AppStyles.fontSizeH,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question.content,
                        style: AppStyles.textBold.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      if (question.imageUrl != null &&
                          question.imageUrl!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          height: 150,
                          width: double.infinity,
                          child: Base64ImageWidget(
                            base64String: question.imageUrl!,
                          ),
                        ),
                      Expanded(
                        child: ListView(
                          children: [
                            ...List.generate(
                              question.answers.length,
                              (index) => _buildAnswerOption(
                                questionIndex: questionIndex,
                                optionIndex: index,
                                text: question.answers[index].answerContent,
                                isCorrect: question.answers[index].isCorrect,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (isChecked)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _isAnswerCorrect(questionIndex)
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _isAnswerCorrect(questionIndex)
                                        ? Colors.green
                                        : Colors.red,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isAnswerCorrect(questionIndex)
                                          ? 'Chính xác!'
                                          : 'Sai rồi!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _isAnswerCorrect(questionIndex)
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    Text(
                                      'Đáp án đúng: '
                                      '${question.answers.firstWhere((a) => a.isCorrect, orElse: () => question.answers.first).answerContent}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (question.explanation.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          'Giải thích: ${question.explanation}',
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                          ),
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
              }),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppStyles.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _tabController.index > 0
                          ? () {
                              _tabController.animateTo(
                                _tabController.index - 1,
                              );
                            }
                          : null,
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _showQuestionIndex(context);
                      },
                      icon: const Icon(
                        Icons.menu_book_outlined,
                        size: 25,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _tabController.index < _questions.length - 1
                      ? () {
                          _tabController.animateTo(_tabController.index + 1);
                        }
                      : null,
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedAnswers.containsKey(_tabController.index) &&
              !(_checkedQuestions[_tabController.index] ?? false))
            Transform.translate(
              offset: const Offset(0, -25),
              child: _buildCheckAnswerButton(_tabController.index),
            ),
        ],
      ),
    );
  }

  GestureDetector _buildCheckAnswerButton(int questionIndex) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _checkedQuestions[questionIndex] = true;
          _updateQuizResult(questionIndex, _isAnswerCorrect(questionIndex));
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          color: Colors.green,
          borderRadius: BorderRadius.circular(100),
        ),
        child: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }

  Future<dynamic> _showQuestionIndex(BuildContext context) {
    return showModalBottomSheet(
      enableDrag: true,
      showDragHandle: true,
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(bottom: 20),
          height: MediaQuery.of(context).size.height * 0.5,
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _questions.length,
            itemBuilder: (context, i) {
              final isCurrentQuestion = _tabController.index == i;
              final isChecked = _checkedQuestions[i] ?? false;
              final isCorrect = isChecked ? _isAnswerCorrect(i) : false;

              Color backgroundColor = Colors.lightBlue[100]!;
              Color textColor = Colors.black;

              if (isChecked) {
                if (isCorrect) {
                  backgroundColor = Colors.green[200]!;
                } else {
                  backgroundColor = Colors.red[200]!;
                }
              }

              if (isCurrentQuestion) {
                backgroundColor = Colors.blue[300]!;
                textColor = Colors.white;
              }

              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _tabController.animateTo(i);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(
                      8,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAnswerOption({
    required int questionIndex,
    required int optionIndex,
    required String text,
    required bool isCorrect,
  }) {
    final isSelected = _selectedAnswers[questionIndex] == optionIndex;
    final showResult = _checkedQuestions[questionIndex] ?? false;

    Color? backgroundColor;
    if (showResult) {
      if (isCorrect) {
        backgroundColor = Colors.green[50];
      } else if (isSelected && !isCorrect) {
        backgroundColor = Colors.red[50];
      }
    } else if (isSelected) {
      backgroundColor = Colors.blue[50];
    }

    return GestureDetector(
      onTap: (showResult)
          ? null
          : () {
              setState(() {
                _selectedAnswers[questionIndex] = optionIndex;
              });
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[400]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: showResult
                  ? Icon(
                      isCorrect ? Icons.check : Icons.close,
                      size: 16,
                      color: isCorrect ? Colors.green : Colors.red,
                    )
                  : null,
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: showResult && isCorrect ? Colors.green : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
