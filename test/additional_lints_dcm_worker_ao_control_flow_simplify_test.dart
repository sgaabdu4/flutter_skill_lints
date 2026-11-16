import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_collapsible_if.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_redundant_else.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_if.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidCollapsibleIfTest>('AvoidCollapsibleIfTest', AvoidCollapsibleIfTest.new, {
    'test_singleNestedIf_lint': (t) => t._singleNestedIfLint(),
    'test_outerElse_noLint': (t) => t._outerElseNoLint(),
    'test_innerElse_noLint': (t) => t._innerElseNoLint(),
    'test_extraStatement_noLint': (t) => t._extraStatementNoLint(),
  });
  analysisRuleSuite<AvoidRedundantElseTest>('AvoidRedundantElseTest', AvoidRedundantElseTest.new, {
    'test_returnBranch_lint': (t) => t._returnBranchLint(),
    'test_throwBranch_lint': (t) => t._throwBranchLint(),
    'test_elseIf_noLint': (t) => t._elseIfNoLint(),
    'test_nonExitingBranch_noLint': (t) => t._nonExitingBranchNoLint(),
    'test_nestedConditionalExit_noLint': (t) => t._nestedConditionalExitNoLint(),
  });
  analysisRuleSuite<AvoidUnnecessaryIfTest>('AvoidUnnecessaryIfTest', AvoidUnnecessaryIfTest.new, {
    'test_oppositeBooleanReturns_lint': (t) => t._oppositeBooleanReturnsLint(),
    'test_oppositeBooleanAssignments_lint': (t) => t._oppositeBooleanAssignmentsLint(),
    'test_sameBooleanReturns_noLint': (t) => t._sameBooleanReturnsNoLint(),
    'test_differentAssignmentTargets_noLint': (t) => t._differentAssignmentTargetsNoLint(),
    'test_elseIf_noLint': (t) => t._elseIfNoLint(),
  });
}

final class AvoidCollapsibleIfTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCollapsibleIf();
    super.setUp();
  }

  Future<void> _singleNestedIfLint() async {
    const source = r'''
void f(bool ready, bool enabled) {
  if (ready) {
    if (enabled) {
      print('go');
    }
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('if (enabled)'), 'if'.length)]);
  }

  Future<void> _outerElseNoLint() async {
    await assertNoDiagnostics(r'''
void f(bool ready, bool enabled) {
  if (ready) {
    if (enabled) {
      print('go');
    }
  } else {
    print('stop');
  }
}
''');
  }

  Future<void> _innerElseNoLint() async {
    await assertNoDiagnostics(r'''
void f(bool ready, bool enabled) {
  if (ready) {
    if (enabled) {
      print('go');
    } else {
      print('wait');
    }
  }
}
''');
  }

  Future<void> _extraStatementNoLint() async {
    await assertNoDiagnostics(r'''
void f(bool ready, bool enabled) {
  if (ready) {
    print('checking');
    if (enabled) {
      print('go');
    }
  }
}
''');
  }
}

final class AvoidRedundantElseTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidRedundantElse();
    super.setUp();
  }

  Future<void> _returnBranchLint() async {
    const source = r'''
int f(bool ready) {
  if (!ready) {
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

  Future<void> _elseIfNoLint() async {
    await assertNoDiagnostics(r'''
int f(int value) {
  if (value < 0) {
    return -1;
  } else if (value == 0) {
    return 0;
  }
  return 1;
}
''');
  }

  Future<void> _nonExitingBranchNoLint() async {
    await assertNoDiagnostics(r'''
int f(bool ready) {
  if (!ready) {
    print('wait');
  } else {
    return 1;
  }
  return 0;
}
''');
  }

  Future<void> _nestedConditionalExitNoLint() async {
    await assertNoDiagnostics(r'''
int f(bool outer, bool inner) {
  if (outer) {
    if (inner) {
      return 1;
    }
    return 2;
  } else {
    return 0;
  }
}
''');
  }
}

final class AvoidUnnecessaryIfTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryIf();
    super.setUp();
  }

  Future<void> _oppositeBooleanReturnsLint() async {
    const source = r'''
bool f(bool ready) {
  if (ready) {
    return true;
  } else {
    return false;
  }
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('if (ready)'), source.indexOf('\n}') - source.indexOf('if (ready)')),
    ]);
  }

  Future<void> _oppositeBooleanAssignmentsLint() async {
    const source = r'''
void f(bool ready) {
  var enabled = false;
  if (ready) {
    enabled = true;
  } else {
    enabled = false;
  }
  print(enabled);
}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('if (ready)'),
        source.indexOf('\n  print') - source.indexOf('if (ready)'),
      ),
    ]);
  }

  Future<void> _sameBooleanReturnsNoLint() async {
    await assertNoDiagnostics(r'''
bool f(bool ready) {
  if (ready) {
    return true;
  } else {
    return true;
  }
}
''');
  }

  Future<void> _differentAssignmentTargetsNoLint() async {
    await assertNoDiagnostics(r'''
void f(bool ready) {
  var enabled = false;
  var visible = false;
  if (ready) {
    enabled = true;
  } else {
    visible = false;
  }
}
''');
  }

  Future<void> _elseIfNoLint() async {
    await assertNoDiagnostics(r'''
bool f(bool first, bool second) {
  if (first) {
    return true;
  } else if (second) {
    return false;
  }
  return false;
}
''');
  }
}
