import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/features/test/controllers/questions_repository.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test/providers/quiz_providers.dart';
import 'package:gplx/features/test/providers/vehicle_provider.dart';
import 'package:gplx/features/test/views/components/question_view_widget.dart';
import 'package:gplx/features/test/views/components/quiz_ui_components.dart';
import 'package:gplx/features/test_sets/models/test_set.dart';
import 'package:gplx/features/test_sets/providers/answered_questions_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseScreen extends ConsumerStatefulWidget {
  final String? testSetId;
  final String? title;
  final Future<List<Question>>? questions;

  const ExerciseScreen(
      {this.testSetId, this.questions, required this.title, super.key});

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen>
    with TickerProviderStateMixin {
  List<Question> _questions = [];
  bool _isLoading = true;
  late TabController _tabController;
  final Map<int, int> _selectedAnswers = {};
  final Map<int, bool> _checkedQuestions = {};
  TestSet? _testSet;
  int currentIndex = 0;
  int? selectedAnswer;
  bool _questionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.questions != null
          ? _loadSearchQuestions()
          : _loadTestSetAndQuestions();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadSearchQuestions() async {
    if (_questionsLoaded) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.questions != null) {
        _questions = await widget.questions!;
        if (!mounted) return;

        _tabController.dispose();
        _tabController = TabController(length: _questions.length, vsync: this);
        _tabController.addListener(() {
          if (_tabController.indexIsChanging) {
            setState(() {
              selectedAnswer = _selectedAnswers[_tabController.index];
            });
          }
        });

        setState(() {
          _isLoading = false;
          _questionsLoaded = true;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      // ignore: avoid_print
      print('Error loading search questions: $e');
    }
  }

  Future<void> _loadTestSetAndQuestions() async {
    if (_isLoading && _questionsLoaded) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _testSet = await ref.read(testSetProvider(widget.testSetId ?? '').future);

      if (_testSet == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final questions = await ref.read(
        quizQuestionsProvider(widget.testSetId ?? '').future,
      );

      if (!mounted) return;

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
        _loadSavedProgress();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      // ignore: avoid_print
      print('Error loading Test set and questions: $e');
    }
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
          ref.read(answeredQuestionsProvider.notifier).updateAnsweredCount(
              widget.testSetId ?? '', _selectedAnswers.length);
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
          // Get the quiz result map for reference (unused for now)
          final _ = savedData['quizResult'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading saved quiz progress: $e');
    }
  }

  // Save progress to SharedPreferences
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
        'lastSaved': DateTime.now().toIso8601String(),
      };

      await prefs.setString(
        'quiz_progress_${widget.testSetId}',
        jsonEncode(savedData),
      );

      // Update the answeredQuestionsProvider with the current count
      ref
          .read(answeredQuestionsProvider.notifier)
          .updateAnsweredCount(widget.testSetId ?? '', _selectedAnswers.length);
    } catch (e) {
      // ignore: avoid_print
      print('Error saving quiz progress: $e');
    }
  }

  // Clear saved progress
  Future<void> _clearSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('quiz_progress_${widget.testSetId}');
    } catch (e) {
      // ignore: avoid_print
      print('Error clearing saved quiz progress: $e');
    }
  }

  // Show confirmation dialog before clearing results
  void _showClearConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa kết quả?'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả kết quả đã làm cho bài ôn tập này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HỦY'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearResults();
            },
            child: const Text('XÓA', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Clear all results and reset the exercise
  Future<void> _clearResults() async {
    setState(() {
      _selectedAnswers.clear();
      _checkedQuestions.clear();
    });

    // Clear saved progress
    await _clearSavedProgress();

    // Clear the answered questions in the provider
    ref
        .read(answeredQuestionsProvider.notifier)
        .clearAnswersForTestSet(widget.testSetId ?? '');

    // Show a confirmation message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa tất cả kết quả!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
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

    if (_questions.isEmpty) {
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

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        primary: true,
        backgroundColor: AppStyles.primaryColor,
        title: widget.title != null
            ? Text(
                widget.title!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: AppStyles.fontSizeH,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              )
            : const Text('Ôn tập GPLX'),
        actions: [
          IconButton(
            onPressed: () => _showClearConfirmationDialog(context),
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới kết quả',
          )
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
                backgroundColor = Colors.blue.withValues(alpha: 0.1);
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
                    'Câu ${_questions[index].number}',
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

                return QuestionViewWidget(
                  questionIndex:
                      questionIndex, // Use array index, not question.number
                  question: question,
                  selectedAnswers: _selectedAnswers,
                  checkedQuestions: _checkedQuestions,
                  onAnswerSelected: (qIndex, optionIndex) {
                    setState(() {
                      _selectedAnswers[qIndex] = optionIndex;
                    });
                    _saveProgress();
                  },
                  isAnswerCorrect: _isAnswerCorrect,
                  isQuiz: false,
                );
              }),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Stack(
        alignment: Alignment.topCenter,
        children: [
          QuizNavigationWidget(
            canGoPrevious: _tabController.index > 0,
            canGoNext: _tabController.index < _questions.length - 1,
            onPrevious: () {
              _tabController.animateTo(_tabController.index - 1);
            },
            onNext: () {
              _tabController.animateTo(_tabController.index + 1);
            },
            onShowQuestionIndex: () => _showQuestionIndex(context),
          ),
          if (_selectedAnswers.containsKey(_tabController.index) &&
              !(_checkedQuestions[_tabController.index] ?? false))
            CheckAnswerButtonWidget(
              onPressed: () => _onCheckAnswer(_tabController.index),
            ),
        ],
      ),
    );
  }

  // Method to handle check answer button press
  Future<void> _onCheckAnswer(int questionIndex) async {
    final question = _questions[questionIndex];
    final isCorrect = _isAnswerCorrect(questionIndex);

    // Save question result to repository
    final vehicleType = ref.read(selectedVehicleTypeProvider).vehicleType;
    final questionRepository = QuestionRepository();

    if (isCorrect) {
      // Add to correct questions if answered correctly (remove from wrong list)
      await questionRepository.saveCorrectQuestion(
          question.number, vehicleType);
    } else {
      // Remove from correct questions if answered incorrectly (add back to wrong list)
      await questionRepository.removeCorrectQuestion(
          question.number, vehicleType);
    }

    setState(() {
      _checkedQuestions[questionIndex] = true;
    });

    // Save progress after checking an answer
    _saveProgress();
  }

  // Show question index modal using reusable component
  Future<dynamic> _showQuestionIndex(BuildContext context) {
    return showModalBottomSheet(
      enableDrag: true,
      showDragHandle: true,
      context: context,
      builder: (context) {
        return QuestionIndexModalWidget(
          totalQuestions: _questions.length,
          currentQuestionIndex: _tabController.index,
          checkedQuestions: _checkedQuestions,
          selectedAnswers: _selectedAnswers,
          onQuestionTap: (index) {
            _tabController.animateTo(index);
          },
          isAnswerCorrect: _isAnswerCorrect,
          isQuiz: false,
          questions: _questions, // Pass the questions list
        );
      },
    );
  }
}
