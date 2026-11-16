import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_unnecessary_consumer_widgets_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_consumer_widgets.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_riverpod_stub.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<AvoidUnnecessaryConsumerWidgetsTest>(
    'AvoidUnnecessaryConsumerWidgetsTest',
    AvoidUnnecessaryConsumerWidgetsTest.new,
    {
      'reportsConsumerWidgetThatNeverUsesRef': (t) => t.reportsConsumerWidgetThatNeverUsesRef(),
      'acceptsConsumerWidgetThatUsesRef': (t) => t.acceptsConsumerWidgetThatUsesRef(),
      'acceptsConsumerWidgetWithoutRefParameter': (t) =>
          t.acceptsConsumerWidgetWithoutRefParameter(),
      'acceptsPlainStatelessWidget': (t) => t.acceptsPlainStatelessWidget(),
      'acceptsPublicPageInScreensFolder': (t) => t.acceptsPublicPageInScreensFolder(),
      'convertsConsumerWidgetToStateless': (t) => t.convertsConsumerWidgetToStateless(),
    },
  );
}

final class AvoidUnnecessaryConsumerWidgetsTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    addFlutterRiverpod(this);
    rule = AvoidUnnecessaryConsumerWidgets();
    super.setUp();
  }

  static const _unused = '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Tile extends ConsumerWidget {
  const Tile();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Text('a');
}
''';

  Future<void> reportsConsumerWidgetThatNeverUsesRef() =>
      assertDiagnostics(_unused, [lint(_unused.indexOf('Tile extends'), 'Tile'.length)]);

  Future<void> acceptsConsumerWidgetThatUsesRef() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Tile extends ConsumerWidget {
  const Tile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read<int>(Object());
    return Text('a');
  }
}
''');

  Future<void> acceptsConsumerWidgetWithoutRefParameter() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Tile extends ConsumerWidget {
  const Tile();

  @override
  Widget build(BuildContext context, WidgetRef other) => Text('a');
}
''');

  Future<void> acceptsPlainStatelessWidget() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

class Tile extends StatelessWidget {
  const Tile();

  @override
  Widget build(BuildContext context) => Text('a');
}
''');

  Future<void> acceptsPublicPageInScreensFolder() async {
    final path = '$testPackageLibPath/features/todos/presentation/screens/todo_screen.dart';
    newFile(path, _unused);
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> convertsConsumerWidgetToStateless() => expectFix(
    _unused,
    (context) => AvoidUnnecessaryConsumerWidgetsFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Tile extends StatelessWidget {
  const Tile();

  @override
  Widget build(BuildContext context) => Text('a');
}
''',
  );
}
