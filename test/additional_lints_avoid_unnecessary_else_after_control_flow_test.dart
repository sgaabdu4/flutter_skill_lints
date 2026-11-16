import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_else_after_control_flow.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidUnnecessaryElseAfterControlFlowTest>(
    'AvoidUnnecessaryElseAfterControlFlowTest',
    _AvoidUnnecessaryElseAfterControlFlowTest.new,
    _AvoidUnnecessaryElseAfterControlFlowTest._allCases,
  );
}

class _AvoidUnnecessaryElseAfterControlFlowTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidUnnecessaryElseAfterControlFlowTest)>
  get _allCases => caseSet<_AvoidUnnecessaryElseAfterControlFlowTest>(
    parent: const {},
    own: {
      'test_returnBranch_lint': (t) => t._returnBranchLint(),
      'test_throwBranch_lint': (t) => t._throwBranchLint(),
      'test_rethrowBranch_lint': (t) => t._rethrowBranchLint(),
      'test_continueBranch_lint': (t) => t._continueBranchLint(),
      'test_breakBranch_lint': (t) => t._breakBranchLint(),
      'test_nestedIfWhenEveryNestedPathExits_lint': (t) =>
          t._nestedIfWhenEveryNestedPathExitsLint(),
      'test_elseIf_lint': (t) => t._elseIfLint(),
      'test_nonExitingIf_noLint': (t) => t._nonExitingIfNoLint(),
      'test_nestedConditionalReturn_noLint': (t) => t._nestedConditionalReturnNoLint(),
      'test_normalBranching_noLint': (t) => t._normalBranchingNoLint(),
      'test_collectionIfElse_noLint': (t) => t._collectionIfElseNoLint(),
      'test_skillSafePopFallback_noLint': (t) => t._skillSafePopFallbackNoLint(),
      'test_skillDeltaSyncAssignment_noLint': (t) => t._skillDeltaSyncAssignmentNoLint(),
      'test_throwExpressionBranchWithoutBlock_lint': (t) =>
          t._throwExpressionBranchWithoutBlockLint(),
    },
  );

  @override
  void setUp() {
    rule = AvoidUnnecessaryElseAfterControlFlow();
    super.setUp();
  }

  Future<void> _returnBranchLint() async {
    const source = r'''
int f(bool success) {
  if (!success) {
    return 0;
  } else {
    return 1;
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('else'), 'else'.length)]);
  }

  Future<void> _throwBranchLint() async {
    const source = r'''
int f(Object? value) {
  if (value == null) {
    throw 'missing';
  } else {
    return 1;
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('else'), 'else'.length)]);
  }

  Future<void> _rethrowBranchLint() async {
    const source = r'''
int f(Object? value) {
  try {
    return value as int;
  } catch (_) {
    if (value == null) {
      rethrow;
    } else {
      return 1;
    }
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('else {'), 'else'.length)]);
  }

  Future<void> _continueBranchLint() async {
    const source = r'''
void f(List<int> values) {
  for (final value in values) {
    if (value.isNegative) {
      continue;
    } else {
      print(value);
    }
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('else'), 'else'.length)]);
  }

  Future<void> _breakBranchLint() async {
    const source = r'''
void f(List<int> values) {
  for (final value in values) {
    if (value.isNegative) {
      break;
    } else {
      print(value);
    }
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('else'), 'else'.length)]);
  }

  Future<void> _nestedIfWhenEveryNestedPathExitsLint() async {
    const source = r'''
int f(int value) {
  if (value < 10) {
    if (value.isNegative) {
      return -1;
    } else {
      return 0;
    }
  } else {
    return 1;
  }
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('else {\n      return 0;'), 'else'.length),
      lint(source.indexOf('else {\n    return 1;'), 'else'.length),
    ]);
  }

  Future<void> _elseIfLint() async {
    const source = r'''
int f(int value) {
  if (value < 0) {
    return -1;
  } else if (value == 0) {
    return 0;
  }
  return 1;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('else if'), 'else'.length)]);
  }

  Future<void> _nonExitingIfNoLint() async {
    const source = r'''
int f(bool success) {
  if (!success) {
    print('failed');
  } else {
    return 1;
  }
  return 0;
}
''';

    await assertNoDiagnostics(source);
  }

  Future<void> _nestedConditionalReturnNoLint() async {
    const source = r'''
int f(bool outer, bool inner) {
  if (outer) {
    if (inner) {
      return 1;
    }
  } else {
    return 0;
  }
  return 2;
}
''';

    await assertNoDiagnostics(source);
  }

  Future<void> _normalBranchingNoLint() async {
    const source = r'''
void f(bool exists, List<int> items) {
  if (exists) {
    items.add(1);
  } else {
    items.add(2);
  }
}
''';

    await assertNoDiagnostics(source);
  }

  Future<void> _collectionIfElseNoLint() async {
    const source = r'''
List<int> f(bool exists) {
  return [
    if (exists) 1 else 2,
  ];
}
''';

    await assertNoDiagnostics(source);
  }

  Future<void> _skillSafePopFallbackNoLint() async {
    const source = r'''
bool canPop() => true;
void pop(Object? result) {}
void goToList() {}

void f(Object? result) {
  if (canPop()) {
    pop(result);
  } else {
    goToList();
  }
}
''';

    await assertNoDiagnostics(source);
  }

  Future<void> _skillDeltaSyncAssignmentNoLint() async {
    const source = r'''
Future<int> f(int? lastTableSync, Future<List<int>> Function() all) async {
  int watermark;
  if (lastTableSync == null) {
    final items = await all();
    watermark = items.length;
  } else {
    watermark = lastTableSync;
  }
  return watermark;
}
''';

    await assertNoDiagnostics(source);
  }

  Future<void> _throwExpressionBranchWithoutBlockLint() async {
    const source = r'''
int f(Object? value) {
  if (value == null) throw ArgumentError('value');
  else return 1;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('else'), 'else'.length)]);
  }
}
