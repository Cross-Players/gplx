import 'package:flutter/material.dart';

class TestQuestionScreen extends StatefulWidget {
  const TestQuestionScreen({super.key});

  @override
  State<TestQuestionScreen> createState() => _TestQuestionScreenState();
}

class _TestQuestionScreenState extends State<TestQuestionScreen> {
  int? selectedAnswer;
  bool isAnswered = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('32/36'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share question
            },
          ),
          IconButton(
            icon: const Icon(Icons.grade_outlined),
            onPressed: () {
              // Mark question
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CÂU HỎI 32:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Các xe đi như thế nào là đúng quy tắc giao thông?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/question_32.png',
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  _buildAnswerOption(
                    index: 1,
                    text:
                        'Các xe ở phía tay phải và tay trái của người điều khiển được phép đi thẳng.',
                    isCorrect: true,
                  ),
                  _buildAnswerOption(
                    index: 2,
                    text: 'Cho phép các xe ở mọi hướng được rẽ phải.',
                    isCorrect: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Previous question
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
                child: const Text('Câu trước'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Next question
                },
                child: const Text('Câu sau'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOption({
    required int index,
    required String text,
    required bool isCorrect,
  }) {
    final isSelected = selectedAnswer == index;
    final showResult = isAnswered;

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

    return InkWell(
      onTap: isAnswered
          ? null
          : () {
              setState(() {
                selectedAnswer = index;
                isAnswered = true;
              });
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
