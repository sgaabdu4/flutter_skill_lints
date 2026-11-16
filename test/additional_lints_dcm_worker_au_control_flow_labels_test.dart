import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_continue.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_labels.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_local_functions.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidContinueTest>(
    'AvoidContinueTest',
    _AvoidContinueTest.new,
    _AvoidContinueTest._allCases,
  );
  analysisRuleSuite<_AvoidLabelsTest>(
    'AvoidLabelsTest',
    _AvoidLabelsTest.new,
    _AvoidLabelsTest._allCases,
  );
  analysisRuleSuite<_AvoidLocalFunctionsTest>(
    'AvoidLocalFunctionsTest',
    _AvoidLocalFunctionsTest.new,
    _AvoidLocalFunctionsTest._allCases,
  );
}

final class _AvoidContinueTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidContinueTest)> get _allCases =>
      caseSet<_AvoidContinueTest>(
        parent: const {},
        own: {
          'test_continueStatement_lint': (t) => t._continueStatementLint(),
          'test_loopWithoutContinue_noLint': (t) => t._loopWithoutContinueNoLint(),
          'test_severity_info': (t) => t._severityInfo(),
        },
      );

  @override
  void setUp() {
    rule = AvoidContinue();
    super.setUp();
  }

  Future<void> _continueStatementLint() async {
    const source = r'''
void f(List<int> values) {
  for (final value in values) {
    if (value.isEven) continue;
    print(value);
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('continue'), 'continue'.length)]);
  }

  Future<void> _loopWithoutContinueNoLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> values) {
  for (final value in values) {
    if (value.isOdd) {
      print(value);
    }
  }
}
''');
  }

  Future<void> _severityInfo() async {
    expect(AvoidContinue.code.severity, DiagnosticSeverity.INFO);
  }
}

final class _AvoidLabelsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidLabelsTest)> get _allCases =>
      caseSet<_AvoidLabelsTest>(
        parent: const {},
        own: {
          'test_labeledStatement_lint': (t) => t._labeledStatementLint(),
          'test_labeledBreak_lint': (t) => t._labeledBreakLint(),
          'test_labeledContinue_lint': (t) => t._labeledContinueLint(),
          'test_unlabeledBreakAndContinue_noLint': (t) => t._unlabeledBreakAndContinueNoLint(),
          'test_severity_error': (t) => t._severityError(),
        },
      );

  @override
  void setUp() {
    rule = AvoidLabels();
    super.setUp();
  }

  Future<void> _labeledStatementLint() async {
    const source = r'''
void f() {
  retry:
  for (var i = 0; i < 2; i++) {
    if (i.isEven) {
      break retry;
    }
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('retry:'), 'retry:'.length)]);
  }

  Future<void> _labeledBreakLint() async {
    const source = r'''
void f() {
  outer:
  for (var i = 0; i < 2; i++) {
    for (var j = 0; j < 2; j++) {
      if (j == i) {
        break outer;
      }
    }
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('outer:'), 'outer:'.length)]);
  }

  Future<void> _labeledContinueLint() async {
    const source = r'''
void f() {
  outer:
  for (var i = 0; i < 2; i++) {
    for (var j = 0; j < 2; j++) {
      if (j == i) {
        continue outer;
      }
    }
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('outer:'), 'outer:'.length)]);
  }

  Future<void> _unlabeledBreakAndContinueNoLint() async {
    await assertNoDiagnostics(r'''
void f(List<int> values) {
  for (final value in values) {
    if (value.isNegative) break;
    if (value.isEven) continue;
    print(value);
  }
}
''');
  }

  Future<void> _severityError() async {
    expect(AvoidLabels.code.severity, DiagnosticSeverity.ERROR);
  }
}

final class _AvoidLocalFunctionsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidLocalFunctionsTest)> get _allCases =>
      caseSet<_AvoidLocalFunctionsTest>(
        parent: const {},
        own: {
          'test_localFunction_lint': (t) => t._localFunctionLint(),
          'test_topLevelFunction_noLint': (t) => t._topLevelFunctionNoLint(),
          'test_anonymousFunction_noLint': (t) => t._anonymousFunctionNoLint(),
          'test_identityGuardedCallback_noLint': (t) => t._identityGuardedCallbackNoLint(),
          'test_invertedIdentityGuard_lint': (t) => t._invertedIdentityGuardLint(),
          'test_parenthesizedConjunctiveIdentityGuard_noLint': (t) =>
              t._parenthesizedConjunctiveIdentityGuardNoLint(),
          'test_effectfulConjunctiveIdentityGuard_lint': (t) =>
              t._effectfulConjunctiveIdentityGuardLint(),
          'test_effectfulStatementBeforeCleanup_lint': (t) =>
              t._effectfulStatementBeforeCleanupLint(),
          'test_disjunctiveIdentityGuard_lint': (t) => t._disjunctiveIdentityGuardLint(),
          'test_coreIdenticalGuard_noLint': (t) => t._coreIdenticalGuardNoLint(),
          'test_staticAndNestedInstanceCallbackSlots_noLint': (t) =>
              t._staticAndNestedInstanceCallbackSlotsNoLint(),
          'test_callbackWithoutCleanupIdentity_lint': (t) =>
              t._callbackWithoutCleanupIdentityLint(),
          'test_comparisonOutsideCleanup_lint': (t) => t._comparisonOutsideCleanupLint(),
          'test_cleanupChecksDifferentSlot_lint': (t) => t._cleanupChecksDifferentSlotLint(),
          'test_cleanupChecksDifferentReceiver_lint': (t) =>
              t._cleanupChecksDifferentReceiverLint(),
          'test_identityComparisonWithoutCleanupWrite_lint': (t) =>
              t._identityComparisonWithoutCleanupWriteLint(),
          'test_identityGuardWithNoOpSlotWrite_lint': (t) =>
              t._identityGuardWithNoOpSlotWriteLint(),
          'test_identityGuardWithUnrelatedConditionalWrite_lint': (t) =>
              t._identityGuardWithUnrelatedConditionalWriteLint(),
          'test_shadowedCallbackName_lint': (t) => t._shadowedCallbackNameLint(),
          'test_unrelatedIdenticalMethod_lint': (t) => t._unrelatedIdenticalMethodLint(),
          'test_severity_info': (t) => t._severityInfo(),
        },
      );

  @override
  void setUp() {
    rule = AvoidLocalFunctions();
    super.setUp();
  }

  Future<void> _localFunctionLint() async {
    const source = r'''
void f() {
  int local(int value) => value + 1;
  print(local(1));
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('local'), 'local'.length)]);
  }

  Future<void> _topLevelFunctionNoLint() async {
    await assertNoDiagnostics(r'''
int helper(int value) => value + 1;

void f() {
  print(helper(1));
}
''');
  }

  Future<void> _anonymousFunctionNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  final values = [1, 2, 3].map((value) => value + 1);
  print(values);
}
''');
  }

  Future<void> _identityGuardedCallbackNoLint() async {
    await assertNoDiagnostics(r'''
typedef Handler = void Function(Object error);

class Registry {
  Handler? current;

  Handler install() {
    final previous = current;
    void handle(Object error) {}
    current = handle;
    return (_) {
      if (current == handle) current = previous;
    };
  }
}
''');
  }

  Future<void> _invertedIdentityGuardLint() async {
    const source = r'''
typedef Handler = void Function(Object error);
class Registry {
  Handler? current;
  Handler install() {
    void handle(Object error) {}
    current = handle;
    return (_) {
      if (current != handle) current = null;
    };
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('handle(Object'), 'handle'.length)]);
  }

  Future<void> _parenthesizedConjunctiveIdentityGuardNoLint() async {
    await assertNoDiagnostics(r'''
typedef Handler = void Function(Object error);
class Registry {
  Handler? current;
  Handler install(bool mounted) {
    void handle(Object error) {}
    current = handle;
    return (_) {
      if ((identical(current, handle)) && mounted) current = null;
    };
  }
}
''');
  }

  Future<void> _effectfulConjunctiveIdentityGuardLint() async {
    const source = r'''
typedef Handler = void Function(Object error);
class Registry {
  Handler? current;
  bool replaceAndPermit() {
    current = (error) {};
    return true;
  }
  Handler install() {
    void handle(Object error) {}
    current = handle;
    return (_) {
      if (current == handle && replaceAndPermit()) current = null;
    };
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('handle(Object'), 'handle'.length)]);
  }

  Future<void> _effectfulStatementBeforeCleanupLint() async {
    const source = r'''
typedef Handler = void Function(Object error);
class Registry {
  Handler? current;
  void replace() { current = (error) {}; }
  Handler install() {
    void handle(Object error) {}
    current = handle;
    return (_) {
      if (current == handle) {
        replace();
        current = null;
      }
    };
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('handle(Object'), 'handle'.length)]);
  }

  Future<void> _disjunctiveIdentityGuardLint() async {
    const source = r'''
typedef Handler = void Function(Object error);
class Registry {
  Handler? current;
  Handler install(bool force) {
    void handle(Object error) {}
    current = handle;
    return (_) {
      if (current == handle || force) current = null;
    };
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('handle(Object'), 'handle'.length)]);
  }

  Future<void> _coreIdenticalGuardNoLint() async {
    await assertNoDiagnostics(r'''
typedef Handler = void Function(Object error);

class Registry {
  Handler? current;

  Handler install() {
    final previous = current;
    void handle(Object error) {}
    current = handle;
    return (_) {
      if (identical(current, handle)) current = previous;
    };
  }
}
''');
  }

  Future<void> _staticAndNestedInstanceCallbackSlotsNoLint() async {
    await assertNoDiagnostics(r'''
typedef Handler = void Function(Object error);

class GlobalHandler {
  static Handler? current;
}

class Dispatcher {
  static final Dispatcher instance = Dispatcher();
  Handler? current;
}

Handler install() {
  final previousGlobal = GlobalHandler.current;
  final previousInstance = Dispatcher.instance.current;
  void handleGlobal(Object error) {}
  void handleInstance(Object error) {}
  GlobalHandler.current = handleGlobal;
  Dispatcher.instance.current = handleInstance;
  return (_) {
    if (GlobalHandler.current == handleGlobal) {
      GlobalHandler.current = previousGlobal;
    }
    if (Dispatcher.instance.current == handleInstance) {
      Dispatcher.instance.current = previousInstance;
    }
  };
}
''');
  }

  Future<void> _callbackWithoutCleanupIdentityLint() async {
    const source = r'''
typedef Handler = void Function(Object error);

void register(Handler handler) {}

void install() {
  void handle(Object error) {}
  register(handle);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('handle(Object'), 'handle'.length)]);
  }

  Future<void> _comparisonOutsideCleanupLint() async {
    const source = r'''
typedef Handler = void Function(Object error);

class Registry {
  Handler? current;

  void install() {
    void handle(Object error) {}
    current = handle;
    if (current == handle) current = null;
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('handle(Object'), 'handle'.length)]);
  }

  Future<void> _cleanupChecksDifferentSlotLint() async {
    const source = r'''
typedef Handler = void Function(Object error);

class Registry {
  Handler? current;
  Handler? unrelated;

  Handler install() {
    void handle(Object error) {}
    current = handle;
    return (_) {
      if (unrelated == handle) unrelated = null;
    };
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('handle(Object'), 'handle'.length)]);
  }

  Future<void> _cleanupChecksDifferentReceiverLint() async {
    const source = r'''
typedef Handler = void Function(Object error);

class Registry {
  Handler? current;
}

Handler install(Registry first, Registry second) {
  void handle(Object error) {}
  first.current = handle;
  return (_) {
    if (second.current == handle) second.current = null;
  };
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('handle(Object'), 'handle'.length)]);
  }

  Future<void> _identityComparisonWithoutCleanupWriteLint() async {
    const source = r'''
typedef Handler = void Function(Object error);

class Registry {
  Handler? current;

  Handler install() {
    void handle(Object error) {}
    current = handle;
    return (_) {
      if (current == handle) print('still installed');
    };
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('handle(Object'), 'handle'.length)]);
  }

  Future<void> _identityGuardWithNoOpSlotWriteLint() async {
    const source = r'''
typedef Handler = void Function(Object error);

class Registry {
  Handler? current;

  Handler install() {
    void handle(Object error) {}
    current = handle;
    return (_) {
      if (current == handle) current = handle;
    };
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('handle(Object'), 'handle'.length)]);
  }

  Future<void> _identityGuardWithUnrelatedConditionalWriteLint() async {
    const source = r'''
typedef Handler = void Function(Object error);

class Registry {
  Handler? current;

  Handler install(bool clear) {
    final previous = current;
    void handle(Object error) {}
    current = handle;
    return (_) {
      if (current == handle) print('still installed');
      if (clear) current = previous;
    };
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('handle(Object'), 'handle'.length)]);
  }

  Future<void> _shadowedCallbackNameLint() async {
    const source = r'''
typedef Handler = void Function(Object error);

class Registry {
  Handler? current;

  Handler install() {
    void handle(Object error) {}
    current = handle;
    return (_) {
      final Handler handle = (error) {};
      if (current == handle) current = null;
    };
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('handle(Object'), 'handle'.length)]);
  }

  Future<void> _unrelatedIdenticalMethodLint() async {
    const source = r'''
typedef Handler = void Function(Object error);

class Checker {
  bool identical(Object? first, Object? second) => first == second;
}

class Registry {
  Handler? current;
  final Checker checker = Checker();

  Handler install() {
    void handle(Object error) {}
    current = handle;
    return (_) {
      if (checker.identical(current, handle)) current = null;
    };
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('handle(Object'), 'handle'.length)]);
  }

  Future<void> _severityInfo() async {
    expect(AvoidLocalFunctions.code.severity, DiagnosticSeverity.INFO);
  }
}
