// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_collapsible_if.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_redundant_else.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_if.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidCollapsibleIfTest);
    defineReflectiveTests(AvoidRedundantElseTest);
    defineReflectiveTests(AvoidUnnecessaryIfTest);
  });
}

@reflectiveTest
final class AvoidCollapsibleIfTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCollapsibleIf();
    super.setUp();
  }

  Future<void> test_singleNestedIf_lint() async {
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

  Future<void> test_outerElse_noLint() async {
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

  Future<void> test_innerElse_noLint() async {
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

  Future<void> test_extraStatement_noLint() async {
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

@reflectiveTest
final class AvoidRedundantElseTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidRedundantElse();
    super.setUp();
  }

  Future<void> test_returnBranch_lint() async {
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

  Future<void> test_throwBranch_lint() async {
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

  Future<void> test_elseIf_noLint() async {
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

  Future<void> test_nonExitingBranch_noLint() async {
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

  Future<void> test_nestedConditionalExit_noLint() async {
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

@reflectiveTest
final class AvoidUnnecessaryIfTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryIf();
    super.setUp();
  }

  Future<void> test_oppositeBooleanReturns_lint() async {
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

  Future<void> test_oppositeBooleanAssignments_lint() async {
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

  Future<void> test_sameBooleanReturns_noLint() async {
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

  Future<void> test_differentAssignmentTargets_noLint() async {
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

  Future<void> test_elseIf_noLint() async {
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
