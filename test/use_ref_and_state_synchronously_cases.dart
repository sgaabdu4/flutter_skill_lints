import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_ref_and_state_synchronously.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_UseRefAndStateSynchronouslyTest>(
    'UseRefAndStateSynchronouslyTest',
    _UseRefAndStateSynchronouslyTest.new,
    {
      'reportsStateAssignmentAfterAwait': (t) => t._reportsStateAssignmentAfterAwait(),
      'reportsRefMethodCallAfterAwait': (t) => t._reportsRefMethodCallAfterAwait(),
      'reportsStatePropertyAfterAwait': (t) => t._reportsStatePropertyAfterAwait(),
      'reportsStateUsedAsArgumentAfterAwait': (t) => t._reportsStateUsedAsArgumentAfterAwait(),
      'reportsUseInStatementThatContainsAwait': (t) => t._reportsUseInStatementThatContainsAwait(),
      'acceptsUseAfterMountedGuard': (t) => t._acceptsUseAfterMountedGuard(),
      'acceptsMountedCheckItself': (t) => t._acceptsMountedCheckItself(),
      'acceptsUseBeforeAwait': (t) => t._acceptsUseBeforeAwait(),
      'acceptsUseInsideClosure': (t) => t._acceptsUseInsideClosure(),
      'ignoresSynchronousMethods': (t) => t._ignoresSynchronousMethods(),
      'ignoresClassesThatAreNotNotifiers': (t) => t._ignoresClassesThatAreNotNotifiers(),
    },
  );
}

final class _UseRefAndStateSynchronouslyTest extends AnalysisRuleTest {
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

  Future<void> _reportsStateAssignmentAfterAwait() =>
      _expectReported("state = 'a';", "state = 'a'");

  Future<void> _reportsRefMethodCallAfterAwait() =>
      _expectReported('ref.read<int>(work);', 'ref.read<int>(work)');

  Future<void> _reportsStatePropertyAfterAwait() =>
      _expectReported('state.length;', 'state.length');

  Future<void> _reportsStateUsedAsArgumentAfterAwait() async {
    final source = _source('    await work();\n    use(state);');
    await assertDiagnostics(source, [lint(source.lastIndexOf('state'), 'state'.length)]);
  }

  Future<void> _reportsUseInStatementThatContainsAwait() async {
    final source = _source('''
    await work();
    if (state.isEmpty) {
      await work();
    }''');
    await assertDiagnostics(source, [
      lint(source.indexOf('state.isEmpty'), 'state.isEmpty'.length),
    ]);
  }

  Future<void> _acceptsUseAfterMountedGuard() => assertNoDiagnostics(
    _source('''
    await work();
    if (!ref.mounted) return;
    state = 'a';'''),
  );

  Future<void> _acceptsMountedCheckItself() => assertNoDiagnostics(
    _source('''
    await work();
    if (!ref.mounted) {
      return;
    }
    final ok = ref.mounted;'''),
  );

  Future<void> _acceptsUseBeforeAwait() => assertNoDiagnostics(
    _source('''
    state = 'a';
    await work();'''),
  );

  Future<void> _acceptsUseInsideClosure() => assertNoDiagnostics(
    _source('''
    await work();
    final later = () => state;'''),
  );

  Future<void> _ignoresSynchronousMethods() => assertNoDiagnostics('''
import 'package:riverpod/riverpod.dart';

class N extends Notifier<String> {
  @override
  String build() => '';

  void run() {
    state = 'a';
  }
}
''');

  Future<void> _ignoresClassesThatAreNotNotifiers() => assertNoDiagnostics('''
class Plain {
  String state = '';

  Future<void> run() async {
    await Future<void>.value();
    state = 'a';
  }
}
''');
}
