// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_mounted_check_in_finally.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(AvoidMountedCheckInFinallyTest));
}

@reflectiveTest
class AvoidMountedCheckInFinallyTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMountedCheckInFinally();
    super.setUp();
  }

  Future<void> test_refMountedReturn_inFinally_lint() async {
    await assertDiagnostics(
      r'''
class Ref { bool get mounted => true; }
class State { State copyWith({bool? isResetting}) => this; }
Future<void> f(Ref ref, State state) async {
  try {
    await Future<void>.value();
  } finally {
    if (!ref.mounted) return;
    state = state.copyWith(isResetting: false);
  }
}
''',
      [lint(204, 25)],
    );
  }

  Future<void> test_contextMountedReturn_inFinally_lint() async {
    await assertDiagnostics(
      r'''
class Ctx { bool get mounted => true; }
Future<void> f(Ctx context) async {
  try {
    await Future<void>.value();
  } finally {
    if (!context.mounted) return;
  }
}
''',
      [lint(134, 29)],
    );
  }

  Future<void> test_bareMountedReturn_inFinally_lint() async {
    await assertDiagnostics(
      r'''
class S {
  bool get mounted => true;
  Future<void> f() async {
    try {
      await Future<void>.value();
    } finally {
      if (!mounted) return;
    }
  }
}
''',
      [lint(131, 21)],
    );
  }

  Future<void> test_returnInBlock_inFinally_lint() async {
    await assertDiagnostics(
      r'''
class Ref { bool get mounted => true; }
Future<void> f(Ref ref) async {
  try {
    await Future<void>.value();
  } finally {
    if (!ref.mounted) {
      return;
    }
  }
}
''',
      [lint(130, 39)],
    );
  }

  Future<void> test_guardForm_inFinally_noLint() async {
    await assertNoDiagnostics(r'''
class Ref { bool get mounted => true; }
class State { State copyWith({bool? isResetting}) => this; }
Future<void> f(Ref ref, State state) async {
  try {
    await Future<void>.value();
  } finally {
    if (ref.mounted) {
      state = state.copyWith(isResetting: false);
    }
  }
}
''');
  }

  Future<void> test_singleLineGuard_inFinally_noLint() async {
    await assertNoDiagnostics(r'''
class Ref { bool get mounted => true; }
class State { State copyWith({bool? isResetting}) => this; }
Future<void> f(Ref ref, State state) async {
  try {
    await Future<void>.value();
  } finally {
    if (ref.mounted) state = state.copyWith(isResetting: false);
  }
}
''');
  }

  Future<void> test_returnOutsideFinally_noLint() async {
    await assertNoDiagnostics(r'''
class Ref { bool get mounted => true; }
class State { State copyWith({bool? l}) => this; }
Future<void> f(Ref ref, State state) async {
  try {
    await Future<void>.value();
    if (!ref.mounted) return;
    state = state.copyWith(l: false);
  } finally {
    state = state.copyWith(l: false);
  }
}
''');
  }

  Future<void> test_returnInCatch_noLint() async {
    await assertNoDiagnostics(r'''
class Ref { bool get mounted => true; }
Future<void> f(Ref ref) async {
  try {
    await Future<void>.value();
  } on Exception {
    if (!ref.mounted) return;
  } finally {
    if (ref.mounted) {
      // ok
    }
  }
}
''');
  }

  Future<void> test_nonMountedReturn_inFinally_noLint() async {
    await assertNoDiagnostics(r'''
Future<void> f(bool flag) async {
  try {
    await Future<void>.value();
  } finally {
    if (!flag) {
      // not a mounted check — outside this rule's scope.
    }
  }
}
''');
  }

  Future<void> test_returnWithValue_inFinally_noLint() async {
    // This rule fires only on bare `return;`. A `return value;` with an
    // expression is a different anti-pattern; we leave that to the built-in
    // `control_flow_in_finally` lint.
    await assertNoDiagnostics(r'''
class Ref { bool get mounted => true; }
Future<int> f(Ref ref) async {
  try {
    await Future<void>.value();
    return 1;
  } finally {
    if (!ref.mounted) {
      // no bare return inside this if.
    }
  }
}
''');
  }

  Future<void> test_ifWithElse_inFinally_noLint() async {
    await assertNoDiagnostics(r'''
class Ref { bool get mounted => true; }
Future<void> f(Ref ref) async {
  try {
    await Future<void>.value();
  } finally {
    if (!ref.mounted) {
      return;
    } else {
      // having an else changes semantics — out of scope.
    }
  }
}
''');
  }

  Future<void> test_returnInsideNestedClosure_inFinally_noLint() async {
    await assertNoDiagnostics(r'''
class Ref { bool get mounted => true; }
Future<void> f(Ref ref) async {
  try {
    await Future<void>.value();
  } finally {
    final cb = () {
      if (!ref.mounted) return;
    };
    cb();
  }
}
''');
  }
}
