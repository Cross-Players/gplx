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
  // Core quiz data
  List<Question> _questions = [];
  TestSet? _testSet;
  late QuizResult _quizResult;

  // Quiz state
  bool _isLoading = true;
  bool _quizCompleted = false;
  bool _questionsLoaded = false;

  // Timer related
  late int _remainingTimeInSeconds;
  Timer? _timer;
  DateTime? _startTime;

  // Navigation
  late TabController _tabController;

  // User answers
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
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadTestSetAndQuestions();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeQuizResult();
  }

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
    _remainingTimeInSeconds = _testTime * 60;
  }

  // Loading and initialization methods
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
      _startQuiz();
    } catch (e) {
      _handleError('Error loading Test set and questions: $e');
    }
  }

  Future<void> _loadTestSet() async {
    _testSet = await ref.read(testSetProvider(widget.testSetId).future);
    if (_testSet != null) {
      _quizResult = _quizResult.copyWith(quizTitle: _testSet!.title);
    }
  }

  Future<void> _loadQuestions() async {
    _questions = await ref.read(
      quizQuestionsProvider(widget.testSetId).future,
    );
  }

  void _setupQuizController() {
    if (!mounted) return;

    _remainingTimeInSeconds = _testTime * 60;
    _startTime = DateTime.now();

    _tabController.dispose();
    _tabController = TabController(length: _questions.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _startQuiz() {
    setState(() {
      _isLoading = false;
      _questionsLoaded = true;
    });
    _startTimer();
    _loadSavedProgress();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        // Update any UI that depends on current tab
      });
    }
  }

  void _setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  void _handleError(String message) {
    print(message);
    _setLoadingState(false);
  }

  // Timer methods
  void _startTimer() {
    _timer?.cancel();
    _startTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

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

  // Progress saving and loading
  Future<void> _loadSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedQuizJson =
          prefs.getString('quiz_progress_${widget.testSetId}');

      if (savedQuizJson != null) {
        final savedData = jsonDecode(savedQuizJson) as Map<String, dynamic>;
        _restoreFromSavedData(savedData);
      }
    } catch (e) {
      print('Error loading saved quiz progress: $e');
    }
  }

  void _restoreFromSavedData(Map<String, dynamic> savedData) {
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
      _quizResult = _parseQuizResultFromSaved(savedData['quizResult']);
    }
  }

  QuizResult _parseQuizResultFromSaved(Map<String, dynamic> quizResultMap) {
    return QuizResult(
      quizId: quizResultMap['quizId'] as String,
      quizTitle: quizResultMap['quizTitle'] as String,
      totalQuestions: quizResultMap['totalQuestions'] as int,
      correctAnswers: quizResultMap['correctAnswers'] as int,
      wrongAnswers: quizResultMap['wrongAnswers'] as int,
      attemptDate: DateTime.parse(quizResultMap['attemptDate'] as String),
      failedCriticalQuestion: quizResultMap['failedCriticalQuestion'] as bool?,
      timeTaken: quizResultMap['timeTaken'] != null
          ? Duration(seconds: quizResultMap['timeTaken'] as int)
          : null,
      minPoint: quizResultMap['minPoint'] as int? ?? 0,
      isPassed: quizResultMap['isPassed'] as bool?,
      selectedAnswers: quizResultMap['selectedAnswers'] != null
          ? Map<String, int>.from(quizResultMap['selectedAnswers'] as Map)
          : null,
    );
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = _createSaveData();

      await prefs.setString(
        'quiz_progress_${widget.testSetId}',
        jsonEncode(savedData),
      );
    } catch (e) {
      print('Error saving quiz progress: $e');
    }
  }

  Map<String, dynamic> _createSaveData() {
    final selectedAnswersMap = <String, int>{};
    _selectedAnswers.forEach((key, value) {
      selectedAnswersMap[key.toString()] = value;
    });

    final checkedQuestionsMap = <String, bool>{};
    _checkedQuestions.forEach((key, value) {
      checkedQuestionsMap[key.toString()] = value;
    });

    return {
      'selectedAnswers': selectedAnswersMap,
      'checkedQuestions': checkedQuestionsMap,
      'quizResult': _quizResult.toJson(),
      'lastSaved': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _clearSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('quiz_progress_${widget.testSetId}');
    } catch (e) {
      print('Error clearing saved quiz progress: $e');
    }
  }

  // Quiz logic methods
  bool _isAnswerCorrect(int questionIndex) {
    if (!_selectedAnswers.containsKey(questionIndex)) return false;

    final selectedAnswerIndex = _selectedAnswers[questionIndex]!;
    final question = _questions[questionIndex];

    if (selectedAnswerIndex >= question.answers.length) return false;

    return question.answers[selectedAnswerIndex].isCorrect;
  }

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

  void _completeQuiz() {
    final timeTaken = _calculateTimeTaken();
    final failedCriticalQuestion = _checkCriticalQuestions();

    _processUnprocessedAnswers();

    setState(() {
      _quizResult = _quizResult.copyWith(
        timeTaken: timeTaken,
        attemptDate: DateTime.now(),
        failedCriticalQuestion: failedCriticalQuestion,
        totalQuestions: _questions.length,
      );

      _quizCompleted = true;
      _timer?.cancel();
    });

    _saveTestResult();
    _clearSavedProgress();
  }

  Duration _calculateTimeTaken() {
    if (_startTime != null) {
      int totalSeconds = _testTime * 60;
      int elapsedSeconds = totalSeconds - _remainingTimeInSeconds;
      return Duration(seconds: elapsedSeconds);
    }
    return Duration.zero;
  }

  bool _checkCriticalQuestions() {
    // Check answered critical questions
    for (final entry in _selectedAnswers.entries) {
      final questionIndex = entry.key;
      final question = _questions[questionIndex];

      if ((question.isDeadPoint ?? false) && !_isAnswerCorrect(questionIndex)) {
        return true;
      }
    }

    // Check unanswered critical questions
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final isCritical = question.isDeadPoint ?? false;
      final isAnswered = _selectedAnswers.containsKey(i);

      if (isCritical && !isAnswered) {
        return true;
      }
    }

    return false;
  }

  void _processUnprocessedAnswers() {
    _selectedAnswers.forEach((questionIndex, selectedAnswerIndex) {
      if (!(_checkedQuestions[questionIndex] ?? false)) {
        _checkedQuestions[questionIndex] = true;
        final isCorrect = _isAnswerCorrect(questionIndex);

        _quizResult = _quizResult.copyWith(
          correctAnswers: isCorrect
              ? _quizResult.correctAnswers + 1
              : _quizResult.correctAnswers,
          wrongAnswers: !isCorrect
              ? _quizResult.wrongAnswers + 1
              : _quizResult.wrongAnswers,
        );
      }
    });
  }

  Future<void> _saveTestResult() async {
    try {
      final percentCorrect = _calculatePercentCorrect();
      final isPassed = _determinePassStatus(percentCorrect);
      final selectedAnswersForSaving = _convertSelectedAnswersForSaving();

      final updatedQuizResult = _quizResult.copyWith(
        attemptDate: DateTime.now(),
        isPassed: isPassed,
        selectedAnswers: selectedAnswersForSaving,
      );

      await ref
          .read(quizResultsNotifierProvider.notifier)
          .addResult(updatedQuizResult);
    } catch (e) {
      print('Error saving test result: $e');
    }
  }

  double _calculatePercentCorrect() {
    return _quizResult.totalQuestions > 0
        ? (_quizResult.correctAnswers / _quizResult.totalQuestions) * 100
        : 0.0;
  }

  bool _determinePassStatus(double percentCorrect) {
    final passedCriticalQuestions = _quizResult.failedCriticalQuestion != true;
    final passedScoreThreshold = percentCorrect >= 84;
    return passedCriticalQuestions && passedScoreThreshold;
  }

  Map<String, int> _convertSelectedAnswersForSaving() {
    final selectedAnswersForSaving = <String, int>{};
    _selectedAnswers.forEach((key, value) {
      selectedAnswersForSaving[key.toString()] = value;
    });
    return selectedAnswersForSaving;
  }

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

      _startTime = DateTime.now();
      _remainingTimeInSeconds = _testTime * 60;
      _tabController.index = 0;
      _startTimer();
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
    _timer?.cancel();
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
        title: const Text('Đang tải bài quiz ...'),
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
              'Không có câu hỏi nào cho bài quiz này',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Quay lại'),
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
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
      title: CountdownTimer(
        duration: Duration(seconds: _remainingTimeInSeconds),
        textStyle: const TextStyle(color: Colors.white, fontSize: 20),
        onTimerComplete: _completeQuiz,
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
          ? Colors.green.withValues(alpha: 0.2)
          : Colors.red.withValues(alpha: 0.2);
      textColor = isCorrect ? Colors.green.shade700 : Colors.red.shade700;
    } else if (hasSelection) {
      backgroundColor = Colors.blue.withValues(alpha: 0.2);
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
          'Câu ${index + 1}',
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
      children: List.generate(_questions.length, _buildQuestionView),
    );
  }

  Widget _buildQuestionView(int questionIndex) {
    final question = _questions[questionIndex];
    final isChecked = _checkedQuestions[questionIndex] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionHeader(questionIndex, question),
          const SizedBox(height: 16),
          if (question.imageUrl?.isNotEmpty == true)
            _buildQuestionImage(question.imageUrl!),
          Expanded(
            child: ListView(
              children: [
                ..._buildAnswerOptions(questionIndex, question),
                const SizedBox(height: 20),
                if (isChecked) _buildAnswerFeedback(questionIndex, question),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(int questionIndex, Question question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CÂU HỎI ${questionIndex + 1}:',
          style: AppStyles.textBold.copyWith(fontSize: AppStyles.fontSizeH),
        ),
        const SizedBox(height: 8),
        Text(
          question.content,
          style: AppStyles.textBold.copyWith(fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildQuestionImage(String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 150,
      width: double.infinity,
      child: Base64ImageWidget(base64String: imageUrl),
    );
  }

  List<Widget> _buildAnswerOptions(int questionIndex, Question question) {
    return List.generate(
      question.answers.length,
      (index) => _buildAnswerOption(
        questionIndex: questionIndex,
        optionIndex: index,
        text: question.answers[index].answerContent,
        isCorrect: question.answers[index].isCorrect,
      ),
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

    return GestureDetector(
      onTap: () => _onAnswerSelected(questionIndex, optionIndex),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _getAnswerBackgroundColor(showResult, isSelected, isCorrect),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnswerIcon(showResult, isSelected, isCorrect),
            const SizedBox(width: 12),
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

  Color? _getAnswerBackgroundColor(
      bool showResult, bool isSelected, bool isCorrect) {
    if (showResult) {
      if (isCorrect) return Colors.green[50];
      if (isSelected && !isCorrect) return Colors.red[50];
    } else if (isSelected) {
      return Colors.blue[50];
    }
    return null;
  }

  Widget _buildAnswerIcon(bool showResult, bool isSelected, bool isCorrect) {
    return Container(
      width: 24,
      height: 24,
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
    );
  }

  Widget _buildAnswerFeedback(int questionIndex, Question question) {
    final isCorrect = _isAnswerCorrect(questionIndex);
    final correctAnswer = question.answers.firstWhere(
      (a) => a.isCorrect,
      orElse: () => question.answers.first,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? 'Chính xác!' : 'Sai rồi!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green : Colors.red,
            ),
          ),
          Text(
            'Đáp án đúng: ${correctAnswer.answerContent}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (question.explanation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Giải thích: ${question.explanation}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        _buildNavigationBar(),
        if (_shouldShowCheckButton()) _buildCheckAnswerButton(),
      ],
    );
  }

  Widget _buildNavigationBar() {
    return Container(
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
                onPressed: _tabController.index > 0 ? _navigatePrevious : null,
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              IconButton(
                onPressed: () => _showQuestionIndex(context),
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
                ? _navigateNext
                : null,
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ),
        ],
      ),
    );
  }

  bool _shouldShowCheckButton() {
    final currentIndex = _tabController.index;
    return _selectedAnswers.containsKey(currentIndex) &&
        !(_checkedQuestions[currentIndex] ?? false);
  }

  Widget _buildCheckAnswerButton() {
    return Transform.translate(
      offset: const Offset(0, -25),
      child: GestureDetector(
        onTap: () => _onAnswerChecked(_tabController.index),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
            color: Colors.green,
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Icon(Icons.check, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _showQuestionIndex(BuildContext context) {
    return showModalBottomSheet(
      enableDrag: true,
      showDragHandle: true,
      context: context,
      builder: (context) => _buildQuestionIndexModal(),
    );
  }

  Widget _buildQuestionIndexModal() {
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
        itemBuilder: _buildQuestionIndexItem,
      ),
    );
  }

  Widget _buildQuestionIndexItem(BuildContext context, int index) {
    final isCurrentQuestion = _tabController.index == index;
    final isChecked = _checkedQuestions[index] ?? false;
    final isCorrect = isChecked ? _isAnswerCorrect(index) : false;

    Color backgroundColor = Colors.lightBlue[100]!;
    Color textColor = Colors.black;

    if (isChecked) {
      backgroundColor = isCorrect ? Colors.green[200]! : Colors.red[200]!;
    }

    if (isCurrentQuestion) {
      backgroundColor = Colors.blue[300]!;
      textColor = Colors.white;
    }

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _navigateToQuestion(index);
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
