import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_ref_and_state_synchronously.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<UseRefAndStateSynchronouslyTest>(
    'UseRefAndStateSynchronouslyTest',
    UseRefAndStateSynchronouslyTest.new,
    {
      'reportsStateAssignmentAfterAwait': (t) => t.reportsStateAssignmentAfterAwait(),
      'reportsRefMethodCallAfterAwait': (t) => t.reportsRefMethodCallAfterAwait(),
      'reportsStatePropertyAfterAwait': (t) => t.reportsStatePropertyAfterAwait(),
      'reportsStateUsedAsArgumentAfterAwait': (t) => t.reportsStateUsedAsArgumentAfterAwait(),
      'reportsUseInStatementThatContainsAwait': (t) => t.reportsUseInStatementThatContainsAwait(),
      'acceptsUseAfterMountedGuard': (t) => t.acceptsUseAfterMountedGuard(),
      'acceptsMountedCheckItself': (t) => t.acceptsMountedCheckItself(),
      'acceptsUseBeforeAwait': (t) => t.acceptsUseBeforeAwait(),
      'acceptsUseInsideClosure': (t) => t.acceptsUseInsideClosure(),
      'ignoresSynchronousMethods': (t) => t.ignoresSynchronousMethods(),
      'ignoresClassesThatAreNotNotifiers': (t) => t.ignoresClassesThatAreNotNotifiers(),
    },
  );
}

final class UseRefAndStateSynchronouslyTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseRefAndStateSynchronously();
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
class Ref {
  T read<T>(Object provider) => throw 'unused';
  bool get mounted => true;
}

abstract class Notifier<T> {
  Ref get ref => Ref();
  late T state;
  T build();
}
''');
    super.setUp();
  }

  static String _source(String body) =>
      '''
import 'package:riverpod/riverpod.dart';

Future<void> work() async {}
void use(Object value) {}

class N extends Notifier<String> {
  @override
  String build() => '';

  Future<void> run() async {
$body
  }
}
''';

  Future<void> _expectReported(String statement, String reported) async {
    final source = _source('    await work();\n    $statement');
    await assertDiagnostics(source, [lint(source.indexOf(reported), reported.length)]);
  }

  Future<void> reportsStateAssignmentAfterAwait() => _expectReported("state = 'a';", "state = 'a'");

  Future<void> reportsRefMethodCallAfterAwait() =>
      _expectReported('ref.read<int>(work);', 'ref.read<int>(work)');

  Future<void> reportsStatePropertyAfterAwait() => _expectReported('state.length;', 'state.length');

  Future<void> reportsStateUsedAsArgumentAfterAwait() async {
    final source = _source('    await work();\n    use(state);');
    await assertDiagnostics(source, [lint(source.lastIndexOf('state'), 'state'.length)]);
  }

  Future<void> reportsUseInStatementThatContainsAwait() async {
    final source = _source('''
    await work();
    if (state.isEmpty) {
      await work();
    }''');
    await assertDiagnostics(source, [
      lint(source.indexOf('state.isEmpty'), 'state.isEmpty'.length),
    ]);
  }

  Future<void> acceptsUseAfterMountedGuard() => assertNoDiagnostics(
    _source('''
    await work();
    if (!ref.mounted) return;
    state = 'a';'''),
  );

  Future<void> acceptsMountedCheckItself() => assertNoDiagnostics(
    _source('''
    await work();
    if (!ref.mounted) {
      return;
    }
    final ok = ref.mounted;'''),
  );

  Future<void> acceptsUseBeforeAwait() => assertNoDiagnostics(
    _source('''
    state = 'a';
    await work();'''),
  );

  Future<void> acceptsUseInsideClosure() => assertNoDiagnostics(
    _source('''
    await work();
    final later = () => state;'''),
  );

  Future<void> ignoresSynchronousMethods() => assertNoDiagnostics('''
import 'package:riverpod/riverpod.dart';

class N extends Notifier<String> {
  @override
  String build() => '';

  void run() {
    state = 'a';
  }
}
''');

  Future<void> ignoresClassesThatAreNotNotifiers() => assertNoDiagnostics('''
class Plain {
  String state = '';

  Future<void> run() async {
    await Future<void>.value();
    state = 'a';
  }
}
''');
}
