import 'package:flutter/material.dart';

class TestSetsScreen extends StatelessWidget {
  const TestSetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Các đề thi Bằng B2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // Show delete confirmation dialog
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final testNumber = index + 1;
          // Mock data for demonstration
          final correct = index % 2 == 0 ? 35 : 9;
          final wrong = index % 2 == 0 ? 1 : 26;
          final isCompleted = correct + wrong > 0;

          return _TestSetCard(
            testNumber: testNumber,
            correct: correct,
            wrong: wrong,
            isCompleted: isCompleted,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/test',
                arguments: {'testNumber': testNumber},
              );
            },
          );
        },
      ),
    );
  }
}

class _TestSetCard extends StatelessWidget {
  final int testNumber;
  final int correct;
  final int wrong;
  final bool isCompleted;
  final VoidCallback onTap;

  const _TestSetCard({
    required this.testNumber,
    required this.correct,
    required this.wrong,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isCompleted
        ? (wrong > 5 ? Colors.red[100] : Colors.green[100])
        : Colors.grey[200];

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ĐỀ THI SỐ $testNumber',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$correct',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.cancel,
                      color: Colors.red[700],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$wrong',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
