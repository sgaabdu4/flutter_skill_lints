// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_continue.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_labels.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_local_functions.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidContinueTest);
    defineReflectiveTests(AvoidLabelsTest);
    defineReflectiveTests(AvoidLocalFunctionsTest);
  });
}

@reflectiveTest
final class AvoidContinueTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidContinue();
    super.setUp();
  }

  Future<void> test_continueStatement_lint() async {
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

  Future<void> test_loopWithoutContinue_noLint() async {
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

  Future<void> test_severity_info() async {
    expect(AvoidContinue.code.severity, DiagnosticSeverity.INFO);
  }
}

@reflectiveTest
final class AvoidLabelsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLabels();
    super.setUp();
  }

  Future<void> test_labeledStatement_lint() async {
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

  Future<void> test_labeledBreak_lint() async {
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

  Future<void> test_labeledContinue_lint() async {
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

  Future<void> test_unlabeledBreakAndContinue_noLint() async {
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

  Future<void> test_severity_error() async {
    expect(AvoidLabels.code.severity, DiagnosticSeverity.ERROR);
  }
}

@reflectiveTest
final class AvoidLocalFunctionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLocalFunctions();
    super.setUp();
  }

  Future<void> test_localFunction_lint() async {
    const source = r'''
void f() {
  int local(int value) => value + 1;
  print(local(1));
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('local'), 'local'.length)]);
  }

  Future<void> test_topLevelFunction_noLint() async {
    await assertNoDiagnostics(r'''
int helper(int value) => value + 1;

void f() {
  print(helper(1));
}
''');
  }

  Future<void> test_anonymousFunction_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  final values = [1, 2, 3].map((value) => value + 1);
  print(values);
}
''');
  }

  Future<void> test_identityGuardedCallback_noLint() async {
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

  Future<void> test_invertedIdentityGuard_lint() async {
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

  Future<void> test_parenthesizedConjunctiveIdentityGuard_noLint() async {
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

  Future<void> test_effectfulConjunctiveIdentityGuard_lint() async {
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

  Future<void> test_effectfulStatementBeforeCleanup_lint() async {
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

  Future<void> test_disjunctiveIdentityGuard_lint() async {
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

  Future<void> test_coreIdenticalGuard_noLint() async {
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

  Future<void> test_staticAndNestedInstanceCallbackSlots_noLint() async {
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

  Future<void> test_callbackWithoutCleanupIdentity_lint() async {
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

  Future<void> test_comparisonOutsideCleanup_lint() async {
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

  Future<void> test_cleanupChecksDifferentSlot_lint() async {
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

  Future<void> test_cleanupChecksDifferentReceiver_lint() async {
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

  Future<void> test_identityComparisonWithoutCleanupWrite_lint() async {
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

  Future<void> test_identityGuardWithNoOpSlotWrite_lint() async {
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

  Future<void> test_identityGuardWithUnrelatedConditionalWrite_lint() async {
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

  Future<void> test_shadowedCallbackName_lint() async {
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

  Future<void> test_unrelatedIdenticalMethod_lint() async {
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

  Future<void> test_severity_info() async {
    expect(AvoidLocalFunctions.code.severity, DiagnosticSeverity.INFO);
  }
}
