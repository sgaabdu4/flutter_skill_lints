// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_slow_collection_methods.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unsafe_collection_methods.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unsafe_reduce.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

const _iterableCore = r'''
extension IterableSafetyTestX<T> on Iterable<T> {
  T reduce(T Function(T, T) combine) => throw 'empty';
  T get first => throw 'empty';
  T get single => throw 'empty';
  bool any(bool Function(T) test) => false;
  Iterable<T> where(bool Function(T) test) => this;
}

''';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidUnsafeReduceTest);
    defineReflectiveTests(AvoidUnsafeCollectionMethodsTest);
    defineReflectiveTests(AvoidSlowCollectionMethodsTest);
  });
}

@reflectiveTest
final class AvoidUnsafeReduceTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnsafeReduce();
    super.setUp();
  }

  Future<void> test_emptyLiteral_lint() async {
    const source =
        _iterableCore +
        r'''
void f() {
  <int>[].reduce((a, b) => a + b);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('<int>[].reduce'), '<int>[].reduce((a, b) => a + b)'.length),
    ]);
  }

  Future<void> test_guardedByEmptyEarlyReturn_noLint() async {
    await assertNoDiagnostics(
      _iterableCore +
          r'''
int f(List<int> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a + b);
}
''',
    );
  }

  Future<void> test_guardedByIfCondition_noLint() async {
    await assertNoDiagnostics(
      _iterableCore +
          r'''
int f(List<int> values) {
  if (values.isNotEmpty) {
    return values.reduce((a, b) => a + b);
  }
  return 0;
}
''',
    );
  }

  Future<void> test_iterableWithoutGuard_lint() async {
    const source =
        _iterableCore +
        r'''
int f(Iterable<int> values) {
  return values.reduce((a, b) => a + b);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('values.reduce'), 'values.reduce((a, b) => a + b)'.length),
    ]);
  }

  Future<void> test_severity_info() async {
    expect(AvoidUnsafeReduce.code.severity, DiagnosticSeverity.INFO);
  }
}

@reflectiveTest
final class AvoidUnsafeCollectionMethodsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnsafeCollectionMethods();
    newPackage('test_api')
        .addFile('lib/expect.dart', 'void expect(Object? actual, Object? matcher) {}');
    newPackage('matcher').addFile('lib/matcher.dart', 'Object hasLength(int length) => Object();');
    newPackage('flutter_test').addFile('lib/flutter_test.dart', r'''
export 'package:test_api/expect.dart';
export 'package:matcher/matcher.dart';
''');
    super.setUp();
  }

  Future<void> test_adjacentResolvedLengthAssertionProvesFirstAndSingle() async {
    await assertNoDiagnostics(
      r'''
import 'package:flutter_test/flutter_test.dart';
''' +
          _iterableCore +
          r'''
void f(List<int> values) {
  expect(values, hasLength(1));
  expect(values.first, 1);
  expect(values, hasLength(1));
  expect(values.single, 1);
}
''',
    );
  }

  Future<void> test_mutationAliasAwaitAndUnrelatedExpectInvalidateLengthProof() async {
    const source =
        r'''
import 'package:flutter_test/flutter_test.dart';
''' +
        _iterableCore +
        r'''
void mutated(List<int> values) {
  expect(values, hasLength(1));
  values.clear();
  print(values.first);
}
void aliased(List<int> values) {
  final alias = values;
  expect(values, hasLength(1));
  alias.clear();
  print(values.first);
}
Future<void> delayed(List<int> values) async {
  expect(values, hasLength(1));
  await Future<void>.value();
  print(values.first);
}
void unrelated(List<int> values) {
  void expect(Object? actual, Object? matcher) {}
  expect(values, hasLength(1));
  print(values.first);
}
void unproven(List<int> values) { print(values.first); }
void sameStatementSideEffect(List<int> values) {
  expect(values, hasLength(1));
  consume(clearAndReturn(values), values.first);
}
Object? clearAndReturn(List<int> values) { values.clear(); return null; }
void consume(Object? first, Object? second) {}
int Function() deferred(List<int> values) {
  expect(values, hasLength(1));
  return () => values.first;
}
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('values.first', source.indexOf('void mutated')), 'values.first'.length),
      lint(source.indexOf('values.first', source.indexOf('void aliased')), 'values.first'.length),
      lint(
        source.indexOf('values.first', source.indexOf('Future<void> delayed')),
        'values.first'.length,
      ),
      lint(source.indexOf('values.first', source.indexOf('void unrelated')), 'values.first'.length),
      lint(source.indexOf('values.first', source.indexOf('void unproven')), 'values.first'.length),
      lint(
        source.indexOf('values.first', source.indexOf('void sameStatementSideEffect')),
        'values.first'.length,
      ),
      lint(
        source.indexOf('values.first', source.indexOf('int Function() deferred')),
        'values.first'.length,
      ),
    ]);
  }

  Future<void> test_emptyLiteralFirst_lint() async {
    const source =
        _iterableCore +
        r'''
void f() {
  print(<int>[].first);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('<int>[].first'), '<int>[].first'.length),
    ]);
  }

  Future<void> test_guardedSingle_noLint() async {
    await assertNoDiagnostics(
      _iterableCore +
          r'''
int f(List<int> values) {
  if (values.isEmpty) throw 'empty';
  return values.single;
}
''',
    );
  }

  Future<void> test_testFileFirstAndSingle_noLint() async {
    final path = '$testPackageRootPath/test/products_test.dart';
    newFile(
      path,
      r'''
import 'package:flutter_test/flutter_test.dart';
''' +
          _iterableCore +
          r'''
void main() {
  final items = <String>['New'];
  expect(items.first, 'New');
  expect(items.single, 'New');
}
''',
    );

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_productionToStringFirst_lint() async {
    const source =
        _iterableCore +
        r'''
class SaveAllRowsException {
  const SaveAllRowsException(this.failures);
  final List<Object> failures;

  @override
  String toString() => 'SaveAllRowsException: first=${failures.first}';
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('failures.first'), 'failures.first'.length),
    ]);
  }

  Future<void> test_iterableFirstWithoutGuard_lint() async {
    const source =
        _iterableCore +
        r'''
int f(Iterable<int> values) {
  return values.first;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('values.first'), 'values.first'.length)]);
  }

  Future<void> test_iterableSingleWithoutGuard_lint() async {
    const source =
        _iterableCore +
        r'''
int f(Iterable<int> values) {
  return values.single;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('values.single'), 'values.single'.length),
    ]);
  }

  Future<void> test_lengthCheck_keptConservative_lint() async {
    const source =
        _iterableCore +
        r'''
int f(List<int> values) {
  if (values.length == 1) {
    return values.single;
  }
  return 0;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('values.single'), 'values.single'.length),
    ]);
  }

  Future<void> test_severity_info() async {
    expect(AvoidUnsafeCollectionMethods.code.severity, DiagnosticSeverity.INFO);
  }
}

@reflectiveTest
final class AvoidSlowCollectionMethodsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidSlowCollectionMethods();
    super.setUp();
  }

  Future<void> test_whereIsEmpty_lint() async {
    const source =
        _iterableCore +
        r'''
bool f(List<int> values) {
  return values.where((value) => value.isEven).isEmpty;
}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('values.where((value) => value.isEven).isEmpty'),
        'values.where((value) => value.isEven).isEmpty'.length,
      ),
    ]);
  }

  Future<void> test_whereIsNotEmpty_lint() async {
    const source =
        _iterableCore +
        r'''
bool f(List<int> values) {
  return values.where((value) => value.isEven).isNotEmpty;
}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('values.where((value) => value.isEven).isNotEmpty'),
        'values.where((value) => value.isEven).isNotEmpty'.length,
      ),
    ]);
  }

  Future<void> test_directAny_noLint() async {
    await assertNoDiagnostics(
      _iterableCore +
          r'''
bool f(List<int> values) {
  return values.any((value) => value.isEven);
}
''',
    );
  }

  Future<void> test_severity_info() async {
    expect(AvoidSlowCollectionMethods.code.severity, DiagnosticSeverity.INFO);
  }
}
