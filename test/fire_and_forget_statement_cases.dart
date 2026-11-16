import 'dart:math' as math;

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/persistence_crash_source_rules.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_FireAndForgetStatementTest>(
    'FireAndForgetStatementTest',
    _FireAndForgetStatementTest.new,
    {
      'reportsAbstractCalleeWithRiskyName': (t) => t._reportsAbstractCalleeWithRiskyName(),
      'reportsStatementSpanningLines': (t) => t._reportsStatementSpanningLines(),
      'acceptsAbstractCalleeWithoutRiskyName': (t) => t._acceptsAbstractCalleeWithoutRiskyName(),
      'acceptsNestedCatchError': (t) => t._acceptsNestedCatchError(),
      'acceptsTryCatchInsideStatement': (t) => t._acceptsTryCatchInsideStatement(),
    },
  );
}

final class _FireAndForgetStatementTest extends AnalysisRuleTest {
  static const _prelude = '''
import 'dart:async';

abstract interface class Client {
  Future<void> sync();
  Future<void> ping();
}

abstract interface class Gate {
  Future<void> run(Object work);
}

''';

  @override
  void setUp() {
    rule = persistenceCrashSourceRules.singleWhere(
      (candidate) => candidate.name == 'fire_and_forget_missing_catch',
    );
    super.setUp();
  }

  Future<void> _expectReported(String body, String needle) async {
    final source = '$_prelude$body';
    final offset = source.indexOf(needle);
    final lineEnd = source.indexOf('\n', offset);
    await assertDiagnostics(source, [
      lint(offset, math.max(1, lineEnd - offset), name: 'fire_and_forget_missing_catch'),
    ]);
  }

  Future<void> _reportsAbstractCalleeWithRiskyName() => _expectReported('''
void mirror(Client client) {
  unawaited(client.sync());
}
''', 'unawaited(client.sync())');

  Future<void> _reportsStatementSpanningLines() => _expectReported('''
void mirror(Client client) {
  unawaited(
    client
        .sync(),
  );
}
''', 'unawaited(\n');

  Future<void> _acceptsAbstractCalleeWithoutRiskyName() => assertNoDiagnostics('''
$_prelude
void mirror(Client client) {
  unawaited(client.ping());
}
''');

  Future<void> _acceptsNestedCatchError() => assertNoDiagnostics('''
$_prelude
void mirror(Client client, Gate gate) {
  unawaited(gate.run(client.sync().catchError((Object error) {})));
}
''');

  Future<void> _acceptsTryCatchInsideStatement() => assertNoDiagnostics('''
$_prelude
void mirror(Client client, Gate gate) {
  unawaited(gate.run(() {
    try {
      client.sync();
    } catch (error) {
      return;
    }
  }));
}
''');
}
