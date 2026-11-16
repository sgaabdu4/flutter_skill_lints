import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/use_unawaited_for_fire_and_forget_futures.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<UseUnawaitedContextTest>(
    'UseUnawaitedContextTest',
    UseUnawaitedContextTest.new,
    {
      'reportsFutureDroppedInDeclaredVoidCallback': (t) =>
          t.reportsFutureDroppedInDeclaredVoidCallback(),
      'reportsFutureDroppedInAssignedVoidCallback': (t) =>
          t.reportsFutureDroppedInAssignedVoidCallback(),
      'acceptsDeclaredCallbackThatReturnsFuture': (t) =>
          t.acceptsDeclaredCallbackThatReturnsFuture(),
      'acceptsCallbackWithoutDeclaredType': (t) => t.acceptsCallbackWithoutDeclaredType(),
      'acceptsAssignmentToUntypedTarget': (t) => t.acceptsAssignmentToUntypedTarget(),
    },
  );
}

final class UseUnawaitedContextTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseUnawaitedForFireAndForgetFutures();
    super.setUp();
  }

  static const _prelude = 'Future<void> fetch() async {}\n';

  Future<void> reportsFutureDroppedInDeclaredVoidCallback() async {
    const source =
        '''
${_prelude}void Function() callback = () {
  fetch();
};
''';
    await assertDiagnostics(source, [lint(source.lastIndexOf('fetch()'), 'fetch()'.length)]);
  }

  Future<void> reportsFutureDroppedInAssignedVoidCallback() async {
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

  Future<void> acceptsDeclaredCallbackThatReturnsFuture() => assertNoDiagnostics('''
${_prelude}Future<void> Function() callback = () {
  fetch();
  return fetch();
};
''');

  Future<void> acceptsCallbackWithoutDeclaredType() => assertNoDiagnostics('''
${_prelude}final callback = () {
  fetch();
};
''');

  Future<void> acceptsAssignmentToUntypedTarget() => assertNoDiagnostics('''
${_prelude}dynamic callback;

void assign() {
  callback = () {
    fetch();
  };
}
''');
}
