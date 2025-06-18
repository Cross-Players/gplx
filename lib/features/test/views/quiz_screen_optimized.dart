import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/widgets/countdown_timer.dart';
import 'package:gplx/features/test/constants/quiz_constants.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test/models/quiz_result.dart';
import 'package:gplx/features/test/providers/quiz_providers.dart';
import 'package:gplx/features/test/providers/quiz_results_provider.dart';
import 'package:gplx/features/test/providers/vehicle_provider.dart';
import 'package:gplx/features/test/services/quiz_logic_service.dart';
import 'package:gplx/features/test/services/quiz_progress_service.dart';
import 'package:gplx/features/test/services/quiz_timer_service.dart';
import 'package:gplx/features/test/views/quiz_result_summary.dart';
import 'package:gplx/features/test/views/components/question_view_widget.dart';
import 'package:gplx/features/test/views/components/quiz_ui_components.dart';
import 'package:gplx/features/test_sets/models/test_set.dart';

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
  List<Question> _questions = [];
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
    _initializeServices();
    _tabController = TabController(length: 0, vsync: this);
    SchedulerBinding.instance
        .addPostFrameCallback((_) => _loadTestSetAndQuestions());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeQuizResult();
  }

  /// Initialize services
  void _initializeServices() {
    _timerService = QuizTimerService();
    _progressService = QuizProgressService.instance;
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

  /// Load test set and questions
  Future<void> _loadTestSetAndQuestions() async {
    if (_isLoading && _questionsLoaded) return;

    _setLoadingState(true);

    try {
      await _loadTestSet();
      if (_testSet == null) {
        _setLoadingState(false);
        return;
      }

      await _loadQuestions();
      _setupQuizController();
      await _loadSavedProgress();
      _startQuiz();
    } catch (e) {
      _handleError('${QuizConstants.loadingErrorMessage}$e');
    }
  }

  /// Load test set
  Future<void> _loadTestSet() async {
    _testSet = await ref.read(testSetProvider(widget.testSetId).future);
    if (_testSet != null) {
      _quizResult = _quizResult.copyWith(quizTitle: _testSet!.title);
    }
  }

  /// Load questions
  Future<void> _loadQuestions() async {
    _questions = await ref.read(quizQuestionsProvider(widget.testSetId).future);
  }

  /// Setup quiz controller
  void _setupQuizController() {
    if (!mounted) return;

    _tabController.dispose();
    _tabController = TabController(length: _questions.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    _timerService.initialize(_testTime, onComplete: _completeQuiz);
  }

  /// Load saved progress
  Future<void> _loadSavedProgress() async {
    try {
      final savedProgress =
          await _progressService.loadProgress(widget.testSetId);
      if (savedProgress != null) {
        _restoreFromSavedData(savedProgress);
      }
    } catch (e) {
      print('${QuizConstants.loadProgressErrorMessage}$e');
    }
  }

  /// Restore from saved progress data
  void _restoreFromSavedData(QuizProgressData savedProgress) {
    _selectedAnswers.clear();
    _selectedAnswers.addAll(savedProgress.selectedAnswers);

    _checkedQuestions.clear();
    _checkedQuestions.addAll(savedProgress.checkedQuestions);

    if (savedProgress.quizResult != null) {
      _quizResult = savedProgress.quizResult!;
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
      setState(() {
        // Update UI that depends on current tab
      });
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
      print('${QuizConstants.saveProgressErrorMessage}$e');
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

  /// Update quiz result
  void _updateQuizResult(int questionIndex, bool isCorrect) {
    setState(() {
      _quizResult = _quizResult.copyWith(
        correctAnswers: isCorrect
            ? _quizResult.correctAnswers + 1
            : _quizResult.correctAnswers,
        wrongAnswers: !isCorrect
            ? _quizResult.wrongAnswers + 1
            : _quizResult.wrongAnswers,
      );
      _saveProgress();
    });
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

  /// Complete quiz
  void _completeQuiz() {
    final timeTaken = _timerService.getElapsedTime(_testTime);
    final failedCriticalQuestion =
        QuizLogicService.checkCriticalQuestionsFailed(
      questions: _questions,
      selectedAnswers: _selectedAnswers,
    );

    // Process unprocessed answers
    _quizResult = QuizLogicService.processUnprocessedAnswers(
      questions: _questions,
      selectedAnswers: _selectedAnswers,
      checkedQuestions: _checkedQuestions,
      currentResult: _quizResult,
    );

    setState(() {
      _quizResult = _quizResult.copyWith(
        timeTaken: timeTaken,
        attemptDate: DateTime.now(),
        failedCriticalQuestion: failedCriticalQuestion,
        totalQuestions: _questions.length,
      );

      _quizCompleted = true;
      _timerService.stop();
    });

    _saveTestResult();
    _progressService.clearProgress(widget.testSetId);
  }

  /// Save test result
  Future<void> _saveTestResult() async {
    try {
      final percentCorrect = QuizLogicService.calculatePercentage(
        correctAnswers: _quizResult.correctAnswers,
        totalQuestions: _quizResult.totalQuestions,
      );

      final isPassed = QuizLogicService.determinePassStatus(
        percentCorrect: percentCorrect,
        failedCriticalQuestion: _quizResult.failedCriticalQuestion ?? false,
      );

      final selectedAnswersForSaving =
          QuizLogicService.convertSelectedAnswersForSaving(_selectedAnswers);

      final updatedQuizResult = _quizResult.copyWith(
        attemptDate: DateTime.now(),
        isPassed: isPassed,
        selectedAnswers: selectedAnswersForSaving,
      );

      await ref
          .read(quizResultsNotifierProvider.notifier)
          .addResult(updatedQuizResult);
    } catch (e) {
      print('${QuizConstants.saveResultErrorMessage}$e');
    }
  }

  /// Reset quiz
  void _resetQuiz() {
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
      _updateQuizResult(questionIndex, _isAnswerCorrect(questionIndex));
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
      return _buildResultScreen();
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
        ref.refresh(quizResultsProvider);
        Navigator.pop(context);
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
      children: [
        _buildTabBar(),
        Expanded(child: _buildTabBarView()),
      ],
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
          ? Colors.green.withOpacity(QuizConstants.correctAnswerOpacity)
          : Colors.red.withOpacity(QuizConstants.wrongAnswerOpacity);
      textColor = isCorrect ? Colors.green.shade700 : Colors.red.shade700;
    } else if (hasSelection) {
      backgroundColor =
          Colors.blue.withOpacity(QuizConstants.selectedAnswerOpacity);
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
