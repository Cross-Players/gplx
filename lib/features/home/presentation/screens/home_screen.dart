import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        // title: Text('Hạng ${selectedCategory.name} - GPLX 2025'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildFeatureButton(
            context,
            icon: Icons.shuffle,
            label: 'Đề ngẫu nhiên',
            color: Colors.orange,
            onTap: () {},
          ),
          _buildFeatureButton(
            context,
            icon: Icons.assignment,
            label: 'Thi theo bộ đề',
            color: Colors.red,
            onTap: () => Navigator.pushNamed(context, '/test-sets'),
          ),
          _buildFeatureButton(
            context,
            icon: Icons.person_outline,
            label: 'Xem câu bị sai',
            color: Colors.green,
            onTap: () {},
          ),
          _buildFeatureButton(
            context,
            icon: Icons.book,
            label: 'Ôn tập câu hỏi',
            color: Colors.teal,
            onTap: () {},
          ),
          _buildFeatureButton(
            context,
            icon: Icons.traffic,
            label: 'Các biển báo',
            color: Colors.blue,
            onTap: () => Navigator.pushNamed(context, '/signs'),
          ),
          _buildFeatureButton(
            context,
            icon: Icons.extension,
            label: 'Mẹo ghi nhớ',
            color: Colors.purple,
            onTap: () {},
          ),
          _buildFeatureButton(
            context,
            icon: Icons.timer,
            label: 'Thi sa hình',
            color: Colors.brown,
            onTap: () {},
          ),
          _buildFeatureButton(
            context,
            icon: Icons.star,
            label: 'Top 50 câu sai',
            color: Colors.blueGrey,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
