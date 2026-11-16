import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_unnecessary_stateful_widgets_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_stateful_widgets.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_AvoidUnnecessaryStatefulWidgetsTest>(
    'AvoidUnnecessaryStatefulWidgetsTest',
    _AvoidUnnecessaryStatefulWidgetsTest.new,
    {
      'reportsStatefulWidgetWithStatelessState': (t) =>
          t._reportsStatefulWidgetWithStatelessState(),
      'acceptsMutableField': (t) => t._acceptsMutableField(),
      'acceptsLifecycleMethod': (t) => t._acceptsLifecycleMethod(),
      'acceptsSetStateCall': (t) => t._acceptsSetStateCall(),
      'acceptsFinalAndStaticFields': (t) => t._acceptsFinalAndStaticFields(),
      'ignoresWidgetWithoutStateClass': (t) => t._ignoresWidgetWithoutStateClass(),
      'convertsToStatelessWidget': (t) => t._convertsToStatelessWidget(),
      'keepsHelperMembersAndAnnotations': (t) => t._keepsHelperMembersAndAnnotations(),
    },
  );
}

final class _AvoidUnnecessaryStatefulWidgetsTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = AvoidUnnecessaryStatefulWidgets();
    super.setUp();
  }

  static const _simple = '''
import 'package:flutter/widgets.dart';

class Tile extends StatefulWidget {
  const Tile();

  @override
  State<Tile> createState() => _TileState();
}

class _TileState extends State<Tile> {
  @override
  Widget build(BuildContext context) => Text('a');
}
''';

  static String _stateful(String stateMembers) =>
      '''
import 'package:flutter/widgets.dart';

class Tile extends StatefulWidget {
  const Tile();

  @override
  State<Tile> createState() => _TileState();
}

class _TileState extends State<Tile> {
$stateMembers
  @override
  Widget build(BuildContext context) => Text('a');
}
''';

  Future<void> _reportsStatefulWidgetWithStatelessState() =>
      assertDiagnostics(_simple, [lint(_simple.indexOf('Tile extends'), 'Tile'.length)]);

  Future<void> _acceptsMutableField() => assertNoDiagnostics(_stateful('  int count = 0;\n'));

  Future<void> _acceptsLifecycleMethod() => assertNoDiagnostics(
    _stateful('''
  @override
  void initState() {
    super.initState();
  }
'''),
  );

  Future<void> _acceptsSetStateCall() => assertNoDiagnostics(
    _stateful('''
  void bump() {
    setState(() {});
  }
'''),
  );

  Future<void> _acceptsFinalAndStaticFields() async {
    final source = _stateful('  static int shared = 0;\n  final int fixed = 1;\n');
    await assertDiagnostics(source, [lint(source.indexOf('Tile extends'), 'Tile'.length)]);
  }

  Future<void> _ignoresWidgetWithoutStateClass() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

class Tile extends StatefulWidget {
  const Tile();
}
''');

  Future<void> _convertsToStatelessWidget() => expectFix(
    _simple,
    (context) => AvoidUnnecessaryStatefulWidgetsFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

class Tile extends StatelessWidget {
  const Tile();

  @override Widget build(BuildContext context) => Text('a');
}
''',
  );

  Future<void> _keepsHelperMembersAndAnnotations() => expectFix(
    '''
import 'package:flutter/widgets.dart';

@immutable
class Tile extends StatefulWidget {
  const Tile();

  @override
  State<Tile> createState() => _TileState();
}

class _TileState extends State<Tile> {
  final int fixed = 1;

  String label() => 'x';

  @override
  Widget build(BuildContext context) => Text(label());
}
''',
    (context) => AvoidUnnecessaryStatefulWidgetsFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

@immutable
class Tile extends StatelessWidget {
  const Tile();

  final int fixed = 1;

  String label() => 'x';

  @override Widget build(BuildContext context) => Text(label());
}
''',
  );
}
