import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/use_unawaited_for_fire_and_forget_futures.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_UseUnawaitedContextTest>(
    'UseUnawaitedContextTest',
    _UseUnawaitedContextTest.new,
    {
      'reportsFutureDroppedInDeclaredVoidCallback': (t) =>
          t._reportsFutureDroppedInDeclaredVoidCallback(),
      'reportsFutureDroppedInAssignedVoidCallback': (t) =>
          t._reportsFutureDroppedInAssignedVoidCallback(),
      'acceptsDeclaredCallbackThatReturnsFuture': (t) =>
          t._acceptsDeclaredCallbackThatReturnsFuture(),
      'acceptsCallbackWithoutDeclaredType': (t) => t._acceptsCallbackWithoutDeclaredType(),
      'acceptsAssignmentToUntypedTarget': (t) => t._acceptsAssignmentToUntypedTarget(),
    },
  );
}

final class _UseUnawaitedContextTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseUnawaitedForFireAndForgetFutures();
    super.setUp();
  }

  static const _prelude = 'Future<void> fetch() async {}\n';

  Future<void> _reportsFutureDroppedInDeclaredVoidCallback() async {
    const source =
        '''
${_prelude}void Function() callback = () {
  fetch();
};
''';
    await assertDiagnostics(source, [lint(source.lastIndexOf('fetch()'), 'fetch()'.length)]);
  }

  Future<void> _reportsFutureDroppedInAssignedVoidCallback() async {
    const source =
        '''
${_prelude}void Function()? callback;

void assign() {
  callback = () {
    fetch();
  };
}
''';
    await assertDiagnostics(source, [lint(source.lastIndexOf('fetch()'), 'fetch()'.length)]);
  }

  Future<void> _acceptsDeclaredCallbackThatReturnsFuture() => assertNoDiagnostics('''
${_prelude}Future<void> Function() callback = () {
  fetch();
  return fetch();
};
''');

  Future<void> _acceptsCallbackWithoutDeclaredType() => assertNoDiagnostics('''
${_prelude}final callback = () {
  fetch();
};
''');

  Future<void> _acceptsAssignmentToUntypedTarget() => assertNoDiagnostics('''
${_prelude}dynamic callback;

void assign() {
  callback = () {
    fetch();
  };
}
''');
}
