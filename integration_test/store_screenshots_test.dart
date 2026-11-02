import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gplx/features/test/views/components/question_view_widget.dart';
import 'package:gplx/main.dart' as app;
import 'package:integration_test/integration_test.dart';

/// Walks through the main screens and captures App Store screenshots.
/// Run via `screenshots/capture.sh`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Screens show loaders while data streams in, so pumpAndSettle may never
  // return; pump for a fixed time instead.
  Future<void> wait(WidgetTester tester, [int seconds = 4]) async {
    for (var i = 0; i < seconds * 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> open(WidgetTester tester, String label, [int seconds = 4]) async {
    final target = find.text(label).first;
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await wait(tester, seconds);
  }

  Future<void> backHome(WidgetTester tester) async {
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .popUntil((route) => route.isFirst);
    await wait(tester, 2);
  }

  // The host script (screenshots/capture.sh) watches the log for this marker
  // and grabs the simulator screen with simctl while the app holds still.
  // That keeps the real iOS status bar, which a Flutter-surface capture lacks.
  Future<void> shot(WidgetTester tester, String name) async {
    debugPrint('SHOT:$name');
    await wait(tester, 3);
  }

  testWidgets('store screenshots', (tester) async {
    app.main();
    await wait(tester, 10);
    await shot(tester, '01_home');

    await open(tester, 'Thi theo bộ đề');
    await shot(tester, '02_test_sets');

    await open(tester, 'Đề số 1', 3);
    await open(tester, 'BẮT ĐẦU', 8);
    // Skip questions that depend on a sign image so the shot reads on its own.
    final needsImage = find.byWidgetPredicate((w) =>
        w is Text &&
        RegExp(r'[Bb]iển|[Hh]ình|[Ss]a hình').hasMatch(w.data ?? ''));
    for (var n = 2; n <= 25 && needsImage.evaluate().isNotEmpty; n++) {
      await open(tester, 'Câu $n', 1);
    }
    await tester.tap(find.byType(AnswerOptionWidget).first);
    await wait(tester, 2);
    await shot(tester, '03_quiz');
    await backHome(tester);

    await open(tester, 'Ôn tập câu hỏi', 8);
    await shot(tester, '04_chapters');
    await backHome(tester);

    await open(tester, 'Các biển báo', 6);
    await shot(tester, '05_signs');
    await backHome(tester);

    await open(tester, 'Mẹo ghi nhớ', 6);
    await shot(tester, '06_tips');
    await backHome(tester);
  });
}
