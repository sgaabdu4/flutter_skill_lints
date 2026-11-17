const uiQualityRedCardSource = r'''
import 'package:flutter/material.dart';

class RedItemCard extends StatelessWidget {
  const RedItemCard({
    super.key,
    required this.onApprove,
    required this.onDecline,
    required this.onMore,
  });

  final VoidCallback onApprove;
  final VoidCallback onDecline;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Pending review',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
              ),
            ),
            const Text('Due today', style: TextStyle(fontSize: 12, color: Color(0xFFFFB300))),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: onApprove,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approve', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onDecline,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF795548),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Decline', style: TextStyle(fontSize: 12)),
                ),
                const Spacer(),
                IconButton(
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: onMore,
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
''';

const uiQualityFixedCardSource = r'''
import 'package:flutter/material.dart';

class FixedItemCard extends StatelessWidget {
  const FixedItemCard({
    super.key,
    required this.onApprove,
    required this.onDecline,
    required this.onMore,
  });

  final VoidCallback onApprove;
  final VoidCallback onDecline;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Text('Pending review', textAlign: TextAlign.center)),
            const Text('Due today', style: TextStyle(color: Color(0xFF7A4F00))),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(onPressed: onApprove, child: const Text('Approve')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: onDecline, child: const Text('Decline')),
                const Spacer(),
                IconButton(
                  tooltip: 'More actions',
                  onPressed: onMore,
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
''';

const uiQualityGuidelineTestSource = r'''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_skill_lints_ui_fixture/fixed_item_card.dart';
import 'package:flutter_skill_lints_ui_fixture/red_item_card.dart';

const _widths = [390.0, 768.0, 1280.0];

final _guidelines = <String, AccessibilityGuideline>{
  'textContrastGuideline': textContrastGuideline,
  'labeledTapTargetGuideline': labeledTapTargetGuideline,
  'iOSTapTargetGuideline': iOSTapTargetGuideline,
  'androidTapTargetGuideline': androidTapTargetGuideline,
};

Future<void> _pump(WidgetTester tester, double width, Widget Function() card) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Align(alignment: Alignment.topCenter, child: card()))),
  );
}

void main() {
  for (final width in _widths) {
    for (final entry in _guidelines.entries) {
      testWidgets('red card fails ${entry.key} at ${width.toInt()} px', (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(
          tester,
          width,
          () => RedItemCard(onApprove: () {}, onDecline: () {}, onMore: () {}),
        );
        final evaluation = await entry.value.evaluate(tester);
        expect(evaluation.passed, isFalse, reason: 'the red card must fail ${entry.key}');
        handle.dispose();
      });

      testWidgets('fixed card passes ${entry.key} at ${width.toInt()} px', (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(
          tester,
          width,
          () => FixedItemCard(onApprove: () {}, onDecline: () {}, onMore: () {}),
        );
        await expectLater(tester, meetsGuideline(entry.value));
        handle.dispose();
      });
    }
  }
}
''';
