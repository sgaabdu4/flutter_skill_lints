// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_else_after_control_flow.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidUnnecessaryElseAfterControlFlowTest));
}

@reflectiveTest
class AvoidUnnecessaryElseAfterControlFlowTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryElseAfterControlFlow();
    super.setUp();
  }

  Future<void> test_returnBranch_lint() async {
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

  Future<void> test_rethrowBranch_lint() async {
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

  Future<void> test_continueBranch_lint() async {
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

  Future<void> test_breakBranch_lint() async {
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

  Future<void> test_nestedIfWhenEveryNestedPathExits_lint() async {
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

  Future<void> test_elseIf_lint() async {
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

  Future<void> test_nonExitingIf_noLint() async {
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

    await assertDiagnostics(source, [lint(source.indexOf('else'), 'else'.length)]);
  }

  Future<void> test_nestedConditionalReturn_lint() async {
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

    await assertDiagnostics(source, [lint(source.indexOf('else'), 'else'.length)]);
  }

  Future<void> test_normalBranching_lint() async {
    const source = r'''
void f(bool exists, List<int> items) {
  if (exists) {
    items.add(1);
  } else {
    items.add(2);
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('else'), 'else'.length)]);
  }

  Future<void> test_collectionIfElse_lint() async {
    const source = r'''
List<int> f(bool exists) {
  return [
    if (exists) 1 else 2,
  ];
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('else'), 'else'.length)]);
  }
}
