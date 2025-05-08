import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/routes/app_routes.dart';
import 'package:gplx/core/widgets/countdown_timer.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test/models/quiz.dart';
import 'package:gplx/features/test/models/quiz_result.dart';
import 'package:gplx/features/test/providers/firestore_providers.dart';
import 'package:gplx/features/test/views/quiz_result_summary.dart';
import 'package:gplx/features/test_sets/controllers/test_results_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A dedicated page for taking a specific quiz from Firebase
class QuizPage extends ConsumerStatefulWidget {
  /// The ID of the quiz to load from Firebase
  final String quizId;

  const QuizPage({required this.quizId, super.key});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage>
    with TickerProviderStateMixin {
  // Quiz and question data
  Quiz? _quiz;
  List<Question> _questions = [];
  bool _isLoading = true;
  bool _quizCompleted = false;

  // Timer state
  int _remainingTimeInSeconds = 20 * 60; // Default 20 minutes
  Timer? _timer;

  // Track quiz start time to calculate duration
  DateTime? _startTime;

  // Tab controller for question navigation
  late TabController _tabController;

  // Track user responses
  final Map<int, int> _selectedAnswers =
      {}; // questionIndex -> selectedOptionIndex
  final Map<int, bool> _checkedQuestions =
      {}; // questionIndex -> hasBeenChecked

  // Computed property to track number of answered questions
  int get _answeredCount => _selectedAnswers.length;

  // Quiz result data
  late QuizResult _quizResult;

  @override
  void initState() {
    super.initState();

    // Initialize with a dummy TabController (we'll replace it once questions are loaded)
    _tabController = TabController(length: 0, vsync: this);

    // Load the quiz and questions - delay with Future.microtask to avoid provider issues
    Future.microtask(() => _loadQuizAndQuestions());
  }

  Future<void> _loadQuizAndQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if we have saved progress for this quiz
      await _loadSavedProgress();

      // Load the quiz details first
      final quizAsync = await ref
          .read(firestoreQuizzesRepositoryProvider)
          .getQuizById(widget.quizId);
      if (!mounted) return;

      if (quizAsync != null) {
        _quiz = quizAsync;

        // Set timer based on quiz time limit
        if (_quiz?.timeLimit != null && _quiz!.timeLimit > 0) {
          _remainingTimeInSeconds = _quiz!.timeLimit * 60;
        }
      }

      // Then load the questions for this quiz
      await ref
          .read(questionsProvider.notifier)
          .fetchQuestionsByQuizId(widget.quizId);
      if (!mounted) return;

      // Get the actual questions from the provider state
      final questionsAsync = ref.read(questionsProvider);

      questionsAsync.when(
        data: (questions) {
          if (!mounted) return;

          setState(() {
            _questions = questions;

            // Dispose the old controller before creating a new one
            _tabController.dispose();

            // Create a new controller with the correct number of tabs
            _tabController =
                TabController(length: _questions.length, vsync: this);

            // Add listener for tab changes - only trigger setState when the tab index is changing
            _tabController.addListener(() {
              if (_tabController.indexIsChanging) {
                setState(() {});
                // Auto-save progress when changing tabs
                _saveProgress();
              }
            });

            _isLoading = false;

            // Initialize quiz result tracking if we don't have saved data
            _quizResult = QuizResult(
              quizId: widget.quizId,
              quizTitle: _quiz?.title ?? 'Quiz ${widget.quizId}',
              totalQuestions: _questions.length,
              correctAnswers: 0,
              wrongAnswers: 0,
              attemptDate: DateTime.now(),
            );

            // Start timer
            _startTimer();
          });
        },
        loading: () {
          // Keep the loading state
        },
        error: (error, stackTrace) {
          if (!mounted) return;

          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi tải câu hỏi: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Thử lại',
                onPressed: _loadQuizAndQuestions,
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      // Log the error
      print('Error loading quiz or questions: $e');

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải câu hỏi: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Thử lại',
            onPressed: _loadQuizAndQuestions,
          ),
        ),
      );
    }
  }

  void _startTimer() {
    // Cancel any existing timer
    _timer?.cancel();

    // Set the start time of the quiz
    _startTime ??= DateTime.now();

    // Create a new timer that ticks every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTimeInSeconds > 0) {
          _remainingTimeInSeconds--;
        } else {
          // Time's up, complete the quiz
          _timer?.cancel();
          _completeQuiz();
        }
      });
    });
  }

  Future<void> _loadSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedQuizJson = prefs.getString('quiz_progress_${widget.quizId}');

      if (savedQuizJson != null) {
        final savedData = jsonDecode(savedQuizJson) as Map<String, dynamic>;

        // Restore selected answers
        if (savedData.containsKey('selectedAnswers')) {
          final selectedAnswersMap =
              savedData['selectedAnswers'] as Map<String, dynamic>;
          _selectedAnswers.clear();
          selectedAnswersMap.forEach((key, value) {
            _selectedAnswers[int.parse(key)] = value as int;
          });
        }

        // Restore checked questions
        if (savedData.containsKey('checkedQuestions')) {
          final checkedQuestionsMap =
              savedData['checkedQuestions'] as Map<String, dynamic>;
          _checkedQuestions.clear();
          checkedQuestionsMap.forEach((key, value) {
            _checkedQuestions[int.parse(key)] = value as bool;
          });
        }

        // Restore quiz result
        if (savedData.containsKey('quizResult')) {
          final quizResultMap = savedData['quizResult'] as Map<String, dynamic>;
          _quizResult = QuizResult(
            quizId: quizResultMap['quizId'] as String,
            quizTitle: quizResultMap['quizTitle'] as String,
            totalQuestions: quizResultMap['totalQuestions'] as int,
            correctAnswers: quizResultMap['correctAnswers'] as int,
            wrongAnswers: quizResultMap['wrongAnswers'] as int,
            attemptDate: DateTime.parse(quizResultMap['attemptDate'] as String),
          );
        }

        // Restore remaining time
        if (savedData.containsKey('remainingTime')) {
          _remainingTimeInSeconds = savedData['remainingTime'] as int;
        }
      }
    } catch (e) {
      print('Error loading saved quiz progress: $e');
      // Continue without saved progress if there's an error
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert maps with int keys to maps with string keys for JSON serialization
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
        'remainingTime': _remainingTimeInSeconds,
        'lastSaved': DateTime.now().toIso8601String(),
      };

      await prefs.setString(
          'quiz_progress_${widget.quizId}', jsonEncode(savedData));
    } catch (e) {
      print('Error saving quiz progress: $e');
      // Continue without saving if there's an error
    }
  }

  Future<void> _clearSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('quiz_progress_${widget.quizId}');
    } catch (e) {
      print('Error clearing saved quiz progress: $e');
    }
  }

  @override
  void dispose() {
    // Cancel timer
    _timer?.cancel();

    // Save current progress before leaving
    if (!_quizCompleted) {
      _saveProgress();
    }

    // Make sure to dispose the tab controller
    _tabController.dispose();
    super.dispose();
  }

  // Check if the selected answer is correct
  bool _isAnswerCorrect(int questionIndex) {
    final selectedAnswerIndex = _selectedAnswers[questionIndex];
    if (selectedAnswerIndex == null) return false;

    final question = _questions[questionIndex];
    return selectedAnswerIndex == question.correctOptionIndex;
  }

  // Update the quiz result when an answer is checked
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

      // Save progress after updating result
      _saveProgress();
    });
  }

  // Complete the quiz and show results
  void _completeQuiz() {
    // Calculate the time taken to complete the quiz
    final Duration timeTaken;
    if (_startTime != null) {
      // Calculate as quiz time limit minus remaining time
      int totalSeconds = (_quiz?.timeLimit ?? 20) * 60; // Default 20 minutes
      int elapsedSeconds = totalSeconds - _remainingTimeInSeconds;
      timeTaken = Duration(seconds: elapsedSeconds);
    } else {
      timeTaken = Duration.zero;
    }

    setState(() {
      // Track if any critical questions were answered incorrectly
      bool failedCriticalQuestion = false;

      // Auto-evaluate any selected but unchecked questions
      _selectedAnswers.forEach((questionIndex, selectedAnswerIndex) {
        if (!(_checkedQuestions[questionIndex] ?? false)) {
          _checkedQuestions[questionIndex] = true;
          final isCorrect = _isAnswerCorrect(questionIndex);
          final isCritical = _questions[questionIndex].isCritical ?? false;

          // Check if this is a critical question that was answered incorrectly
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

      // Check if any already-checked critical questions were failed
      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final isChecked = _checkedQuestions[i] ?? false;

        if (isChecked && (question.isCritical ?? false)) {
          final isCorrect = _isAnswerCorrect(i);
          if (!isCorrect) {
            failedCriticalQuestion = true;
            break;
          }
        }
      }

      // NEW CODE: Check if any critical questions were skipped (not answered at all)
      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final isCritical = question.isCritical ?? false;
        final isAnswered = _selectedAnswers.containsKey(i);

        // If a critical question wasn't answered at all, fail the test
        if (isCritical && !isAnswered) {
          failedCriticalQuestion = true;
          break;
        }
      }

      // Store the calculated time taken and critical question status in the state
      _quizResult = _quizResult.copyWith(
        timeTaken: timeTaken,
        attemptDate: DateTime.now(), // Update to current time
        failedCriticalQuestion: failedCriticalQuestion,
      );

      // Mark quiz as completed
      _quizCompleted = true;

      // Stop timer
      _timer?.cancel();

      // Save the result to the TestResultsRepository
      _saveTestResult();

      // Clear saved progress as we've completed the quiz
      _clearSavedProgress();
    });
  }

  // Save the test result to the repository and Riverpod state
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
        attemptDate: DateTime.now(), // Update to current time
        isPassed: isPassed,
      );

      // Save to Riverpod state first (this will update the UI immediately)
      await ref
          .read(testResultsNotifierProvider.notifier)
          .addResult(updatedQuizResult);

      // No need to save to repository separately since the notifier already does that
    } catch (e) {
      print('Error saving test result: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while questions are being loaded
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Đang tải bài quiz ${widget.quizId}...'),
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error state if no questions found
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz ${widget.quizId}'),
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
              ElevatedButton(
                onPressed: _loadQuizAndQuestions,
                child: const Text('Thử lại'),
              ),
              const SizedBox(height: 10),
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

    // If quiz is completed, show the results page
    if (_quizCompleted) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Kết quả - ${_quiz?.title ?? "Quiz ${widget.quizId}"}'),
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Share functionality would go here
              },
            ),
          ],
        ),
        body: QuizResultSummary(
          quizResult: _quizResult,
          questions: _questions,
          selectedAnswers: _selectedAnswers,
          timeTaken: _quizResult.timeTaken ?? Duration.zero,
          onBackPressed: () {
            // Refresh the test results provider before navigating back
            final _ = ref.refresh(testResultsProvider);

            // Instead of simple pop, navigate back to the test-sets screen with replacement
            // This ensures a fresh instance of TestSetsScreen with updated data
            Navigator.pushReplacementNamed(context, AppRoutes.testSets);
          },
          onRetakeQuiz: () {
            setState(() {
              _selectedAnswers.clear();
              _checkedQuestions.clear();
              _quizCompleted = false;
              _quizResult = QuizResult(
                quizId: widget.quizId,
                quizTitle: _quiz?.title ?? 'Quiz ${widget.quizId}',
                totalQuestions: _questions.length,
                correctAnswers: 0,
                wrongAnswers: 0,
                attemptDate: DateTime.now(),
              );

              // Reset timer and start time
              _startTime = DateTime.now();
              _remainingTimeInSeconds =
                  _quiz?.timeLimit != null ? _quiz!.timeLimit * 60 : 20 * 60;
              _startTimer();
            });
          },
        ),
      );
    }

    // Main quiz interface - Styled to match TestQuestionScreen
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

              // Set color based on whether answer was checked and correct
              Color? backgroundColor;
              Color? textColor;
              if (isChecked) {
                backgroundColor = isCorrect
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2);
                textColor =
                    isCorrect ? Colors.green.shade700 : Colors.red.shade700;
              } else if (hasSelection) {
                // Blue for selected but not checked
                backgroundColor = Colors.blue.withOpacity(0.1);
                textColor = Colors.blue.shade700;
              }

              return Tab(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        question.questionTitle,
                        style: AppStyles.textBold.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      if (question.imageUrl != null &&
                          question.imageUrl!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          height: 150,
                          width: double.infinity,
                          child: question.imageUrl!.startsWith('http')
                              ? Image.network(
                                  question.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[400],
                                      size: 50,
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  question.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[400],
                                      size: 50,
                                    ),
                                  ),
                                ),
                        ),
                      Expanded(
                        child: ListView(
                          children: [
                            ...List.generate(
                              question.options.length,
                              (index) => _buildAnswerOption(
                                questionIndex: questionIndex,
                                optionIndex: index,
                                text: question.options[index],
                                isCorrect: index == question.correctOptionIndex,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Answer feedback after checking
                            if (isChecked)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _isAnswerCorrect(questionIndex)
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
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
                                      'Đáp án đúng: ${question.options[question.correctOptionIndex]}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
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
          // Main bottom navigation bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppStyles.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                              _tabController
                                  .animateTo(_tabController.index - 1);
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
              borderRadius: BorderRadius.circular(100)),
          child: const Icon(
            Icons.check,
            color: Colors.white,
          ),
        ));
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
              crossAxisCount: 6, // 6 items per row
              childAspectRatio: 1, // square items
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _questions.length,
            itemBuilder: (context, i) {
              final isCurrentQuestion = _tabController.index == i;
              final isChecked = _checkedQuestions[i] ?? false;
              final isCorrect = isChecked ? _isAnswerCorrect(i) : false;

              // Determine background color
              Color backgroundColor =
                  Colors.lightBlue[100]!; // Default light blue
              Color textColor = Colors.black;

              if (isChecked) {
                if (isCorrect) {
                  backgroundColor = Colors.green[200]!; // Green for correct
                } else {
                  backgroundColor = Colors.red[200]!; // Red for incorrect
                }
              }

              if (isCurrentQuestion) {
                backgroundColor =
                    Colors.blue[300]!; // Blue for current question
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
                // Only update selection, don't mark as checked/answered yet
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
