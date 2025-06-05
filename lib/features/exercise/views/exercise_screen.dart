import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/widgets/base64_image_widget.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test/providers/quiz_providers.dart';
import 'package:gplx/features/test_sets/models/test_set.dart';
import 'package:gplx/features/test_sets/providers/answered_questions_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseScreen extends ConsumerStatefulWidget {
  final String? testSetId;
  final String? title;
  final List<Question>? questions;

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
    if (_isLoading && _questionsLoaded) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.questions != null) {
        _questions = widget.questions!;
        _tabController.dispose();
        _tabController = TabController(length: _questions.length, vsync: this);
        _tabController.addListener(() {
          if (_tabController.indexIsChanging) {
            setState(() {
              selectedAnswer = _selectedAnswers[_tabController.index];
            });
          }
        });
        _isLoading = false;
        _questionsLoaded = true;
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
      print('Error saving quiz progress: $e');
    }
  }

  // Clear saved progress
  Future<void> _clearSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('quiz_progress_${widget.testSetId}');
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
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
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
                  color: Colors.black.withValues(alpha: 0.1),
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
        });

        // Save progress after checking an answer
        _saveProgress();
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
                    ), // Add rounded corners
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

              // Save progress to update the count in provider and SharedPreferences
              _saveProgress();
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
