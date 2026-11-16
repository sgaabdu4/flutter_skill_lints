import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_mounted_check_in_finally.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidMountedCheckInFinallyTest>(
    'AvoidMountedCheckInFinallyTest',
    _AvoidMountedCheckInFinallyTest.new,
    _AvoidMountedCheckInFinallyTest._allCases,
  );
}

class _AvoidMountedCheckInFinallyTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidMountedCheckInFinallyTest)> get _allCases =>
      caseSet<_AvoidMountedCheckInFinallyTest>(
        parent: const {},
        own: {
          'test_refMountedReturn_inFinally_lint': (t) => t._refMountedReturnInFinallyLint(),
          'test_contextMountedReturn_inFinally_lint': (t) => t._contextMountedReturnInFinallyLint(),
          'test_bareMountedReturn_inFinally_lint': (t) => t._bareMountedReturnInFinallyLint(),
          'test_returnInBlock_inFinally_lint': (t) => t._returnInBlockInFinallyLint(),
          'test_guardForm_inFinally_noLint': (t) => t._guardFormInFinallyNoLint(),
          'test_singleLineGuard_inFinally_noLint': (t) => t._singleLineGuardInFinallyNoLint(),
          'test_returnOutsideFinally_noLint': (t) => t._returnOutsideFinallyNoLint(),
          'test_returnInCatch_noLint': (t) => t._returnInCatchNoLint(),
          'test_nonMountedReturn_inFinally_noLint': (t) => t._nonMountedReturnInFinallyNoLint(),
          'test_returnWithValue_inFinally_noLint': (t) => t._returnWithValueInFinallyNoLint(),
          'test_ifWithElse_inFinally_noLint': (t) => t._ifWithElseInFinallyNoLint(),
          'test_returnInsideNestedClosure_inFinally_noLint': (t) =>
              t._returnInsideNestedClosureInFinallyNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidMountedCheckInFinally();
    super.setUp();
  }

  Future<void> _refMountedReturnInFinallyLint() async {
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

  Future<void> _contextMountedReturnInFinallyLint() async {
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

  Future<void> _bareMountedReturnInFinallyLint() async {
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

  Future<void> _returnInBlockInFinallyLint() async {
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

  Future<void> _guardFormInFinallyNoLint() async {
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

  Future<void> _singleLineGuardInFinallyNoLint() async {
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

  Future<void> _returnOutsideFinallyNoLint() async {
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

  Future<void> _returnInCatchNoLint() async {
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

  Future<void> _nonMountedReturnInFinallyNoLint() async {
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

  Future<void> _returnWithValueInFinallyNoLint() async {
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

  Future<void> _ifWithElseInFinallyNoLint() async {
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

  Future<void> _returnInsideNestedClosureInFinallyNoLint() async {
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
