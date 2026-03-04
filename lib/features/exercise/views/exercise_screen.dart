// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/widgets/gradient_app_bar.dart';
import 'package:gplx/features/exercise/controllers/deadpoint_questions_provider.dart';
import 'package:gplx/features/exercise/providers/chapter_progress_provider.dart';
import 'package:gplx/features/test/controllers/questions_repository.dart';
import 'package:gplx/features/test/models/license_data.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test/models/vehicle.dart';
import 'package:gplx/features/test/views/components/question_view_widget.dart';
import 'package:gplx/features/test/views/components/quiz_ui_components.dart';
import 'package:gplx/features/test_sets/controllers/test_controller.dart';
import 'package:gplx/features/test_sets/providers/answered_questions_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseScreen extends ConsumerStatefulWidget {
  final String? testSetId;
  final String? title;
  final Future<List<Question>>? questions;

  const ExerciseScreen({
    this.testSetId,
    this.questions,
    required this.title,
    super.key,
  });

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
  // New maps for ID-based storage
  final Map<String, int> _selectedAnswersByQuestionId = {};
  final Map<String, bool> _checkedQuestionsByQuestionId = {};
  int currentIndex = 0;
  int? selectedAnswer;
  bool _questionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Load progress first
      ref.read(answeredQuestionsProgressProvider.notifier).loadProgress();

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

        // Sort questions by question number in ascending order
        _questions.sort((a, b) {
          final aNumber = a.number ?? 0;
          final bNumber = b.number ?? 0;
          return aNumber.compareTo(bNumber);
        });

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

        // Load existing progress for current questions
        await _loadSavedProgress();
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
      print('Error loading search questions: $e');
    }
  }

  Future<void> _loadTestSetAndQuestions() async {
    if (_isLoading && _questionsLoaded) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if this is a dead point questions quiz
      if (widget.testSetId != null &&
          widget.testSetId!.startsWith('deadpoints-')) {
        await _loadDeadPointQuestions();
        return;
      }
      // Parse testSetId, ví dụ: '01-A1' hoặc '01-A'
      final parts = (widget.testSetId ?? '').split('-');
      int testNumber = 1;
      String vehicleStr = '';
      if (parts.isNotEmpty) {
        testNumber = int.tryParse(parts[0].replaceAll(RegExp(r'^0+'), '')) ?? 1;
      }
      if (parts.length > 1) {
        vehicleStr = parts.sublist(1).join('-');
      }
      LicenseType licenseType;
      try {
        licenseType = LicenseType.values.firstWhere(
          (e) => e.name == vehicleStr,
        );
      } catch (_) {
        licenseType = LicenseType.A1;
      }
      final controller = TestController();
      final questions = await controller.fetchQuestionsByTestSets(
        licenseType,
        testNumber,
      );
      if (!mounted) return;

      // Sort questions by question number in ascending order
      questions.sort((a, b) {
        final aNumber = a.number ?? 0;
        final bNumber = b.number ?? 0;
        return aNumber.compareTo(bNumber);
      });

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
      print('Error loading Test set and questions: $e');
    }
  }

  /// Load dead point questions for the selected license type
  Future<void> _loadDeadPointQuestions() async {
    try {
      // Extract license type from testSetId (format: 'deadpoints-A1')
      final parts = (widget.testSetId ?? '').split('-');
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

      // Load dead point questions from local assets via provider
      final questions = await ref.read(
        deadpointQuestionsForLicenseProvider(licenseType).future,
      );

      if (questions.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

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
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          setState(() {
            selectedAnswer = _selectedAnswers[_tabController.index];
          });
        }
      });

      // Load saved progress
      await _loadSavedProgress();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _questionsLoaded = true;
        });
      }
    } catch (e) {
      print('Lỗi khi tải câu hỏi điểm liệt: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // First load from ID-based storage (persistent across sessions)
      await _loadProgressByQuestionId();

      // Then load session-specific progress
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
                widget.testSetId ?? '',
                _selectedAnswers.length,
              );
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

      // Sync from ID-based maps to index-based maps for current session
      _syncFromIdBasedMaps();
    } catch (e) {
      print('Error loading saved quiz progress: $e');
    }
  }

  // Load progress by question ID from persistent storage
  Future<void> _loadProgressByQuestionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load selected answers by question ID
      final selectedAnswersJson = prefs.getString('selected_answers_by_id');
      if (selectedAnswersJson != null) {
        final Map<String, dynamic> decodedMap = jsonDecode(selectedAnswersJson);
        _selectedAnswersByQuestionId.clear();
        decodedMap.forEach((key, value) {
          _selectedAnswersByQuestionId[key] = value as int;
        });
      }

      // Load checked questions by question ID
      final checkedQuestionsJson = prefs.getString('checked_questions_by_id');
      if (checkedQuestionsJson != null) {
        final Map<String, dynamic> decodedMap = jsonDecode(
          checkedQuestionsJson,
        );
        _checkedQuestionsByQuestionId.clear();
        decodedMap.forEach((key, value) {
          _checkedQuestionsByQuestionId[key] = value as bool;
        });
      }
    } catch (e) {
      print('Error loading progress by question ID: $e');
    }
  }

  // Save progress to SharedPreferences
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Sync current answers to ID-based maps
      _syncToIdBasedMaps();

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

      // Also save by question ID for persistent cross-session storage
      await _saveProgressByQuestionId();

      // Update the answeredQuestionsProvider with the current count
      ref
          .read(answeredQuestionsProvider.notifier)
          .updateAnsweredCount(widget.testSetId ?? '', _selectedAnswers.length);

      // Update chapter progress as well
      await _updateChapterProgress();
    } catch (e) {
      print('Error saving quiz progress: $e');
    }
  }

  // Save progress by question ID for persistent storage
  Future<void> _saveProgressByQuestionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save selected answers by question ID
      final selectedAnswersJson = jsonEncode(_selectedAnswersByQuestionId);
      await prefs.setString('selected_answers_by_id', selectedAnswersJson);

      // Save checked questions by question ID
      final checkedQuestionsJson = jsonEncode(_checkedQuestionsByQuestionId);
      await prefs.setString('checked_questions_by_id', checkedQuestionsJson);
    } catch (e) {
      print('Error saving progress by question ID: $e');
    }
  }

  // Update chapter progress based on answered questions
  Future<void> _updateChapterProgress() async {
    try {
      final questionNumberToChapter = <int, String>{};

      // Map answered questions to their chapters using question numbers
      for (final entry in _selectedAnswers.entries) {
        final questionIndex = entry.key;
        if (questionIndex < _questions.length) {
          final question = _questions[questionIndex];
          final chapter = question.chapter;
          final questionNumber = question.number;

          if (chapter != null && chapter.isNotEmpty && questionNumber != null) {
            questionNumberToChapter[questionNumber] = chapter;
          }
        }
      }

      // Record answered questions for progress tracking
      if (questionNumberToChapter.isNotEmpty) {
        await ref
            .read(answeredQuestionsProgressProvider.notifier)
            .recordAnsweredQuestions(questionNumberToChapter);
      }
    } catch (e) {
      print('Error updating chapter progress: $e');
    }
  }

  // Clear saved progress
  Future<void> _clearSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear index-based storage (session-specific)
      await prefs.remove('quiz_progress_${widget.testSetId}');

      // Clear ID-based storage (persistent across sessions)
      await prefs.remove('selected_answers_by_id');
      await prefs.remove('checked_questions_by_id');
    } catch (e) {
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
      // Also clear the ID-based maps
      _selectedAnswersByQuestionId.clear();
      _checkedQuestionsByQuestionId.clear();
    });

    // Clear saved progress (both index-based and ID-based)
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

  // Generate unique ID for question: LicenseType-Chapter-QuestionNumber
  String _generateQuestionId(Question question) {
    final licenseType = ref.read(licenseTypeProvider);
    final chapter = question.chapter ?? 'Unknown';
    final questionNumber = question.number ?? 0;
    return '${licenseType.name}-$chapter-$questionNumber';
  }

  // Sync data from index-based maps to ID-based maps
  void _syncToIdBasedMaps() {
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final questionId = _generateQuestionId(question);

      if (_selectedAnswers.containsKey(i)) {
        _selectedAnswersByQuestionId[questionId] = _selectedAnswers[i]!;
      }

      if (_checkedQuestions.containsKey(i)) {
        _checkedQuestionsByQuestionId[questionId] = _checkedQuestions[i]!;
      }
    }
  }

  // Sync data from ID-based maps to index-based maps
  void _syncFromIdBasedMaps() {
    _selectedAnswers.clear();
    _checkedQuestions.clear();

    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final questionId = _generateQuestionId(question);

      if (_selectedAnswersByQuestionId.containsKey(questionId)) {
        _selectedAnswers[i] = _selectedAnswersByQuestionId[questionId]!;
      }

      if (_checkedQuestionsByQuestionId.containsKey(questionId)) {
        _checkedQuestions[i] = _checkedQuestionsByQuestionId[questionId]!;
      }
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

    if (question.answers == null ||
        selectedAnswerIndex >= question.answers!.length) {
      return false;
    }

    return question.answers![selectedAnswerIndex].isCorrect;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: GradientAppBar(
          title: Text('Đang tải bài quiz ...'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: const GradientAppBar(
          title: Text('Quiz'),
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
      appBar: GradientAppBar(
        title: widget.title != null
            ? Text(
                widget.title!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppStyles.fontSizeH,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : const Text('Ôn tập GPLX'),
        actions: [
          IconButton(
            onPressed: () => _showClearConfirmationDialog(context),
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới kết quả',
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorWeight: 3,
            indicatorColor: AppStyles.primaryGradientEnd,
            labelColor: AppStyles.primaryGradientEnd,
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
        question.number!,
        vehicleType,
      );
    } else {
      // Remove from correct questions if answered incorrectly (add back to wrong list)
      await questionRepository.removeCorrectQuestion(
        question.number!,
        vehicleType,
      );
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
