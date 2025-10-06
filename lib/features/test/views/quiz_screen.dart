import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/widgets/countdown_timer.dart';
import 'package:gplx/features/test/constants/quiz_constants.dart';
import 'package:gplx/features/test/models/license_data.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test/models/quiz_result.dart';
import 'package:gplx/features/test/models/vehicle.dart';
import 'package:gplx/features/test/providers/quiz_results_provider.dart';
import 'package:gplx/features/test/services/quiz_logic_service.dart';
import 'package:gplx/features/test/services/quiz_progress_service.dart';
import 'package:gplx/features/test/services/quiz_timer_service.dart';
import 'package:gplx/features/test/views/components/question_view_widget.dart';
import 'package:gplx/features/test/views/components/quiz_ui_components.dart';
import 'package:gplx/features/test/views/quiz_result_summary.dart';
import 'package:gplx/features/test_sets/controllers/test_controller.dart';
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
  // Services
  late final QuizTimerService _timerService;
  late final QuizProgressService _progressService;

  // Core data
  final List<Question> _questions = [];
  TestSet? _testSet;
  late QuizResult _quizResult;

  // State
  bool _isLoading = true;
  bool _quizCompleted = false;
  bool _questionsLoaded = false;

  // Navigation
  late TabController _tabController;

  // User interaction
  final Map<int, int> _selectedAnswers = {};
  final Map<int, bool> _checkedQuestions = {};

  // Getters
  int get _answeredCount => _selectedAnswers.length;
  int get _testTime => ref.read(selectedVehicleTypeProvider).minutes;
  int get _minPoint => ref.read(selectedVehicleTypeProvider).minPoint;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    SchedulerBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeQuizResult();
    _loadTestSetAndQuestions();
  }

  /// Initialize quiz result
  void _initializeQuizResult() {
    _quizResult = QuizResult(
      quizId: widget.testSetId,
      quizTitle: 'Đang tải...',
      totalQuestions: 0,
      correctAnswers: 0,
      wrongAnswers: 0,
      minPoint: _minPoint,
      attemptDate: DateTime.now(),
    );
  }

  /// Initialize services
  void _initializeServices() {
    _timerService = QuizTimerService();
    _progressService = QuizProgressService.instance;
  }

  /// Load test set and questions
  Future<void> _loadTestSetAndQuestions() async {
    if (_questionsLoaded) return;

    _setLoadingState(true);

    try {
      // Check if this is a dead point questions quiz
      if (widget.testSetId.startsWith('deadpoints-')) {
        await _loadDeadPointQuestions();
        return;
      }

      // Parse testSetId expected like '01-A1' or '01-A'
      final parts = widget.testSetId.split('-');
      int testNumber = 1;
      String vehicleStr = '';
      if (parts.isNotEmpty) {
        // first part might be '01' or '01'
        testNumber = int.tryParse(parts[0].replaceAll(RegExp(r'^0+'), '')) ?? 1;
      }
      if (parts.length > 1) {
        vehicleStr = parts.sublist(1).join('-');
      }

      // Resolve license type from string
      LicenseType licenseType;
      try {
        licenseType = LicenseType.values.firstWhere(
          (e) => e.name == vehicleStr,
        );
      } catch (_) {
        // fallback to selected vehicle provider's type
        licenseType = ref.read(selectedVehicleTypeProvider).vehicleType;
      }

      _initializeServices();

      // Fetch questions via controller
      final controller = TestController();
      final questions = await controller.fetchQuestionsByTestSets(
        licenseType,
        testNumber,
      );

      if (questions.isEmpty) {
        _handleError(QuizConstants.noQuestionsMessage);
        return;
      }
      // set test set meta
      _testSet = TestSet(
        id: widget.testSetId,
        title: 'Đề $testNumber - ${licenseType.name}',
        vehicleType: licenseType.name,
        questionNumbers: List.generate(questions.length, (i) => i + 1),
      );

      _questions.clear();
      _questions.addAll(questions);

      // setup controller and timer
      _tabController.dispose();
      _tabController = TabController(length: _questions.length, vsync: this);
      _tabController.addListener(_onTabChanged);

      // initialize timer with a mounted-guarded callback to avoid calling
      // setState after this State has been disposed.
      _timerService.initialize(
        _testTime,
        onComplete: () {
          if (mounted) _completeQuiz();
        },
      );

      // load saved progress if any
      try {
        final savedProgress = await _progressService.loadProgress(
          widget.testSetId,
        );
        if (savedProgress != null) {
          _selectedAnswers.clear();
          _selectedAnswers.addAll(savedProgress.selectedAnswers);

          _checkedQuestions.clear();
          _checkedQuestions.addAll(savedProgress.checkedQuestions);

          if (savedProgress.quizResult != null) {
            _quizResult = savedProgress.quizResult!;
          }
        }
      } catch (_) {}

      if (!mounted) return;
      _startQuiz();
    } catch (e) {
      _handleError('${QuizConstants.loadingErrorMessage}$e');
    }
  }

  /// Load dead point questions for the selected license type
  Future<void> _loadDeadPointQuestions() async {
    try {
      // Extract license type from testSetId (format: 'deadpoints-A1')
      final parts = widget.testSetId.split('-');
      String vehicleStr = '';
      if (parts.length > 1) {
        vehicleStr = parts.sublist(1).join('-');
      }

      // Resolve license type from string
      LicenseType licenseType;
      try {
        licenseType = LicenseType.values.firstWhere(
          (e) => e.name == vehicleStr,
        );
      } catch (_) {
        // fallback to selected vehicle provider's type
        licenseType = ref.read(licenseTypeProvider);
      }

      _initializeServices();

      // Fetch dead point questions via controller
      final controller = TestController();
      final questions = await controller.fetchDeadPointQuestions(licenseType);

      if (questions.isEmpty) {
        _handleError(
          'Không có câu hỏi điểm liệt nào cho hạng ${licenseType.name}',
        );
        return;
      }

      // set test set meta for dead point questions
      _testSet = TestSet(
        id: widget.testSetId,
        title: 'Câu điểm liệt - Hạng ${licenseType.name}',
        vehicleType: licenseType.name,
        questionNumbers: List.generate(questions.length, (i) => i + 1),
      );

      _questions.clear();
      _questions.addAll(questions);

      // Sort questions by question number in ascending order
      _questions.sort((a, b) {
        final aNumber = a.number ?? 0;
        final bNumber = b.number ?? 0;
        return aNumber.compareTo(bNumber);
      });

      // setup controller and timer (no time limit for dead point questions)
      _tabController.dispose();
      _tabController = TabController(length: _questions.length, vsync: this);
      _tabController.addListener(_onTabChanged);

      // initialize timer with unlimited time (set to a very high value)
      _timerService.initialize(
        300,
        onComplete: () {
          if (mounted) _completeQuiz();
        },
      );

      // load saved progress if any
      try {
        final savedProgress = await _progressService.loadProgress(
          widget.testSetId,
        );
        if (savedProgress != null) {
          _selectedAnswers.clear();
          _selectedAnswers.addAll(savedProgress.selectedAnswers);

          _checkedQuestions.clear();
          _checkedQuestions.addAll(savedProgress.checkedQuestions);

          if (savedProgress.quizResult != null) {
            _quizResult = savedProgress.quizResult!;
          }
        }
      } catch (_) {}

      if (!mounted) return;
      _startQuiz();
    } catch (e) {
      _handleError('Lỗi khi tải câu hỏi điểm liệt: $e');
    }
  }

  /// Start quiz
  void _startQuiz() {
    setState(() {
      _isLoading = false;
      _questionsLoaded = true;
    });
    _timerService.start();
  }

  /// Tab changed handler
  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  /// Set loading state
  void _setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  /// Handle errors
  void _handleError(String message) {
    // ignore: avoid_print
    print(message);
    _setLoadingState(false);
  }

  /// Save progress
  Future<void> _saveProgress() async {
    try {
      await _progressService.saveProgress(
        testSetId: widget.testSetId,
        selectedAnswers: _selectedAnswers,
        checkedQuestions: _checkedQuestions,
        quizResult: _quizResult,
      );
    } catch (e) {
      // ignore: avoid_print
      print('${QuizConstants.saveProgressErrorMessage} $e');
    }
  }

  /// Check if answer is correct
  bool _isAnswerCorrect(int questionIndex) {
    return QuizLogicService.isAnswerCorrect(
      questions: _questions,
      questionIndex: questionIndex,
      selectedAnswers: _selectedAnswers,
    );
  }

  /// Show confirmation dialog
  Future<void> _showConfirmationDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text(QuizConstants.confirmSubmitTitle),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                QuizConstants.cancelButtonText,
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _completeQuiz();
              },
              child: const Text(QuizConstants.submitButtonText),
            ),
          ],
        );
      },
    );
  }

  /// Complete quiz: evaluate answers, stop timer, save result and show result screen
  void _completeQuiz() async {
    // Stop timer
    _timerService.stop();

    final timeTaken = _timerService.getElapsedTime(_testTime);

    final failedCriticalQuestion =
        QuizLogicService.checkCriticalQuestionsFailed(
      questions: _questions,
      selectedAnswers: _selectedAnswers,
    );

    // Calculate correct/wrong counts
    int correct = 0;
    int wrong = 0;
    for (int i = 0; i < _questions.length; i++) {
      final hasAnswer = _selectedAnswers.containsKey(i);

      if (hasAnswer) {
        final selected = _selectedAnswers[i]!;
        final answers = _questions[i].answers ?? [];
        if (selected >= 0 &&
            selected < answers.length &&
            answers[selected].isCorrect) {
          correct++;
        } else {
          wrong++;
        }
      }
      // Note: Unanswered questions (including critical ones) are not counted as wrong
    }

    // Calculate if passed: correct answers >= minPoint AND no failed critical questions
    final isPassed = correct >= _minPoint && !failedCriticalQuestion;

    // Build QuizResult instance (do this before any UI updates)
    final result = QuizResult(
      quizId: widget.testSetId,
      quizTitle: _testSet?.title ?? widget.testSetId,
      totalQuestions: _questions.length,
      correctAnswers: correct,
      wrongAnswers: wrong,
      attemptDate: DateTime.now(),
      minPoint: _minPoint,
      isPassed: isPassed,
      timeTaken: timeTaken,
      failedCriticalQuestion: failedCriticalQuestion,
      selectedAnswers: QuizLogicService.convertSelectedAnswersForSaving(
        _selectedAnswers,
      ),
    );

    // Persist result regardless of mounted state
    await _saveTestResult(result);

    // Clear saved progress for this quiz
    try {
      await _progressService.clearProgress(widget.testSetId);
    } catch (_) {}

    // If widget still in tree, update UI and navigate to result screen
    if (!mounted) return;

    setState(() {
      _quizResult = result;
      for (int i = 0; i < _questions.length; i++) {
        _checkedQuestions[i] = true;
      }
    });

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => _buildResultScreen()));
  }

  /// Save test result
  Future<void> _saveTestResult(QuizResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const prefix = 'quiz_result_';
      final key = prefix + result.quizId;
      await prefs.setString(key, jsonEncode(result.toJson()));
    } catch (e) {
      debugPrint('Failed to persist quiz result: $e');
    }
  }

  /// Reset quiz
  void _resetQuiz() {
    // Clear persisted progress and saved result (best-effort, do not await)
    try {
      _progressService.clearProgress(widget.testSetId).catchError((_) {});
    } catch (_) {}

    try {
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('quiz_result_${widget.testSetId}');
      }).catchError((_) {});
    } catch (_) {}

    // Reset local state to initial empty quiz
    setState(() {
      _selectedAnswers.clear();
      _checkedQuestions.clear();
      _quizCompleted = false;
      _quizResult = QuizResult(
        quizId: widget.testSetId,
        quizTitle: _testSet?.title ?? widget.testSetId,
        totalQuestions: _questions.length,
        correctAnswers: 0,
        wrongAnswers: 0,
        attemptDate: DateTime.now(),
        minPoint: _minPoint,
      );

      _tabController.index = 0;
      _timerService.reset(_testTime);
      _timerService.start();
    });
  }

  // UI Event handlers
  void _onAnswerSelected(int questionIndex, int optionIndex) {
    final showResult = _checkedQuestions[questionIndex] ?? false;
    if (showResult) return;

    setState(() {
      _selectedAnswers[questionIndex] = optionIndex;
    });
  }

  void _onAnswerChecked(int questionIndex) {
    setState(() {
      _checkedQuestions[questionIndex] = true;
      // _updateQuizResult(questionIndex, _isAnswerCorrect(questionIndex));
    });
  }

  void _navigateToQuestion(int index) {
    _tabController.animateTo(index);
  }

  void _navigatePrevious() {
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
    }
  }

  void _navigateNext() {
    if (_tabController.index < _questions.length - 1) {
      _tabController.animateTo(_tabController.index + 1);
    }
  }

  @override
  void dispose() {
    _timerService.dispose();
    if (!_quizCompleted) {
      _saveProgress();
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_testSet == null || _questions.isEmpty) {
      return _buildErrorScreen();
    }

    if (_quizCompleted) {
      // return _buildResultScreen();
    }

    return _buildQuizScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(QuizConstants.loadingTitle),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScreen() {
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
              QuizConstants.noQuestionsMessage,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(QuizConstants.backButtonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    return QuizResultSummary(
      quizResult: _quizResult,
      questions: _questions,
      selectedAnswers: _selectedAnswers,
      timeTaken: _quizResult.timeTaken ?? Duration.zero,
      onBackPressed: () {
        ref.invalidate(quizResultsProvider);
        Navigator.pop(context, _quizResult); // Return result when going back
      },
      onRetakeQuiz: _resetQuiz,
    );
  }

  Widget _buildQuizScreen() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildQuizBody(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      centerTitle: true,
      backgroundColor: AppStyles.primaryColor,
      leading: Center(
        child: Container(
          margin: const EdgeInsets.only(left: 5.0),
          child: Text(
            '$_answeredCount/${_questions.length}',
            style: const TextStyle(
              fontSize: QuizConstants.counterFontSize,
              color: Colors.white,
            ),
          ),
        ),
      ),
      title: ListenableBuilder(
        listenable: _timerService,
        builder: (context, child) {
          return CountdownTimer(
            duration: Duration(seconds: _timerService.remainingTimeInSeconds),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: QuizConstants.timerFontSize,
            ),
            onTimerComplete: _completeQuiz,
          );
        },
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextButton(
            onPressed: _showConfirmationDialog,
            child: Text(
              QuizConstants.completeButtonText,
              style: AppStyles.textBold.copyWith(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizBody() {
    return Column(
      children: [_buildTabBar(), Expanded(child: _buildTabBarView())],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorWeight: 3,
      indicatorColor: AppStyles.primaryColor,
      labelColor: AppStyles.primaryColor,
      unselectedLabelColor: Colors.grey,
      tabs: List.generate(_questions.length, _buildQuestionTab),
    );
  }

  Widget _buildQuestionTab(int index) {
    final isChecked = _checkedQuestions[index] ?? false;
    final hasSelection = _selectedAnswers.containsKey(index);
    final isCorrect = isChecked ? _isAnswerCorrect(index) : false;

    Color? backgroundColor;
    Color? textColor;

    if (isChecked) {
      backgroundColor = isCorrect
          ? Colors.green.withValues(
              alpha: QuizConstants.correctAnswerOpacity,
            )
          : Colors.red.withValues(alpha: QuizConstants.wrongAnswerOpacity);
      textColor = isCorrect ? Colors.green.shade700 : Colors.red.shade700;
    } else if (hasSelection) {
      backgroundColor = Colors.blue.withValues(
        alpha: QuizConstants.selectedAnswerOpacity,
      );
      textColor = Colors.blue.shade700;
    }

    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${QuizConstants.questionTabPrefix}${index + 1}',
          style: TextStyle(
            color: textColor,
            fontWeight: hasSelection ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: List.generate(
        _questions.length,
        (index) => QuestionViewWidget(
          questionIndex: index,
          question: _questions[index],
          selectedAnswers: _selectedAnswers,
          checkedQuestions: _checkedQuestions,
          onAnswerSelected: _onAnswerSelected,
          isAnswerCorrect: _isAnswerCorrect,
          isQuiz: true,
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        QuizNavigationWidget(
          canGoPrevious: _tabController.index > 0,
          canGoNext: _tabController.index < _questions.length - 1,
          onPrevious: _navigatePrevious,
          onNext: _navigateNext,
          onShowQuestionIndex: () => _showQuestionIndex(context),
        ),
        if (_shouldShowCheckButton())
          CheckAnswerButtonWidget(
            onPressed: () => _onAnswerChecked(_tabController.index),
          ),
      ],
    );
  }

  bool _shouldShowCheckButton() {
    final currentIndex = _tabController.index;
    return _selectedAnswers.containsKey(currentIndex) &&
        !(_checkedQuestions[currentIndex] ?? false);
  }

  Future<void> _showQuestionIndex(BuildContext context) {
    return showModalBottomSheet(
      enableDrag: true,
      showDragHandle: true,
      context: context,
      builder: (context) => QuestionIndexModalWidget(
        totalQuestions: _questions.length,
        currentQuestionIndex: _tabController.index,
        checkedQuestions: _checkedQuestions,
        selectedAnswers: _selectedAnswers,
        onQuestionTap: _navigateToQuestion,
        isAnswerCorrect: _isAnswerCorrect,
        isQuiz: true,
      ),
    );
  }
}
