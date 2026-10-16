import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/routes/app_routes.dart';
import 'package:gplx/features/settings/presentation/screens/settings_screen.dart';
import 'package:gplx/features/test/models/license_data.dart';
import 'package:gplx/features/test/views/quiz_screen.dart';
import 'package:gplx/features/test_sets/views/test_sets_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licenseType = ref.watch(licenseTypeProvider);

    Future<void> navigateToRandomTest() async {
      try {
        final currentLicenseType = ref.read(licenseTypeProvider);
        final totalTestSets = numberOfTestSetsBasedOnLicense(
          currentLicenseType,
        );

        if (totalTestSets <= 0) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không có đề thi nào cho hạng xe này.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        final random = Random();
        final randomTestNumber = random.nextInt(totalTestSets) + 1;
        final testSetId = '$randomTestNumber-${currentLicenseType.name}';
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(testSetId: testSetId),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Có lỗi xảy ra: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    void openSettings() => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );

    final features = [
      _FeatureData(
        title: 'Thi theo bộ đề',
        subtitle: 'Đề chính thức',
        icon: Icons.assignment_rounded,
        color: const Color(0xFFE11D48),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TestSetsScreen()),
        ),
      ),
      _FeatureData(
        title: 'Ôn tập câu hỏi',
        subtitle: 'Theo chương',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF0D9488),
        onTap: () => Navigator.pushNamed(context, AppRoutes.allChapters),
      ),
      _FeatureData(
        title: 'Câu điểm liệt',
        subtitle: 'Không được sai',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFD97706),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.deadpointQuestions,
              arguments: {
                'title': 'Câu điểm liệt của hạng ${licenseType.name}',
                'testSetId': 'deadpoints-${licenseType.name}',
              });
        },
      ),
      _FeatureData(
        title: 'Các biển báo',
        subtitle: 'Tra cứu nhanh',
        icon: Icons.traffic_rounded,
        color: const Color(0xFF2563EB),
        onTap: () => Navigator.pushNamed(context, AppRoutes.signs),
      ),
      _FeatureData(
        title: 'Mẹo ghi nhớ',
        subtitle: 'Học nhanh, nhớ lâu',
        icon: Icons.lightbulb_rounded,
        color: const Color(0xFF9333EA),
        onTap: () => Navigator.pushNamed(context, AppRoutes.tips),
      ),
      _FeatureData(
        title: 'Thiết lập',
        subtitle: 'Đổi hạng bằng',
        icon: Icons.tune_rounded,
        color: const Color(0xFF475569),
        onTap: openSettings,
      ),
    ];

    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // Header with the quick start card overlapping its bottom edge
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.zero,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(24, topInset + 20, 24, 64),
                    decoration: const BoxDecoration(
                      gradient: AppPalette.heroGradient,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Positioned(
                          right: -60,
                          top: -40,
                          child: _Glow(size: 180),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.asset(
                                    'assets/images/logo_vx.jpg',
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Ôn thi GPLX',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                _GlassIconButton(
                                  icon: Icons.settings_rounded,
                                  onTap: openSettings,
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'Học lý thuyết\nGiấy phép lái xe',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Hạng ${licenseType.name}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: openSettings,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Đổi',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Icon(Icons.expand_more_rounded,
                                            size: 16, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Pull the card up so it overlaps the header bottom edge.
                Transform.translate(
                  offset: const Offset(0, -56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _QuickStartCard(onTap: navigateToRandomTest),
                  ),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 14),
              child: Text(
                'Luyện tập',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.ink,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),

          // Features grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.15,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _FeatureCard(feature: features[index]),
                childCount: features.length,
              ),
            ),
          ),

          // Tip card
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(18),
              margin: EdgeInsets.fromLTRB(
                  20, 20, 20, 24 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: AppPalette.warningSoft,
                borderRadius: BorderRadius.circular(AppPalette.radiusM),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mẹo học tập',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hãy ôn tập các câu điểm liệt trước khi thi để đạt kết quả tốt nhất!',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppPalette.ink.withValues(alpha: 0.7),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _FeatureData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _Glow extends StatelessWidget {
  final double size;

  const _Glow({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _QuickStartCard extends StatelessWidget {
  final VoidCallback onTap;

  const _QuickStartCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(AppPalette.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppPalette.primaryDeep.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9F43), Color(0xFFFF6B3D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child:
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thi thử ngẫu nhiên',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.ink,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Bốc một đề bất kỳ và bấm giờ như thi thật',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppPalette.inkMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppPalette.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: feature.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(AppPalette.radiusL),
          border: Border.all(color: AppPalette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(feature.icon, color: feature.color, size: 24),
            ),
            const Spacer(),
            Text(
              feature.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppPalette.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              feature.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppPalette.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scales its child down slightly while pressed.
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _Pressable({required this.child, required this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
