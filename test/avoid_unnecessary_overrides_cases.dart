import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_unnecessary_overrides_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_unnecessary_overrides_in_state_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_overrides.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_overrides_in_state.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_AvoidUnnecessaryOverridesTest>(
    'AvoidUnnecessaryOverridesTest',
    _AvoidUnnecessaryOverridesTest.new,
    {
      'reportsMethodThatOnlyCallsSuper': (t) => t._reportsMethodThatOnlyCallsSuper(),
      'reportsMethodWithBlockBody': (t) => t._reportsMethodWithBlockBody(),
      'reportsPassThroughParameters': (t) => t._reportsPassThroughParameters(),
      'reportsGetterThatOnlyReturnsSuper': (t) => t._reportsGetterThatOnlyReturnsSuper(),
      'reportsSetterThatOnlyAssignsSuper': (t) => t._reportsSetterThatOnlyAssignsSuper(),
      'reportsOperatorThatOnlyCallsSuper': (t) => t._reportsOperatorThatOnlyCallsSuper(),
      'reportsOverridesInMixins': (t) => t._reportsOverridesInMixins(),
      'acceptsMethodsThatAddLogic': (t) => t._acceptsMethodsThatAddLogic(),
      'acceptsReorderedOrChangedArguments': (t) => t._acceptsReorderedOrChangedArguments(),
      'acceptsMethodsWithoutOverrideAnnotation': (t) =>
          t._acceptsMethodsWithoutOverrideAnnotation(),
      'acceptsGettersAndSettersThatChangeValues': (t) =>
          t._acceptsGettersAndSettersThatChangeValues(),
      'acceptsDifferentSuperMember': (t) => t._acceptsDifferentSuperMember(),
      'removesUnnecessaryOverrideWithItsAnnotation': (t) =>
          t._removesUnnecessaryOverrideWithItsAnnotation(),
    },
  );
  analysisRuleSuite<_AvoidUnnecessaryOverridesInStateTest>(
    'AvoidUnnecessaryOverridesInStateTest',
    _AvoidUnnecessaryOverridesInStateTest.new,
    {
      'reportsStateOverridesThatOnlyCallSuper': (t) => t._reportsStateOverridesThatOnlyCallSuper(),
      'acceptsStateOverridesWithLogic': (t) => t._acceptsStateOverridesWithLogic(),
      'ignoresClassesThatAreNotState': (t) => t._ignoresClassesThatAreNotState(),
      'removesStateOverride': (t) => t._removesStateOverride(),
    },
  );
}

final class _AvoidUnnecessaryOverridesTest extends FixRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryOverrides();
    super.setUp();
  }

  static const _base = '''
class Base {
  int value = 0;
  int get size => 0;
  set size(int v) {}
  void run(int a, {int b = 0}) {}
  Base operator +(Base other) => this;
}

''';

  Future<void> _expectReported(String member) async {
    final source = '${_base}class Child extends Base {\n  @override\n$member\n}\n';
    final reported = '@override\n$member';
    await assertDiagnostics(source, [lint(source.indexOf(reported), reported.length)]);
  }

  Future<void> _reportsMethodThatOnlyCallsSuper() {
    const member = '  void run(int a, {int b = 0}) => super.run(a, b: b);';
    return _expectReported(member);
  }

  Future<void> _reportsMethodWithBlockBody() {
    const member = '  void run(int a, {int b = 0}) {\n    super.run(a, b: b);\n  }';
    return _expectReported(member);
  }

  Future<void> _reportsPassThroughParameters() {
    const member = '  void run(int a, {int b = 0}) { return super.run(a, b: b); }';
    return _expectReported(member);
  }

  Future<void> _reportsGetterThatOnlyReturnsSuper() {
    const member = '  int get size => super.size;';
    return _expectReported(member);
  }

  Future<void> _reportsSetterThatOnlyAssignsSuper() {
    const member = '  set size(int v) => super.size = v;';
    return _expectReported(member);
  }

  Future<void> _reportsOperatorThatOnlyCallsSuper() {
    const member = '  Base operator +(Base other) => super + other;';
    return _expectReported(member);
  }

  Future<void> _reportsOverridesInMixins() async {
    const source = '''
class Base {
  void run() {}
}

mixin Helper on Base {
  @override
  void run() => super.run();
}
''';
    const member = '@override\n  void run() => super.run();';
    await assertDiagnostics(source, [lint(source.indexOf(member), member.length)]);
  }

  Future<void> _acceptsMethodsThatAddLogic() => assertNoDiagnostics('''
${_base}class Child extends Base {
  @override
  void run(int a, {int b = 0}) {
    print(a);
    super.run(a, b: b);
  }
}
''');

  Future<void> _acceptsReorderedOrChangedArguments() => assertNoDiagnostics('''
${_base}class Child extends Base {
  @override
  void run(int a, {int b = 0}) => super.run(b, b: a);
}
''');

  Future<void> _acceptsMethodsWithoutOverrideAnnotation() => assertNoDiagnostics('''
class Base {
  void run() {}
}

class Child extends Base {
  void run() => super.run();
}
''');

  Future<void> _acceptsGettersAndSettersThatChangeValues() => assertNoDiagnostics('''
${_base}class Child extends Base {
  @override
  int get size => super.size + 1;

  @override
  set size(int v) => super.size = v + 1;
}
''');

  Future<void> _acceptsDifferentSuperMember() => assertNoDiagnostics('''
class Base {
  void run() {}
  void stop() {}
}

class Child extends Base {
  @override
  void run() => super.stop();
}
''');

  Future<void> _removesUnnecessaryOverrideWithItsAnnotation() => expectFix(
    '''
class Base {
  void run() {}
  void stop() {}
}

class Child extends Base {
  @override
  void run() => super.run();

  @override
  void stop() {
    print(1);
    super.stop();
  }
}
''',
    (context) => AvoidUnnecessaryOverridesFix(context: context),
    expected: '''
class Base {
  void run() {}
  void stop() {}
}

class Child extends Base {
  @override
  void stop() {
    print(1);
    super.stop();
  }
}
''',
  );
}

final class _AvoidUnnecessaryOverridesInStateTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = AvoidUnnecessaryOverridesInState();
    super.setUp();
  }

  static String _state(String members) =>
      '''
import 'package:flutter/widgets.dart';

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
$members
  @override
  Widget build(BuildContext context) => Text('a');
}
''';

  Future<void> _reportsStateOverridesThatOnlyCallSuper() async {
    final source = _state('''
  @override
  void initState() => super.initState();

  @override
  void dispose() {
    super.dispose();
  }
''');
    await assertDiagnostics(source, [
      lint(
        source.indexOf('@override\n  void initState'),
        '@override\n  void initState() => super.initState();'.length,
      ),
      lint(
        source.indexOf('@override\n  void dispose'),
        '@override\n  void dispose() {\n    super.dispose();\n  }'.length,
      ),
    ]);
  }

  Future<void> _acceptsStateOverridesWithLogic() => assertNoDiagnostics(
    _state('''
  @override
  void initState() {
    super.initState();
    print(1);
  }
'''),
  );

  Future<void> _ignoresClassesThatAreNotState() => assertNoDiagnostics('''
class Base {
  void initState() {}
}

class Child extends Base {
  @override
  void initState() => super.initState();
}
''');

  Future<void> _removesStateOverride() => expectFix(
    _state('''
  @override
  void initState() => super.initState();
'''),
    (context) => AvoidUnnecessaryOverridesInStateFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
  @override
  Widget build(BuildContext context) => Text('a');
}
''',
  );
}
