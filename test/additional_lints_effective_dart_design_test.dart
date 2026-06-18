// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_futureor_return_type.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nullable_async_or_collection_return_type.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_public_late_final_without_initializer.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidFutureOrReturnTypeTest);
    defineReflectiveTests(AvoidNullableAsyncOrCollectionReturnTypeTest);
    defineReflectiveTests(AvoidPublicLateFinalWithoutInitializerTest);
  });
}

@reflectiveTest
class AvoidFutureOrReturnTypeTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidFutureOrReturnType();
    super.setUp();
  }

  Future<void> test_functionReturn_lint() async {
    const source = r'''
import 'dart:async';

FutureOr<int> loadValue() => 1;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('FutureOr<int>'), 'FutureOr<int>'.length),
    ]);
  }

  Future<void> test_methodReturn_lint() async {
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

  Future<void> test_parameter_noLint() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

Future<int> loadValue(FutureOr<int> value) async => await Future<int>.value(1);
''');
  }

  Future<void> test_callbackReturn_noLint() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void observe(FutureOr<void> Function() callback) {}
''');
  }

  Future<void> test_userTypeNamedFutureOr_noLint() async {
    await assertNoDiagnostics(r'''
class FutureOr<T> {
  const FutureOr();
}

FutureOr<int> loadValue() => const FutureOr<int>();
''');
  }
}

@reflectiveTest
class AvoidNullableAsyncOrCollectionReturnTypeTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNullableAsyncOrCollectionReturnType();
    super.setUp();
  }

  Future<void> test_nullableFutureReturn_lint() async {
    const source = r'''
Future<int>? loadValue() => null;
''';

    await assertDiagnostics(source, [lint(source.indexOf('Future<int>?'), 'Future<int>?'.length)]);
  }

  Future<void> test_nullableStreamReturn_lint() async {
    const source = r'''
Stream<int>? streamValues() => null;
''';

    await assertDiagnostics(source, [lint(source.indexOf('Stream<int>?'), 'Stream<int>?'.length)]);
  }

  Future<void> test_nullableCollectionReturn_lint() async {
    const source = r'''
List<int>? loadValues() => null;
''';

    await assertDiagnostics(source, [lint(source.indexOf('List<int>?'), 'List<int>?'.length)]);
  }

  Future<void> test_nestedNullableCollectionReturn_lint() async {
    const source = r'''
Future<List<int>?> loadValues() async => null;
''';

    await assertDiagnostics(source, [lint(source.indexOf('List<int>?'), 'List<int>?'.length)]);
  }

  Future<void> test_nullableValueInsideFuture_noLint() async {
    await assertNoDiagnostics(r'''
Future<int?> loadValue() async => null;
''');
  }

  Future<void> test_nullableElementInsideCollection_noLint() async {
    await assertNoDiagnostics(r'''
List<int?> loadValues() => const <int?>[];
''');
  }

  Future<void> test_parameter_noLint() async {
    await assertNoDiagnostics(r'''
void saveValues(List<int>? values) {}
''');
  }

  Future<void> test_overrideFrameworkSignature_noLint() async {
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

@reflectiveTest
class AvoidPublicLateFinalWithoutInitializerTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidPublicLateFinalWithoutInitializer();
    super.setUp();
  }

  Future<void> test_publicLateFinalField_lint() async {
    const source = r'''
class Cache {
  late final int count;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('count'), 'count'.length)]);
  }

  Future<void> test_privateLateFinalField_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  late final int _count;
}
''');
  }

  Future<void> test_initializedLateFinalField_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  late final int count = 0;
}
''');
  }

  Future<void> test_localLateFinal_noLint() async {
    await assertNoDiagnostics(r'''
void build() {
  late final int count;
  count = 1;
}
''');
  }

  Future<void> test_mutableLateField_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  late int count;
}
''');
  }
}
