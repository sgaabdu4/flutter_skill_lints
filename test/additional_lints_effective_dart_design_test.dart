import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_futureor_return_type.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nullable_async_or_collection_return_type.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_public_late_final_without_initializer.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidFutureOrReturnTypeTest>(
    'AvoidFutureOrReturnTypeTest',
    _AvoidFutureOrReturnTypeTest.new,
    _AvoidFutureOrReturnTypeTest._allCases,
  );
  analysisRuleSuite<_AvoidNullableAsyncOrCollectionReturnTypeTest>(
    'AvoidNullableAsyncOrCollectionReturnTypeTest',
    _AvoidNullableAsyncOrCollectionReturnTypeTest.new,
    _AvoidNullableAsyncOrCollectionReturnTypeTest._allCases,
  );
  analysisRuleSuite<_AvoidPublicLateFinalWithoutInitializerTest>(
    'AvoidPublicLateFinalWithoutInitializerTest',
    _AvoidPublicLateFinalWithoutInitializerTest.new,
    _AvoidPublicLateFinalWithoutInitializerTest._allCases,
  );
}

class _AvoidFutureOrReturnTypeTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidFutureOrReturnTypeTest)> get _allCases =>
      caseSet<_AvoidFutureOrReturnTypeTest>(
        parent: const {},
        own: {
          'test_functionReturn_lint': (t) => t._functionReturnLint(),
          'test_methodReturn_lint': (t) => t._methodReturnLint(),
          'test_parameter_noLint': (t) => t._parameterNoLint(),
          'test_callbackReturn_noLint': (t) => t._callbackReturnNoLint(),
          'test_userTypeNamedFutureOr_noLint': (t) => t._userTypeNamedFutureOrNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidFutureOrReturnType();
    super.setUp();
  }

  Future<void> _functionReturnLint() async {
    const source = r'''
import 'dart:async';

FutureOr<int> loadValue() => 1;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('FutureOr<int>'), 'FutureOr<int>'.length),
    ]);
  }

  Future<void> _methodReturnLint() async {
    const source = r'''
import 'dart:async';

class Repository {
  FutureOr<String> loadName() => 'name';
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('FutureOr<String>'), 'FutureOr<String>'.length),
    ]);
  }

  Future<void> _parameterNoLint() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

Future<int> loadValue(FutureOr<int> value) async => await Future<int>.value(1);
''');
  }

  Future<void> _callbackReturnNoLint() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void observe(FutureOr<void> Function() callback) {}
''');
  }

  Future<void> _userTypeNamedFutureOrNoLint() async {
    await assertNoDiagnostics(r'''
class FutureOr<T> {
  const FutureOr();
}

FutureOr<int> loadValue() => const FutureOr<int>();
''');
  }
}

class _AvoidNullableAsyncOrCollectionReturnTypeTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidNullableAsyncOrCollectionReturnTypeTest)>
  get _allCases => caseSet<_AvoidNullableAsyncOrCollectionReturnTypeTest>(
    parent: const {},
    own: {
      'test_nullableFutureReturn_lint': (t) => t._nullableFutureReturnLint(),
      'test_nullableStreamReturn_lint': (t) => t._nullableStreamReturnLint(),
      'test_nullableCollectionReturn_lint': (t) => t._nullableCollectionReturnLint(),
      'test_nestedNullableCollectionReturn_lint': (t) => t._nestedNullableCollectionReturnLint(),
      'test_nullableValueInsideFuture_noLint': (t) => t._nullableValueInsideFutureNoLint(),
      'test_nullableElementInsideCollection_noLint': (t) =>
          t._nullableElementInsideCollectionNoLint(),
      'test_parameter_noLint': (t) => t._parameterNoLint(),
      'test_overrideFrameworkSignature_noLint': (t) => t._overrideFrameworkSignatureNoLint(),
    },
  );

  @override
  void setUp() {
    rule = AvoidNullableAsyncOrCollectionReturnType();
    super.setUp();
  }

  Future<void> _nullableFutureReturnLint() async {
    const source = r'''
Future<int>? loadValue() => null;
''';

    await assertDiagnostics(source, [lint(source.indexOf('Future<int>?'), 'Future<int>?'.length)]);
  }

  Future<void> _nullableStreamReturnLint() async {
    const source = r'''
Stream<int>? streamValues() => null;
''';

    await assertDiagnostics(source, [lint(source.indexOf('Stream<int>?'), 'Stream<int>?'.length)]);
  }

  Future<void> _nullableCollectionReturnLint() async {
    const source = r'''
List<int>? loadValues() => null;
''';

    await assertDiagnostics(source, [lint(source.indexOf('List<int>?'), 'List<int>?'.length)]);
  }

  Future<void> _nestedNullableCollectionReturnLint() async {
    const source = r'''
Future<List<int>?> loadValues() async => null;
''';

    await assertDiagnostics(source, [lint(source.indexOf('List<int>?'), 'List<int>?'.length)]);
  }

  Future<void> _nullableValueInsideFutureNoLint() async {
    await assertNoDiagnostics(r'''
Future<int?> loadValue() async => null;
''');
  }

  Future<void> _nullableElementInsideCollectionNoLint() async {
    await assertNoDiagnostics(r'''
List<int?> loadValues() => const <int?>[];
''');
  }

  Future<void> _parameterNoLint() async {
    await assertNoDiagnostics(r'''
void saveValues(List<int>? values) {}
''');
  }

  Future<void> _overrideFrameworkSignatureNoLint() async {
    await assertNoDiagnostics(r'''
abstract class Headers {
  // ignore: avoid_nullable_async_or_collection_return_type
  List<String>? operator [](String name);
}

class FakeHeaders implements Headers {
  @override
  List<String>? operator [](String name) => null;
}
''');
  }
}

class _AvoidPublicLateFinalWithoutInitializerTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidPublicLateFinalWithoutInitializerTest)>
  get _allCases => caseSet<_AvoidPublicLateFinalWithoutInitializerTest>(
    parent: const {},
    own: {
      'test_publicLateFinalField_lint': (t) => t._publicLateFinalFieldLint(),
      'test_privateLateFinalField_noLint': (t) => t._privateLateFinalFieldNoLint(),
      'test_initializedLateFinalField_noLint': (t) => t._initializedLateFinalFieldNoLint(),
      'test_localLateFinal_noLint': (t) => t._localLateFinalNoLint(),
      'test_mutableLateField_noLint': (t) => t._mutableLateFieldNoLint(),
    },
  );

  @override
  void setUp() {
    rule = AvoidPublicLateFinalWithoutInitializer();
    super.setUp();
  }

  Future<void> _publicLateFinalFieldLint() async {
    const source = r'''
class Cache {
  late final int count;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('count'), 'count'.length)]);
  }

  Future<void> _privateLateFinalFieldNoLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  late final int _count;
}
''');
  }

  Future<void> _initializedLateFinalFieldNoLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  late final int count = 0;
}
''');
  }

  Future<void> _localLateFinalNoLint() async {
    await assertNoDiagnostics(r'''
void build() {
  late final int count;
  count = 1;
}
''');
  }

  Future<void> _mutableLateFieldNoLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  late int count;
}
''');
  }
}
