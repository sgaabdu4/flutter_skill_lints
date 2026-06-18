// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_double_slash_imports.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_enum_values_by_index.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_future_tostring.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_late_keyword.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_multi_assignment.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidDoubleSlashImportsTest);
    defineReflectiveTests(AvoidEnumValuesByIndexTest);
    defineReflectiveTests(AvoidFutureToStringTest);
    defineReflectiveTests(AvoidLateKeywordTest);
    defineReflectiveTests(AvoidMultiAssignmentTest);
  });
}

@reflectiveTest
final class AvoidDoubleSlashImportsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDoubleSlashImports();
    super.setUp();
    newFile('$testPackageLibPath/src/models.dart', '');
  }

  Future<void> test_exportWithDoubleSlash_lint() async {
    const source = r'''
// ignore_for_file: uri_does_not_exist

export 'src//models.dart';
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'src//models.dart'"), "'src//models.dart'".length),
    ]);
  }

  Future<void> test_importWithDoubleSlash_lint() async {
    const source = r'''
// ignore_for_file: uri_does_not_exist

import 'package:app/src//models.dart';
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'package:app"), "'package:app/src//models.dart'".length),
    ]);
  }

  Future<void> test_normalizedImport_noLint() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: unused_import

import 'src/models.dart';
''');
  }
}

@reflectiveTest
final class AvoidEnumValuesByIndexTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidEnumValuesByIndex();
    super.setUp();
  }

  Future<void> test_enumValuesByIndex_lint() async {
    const source = r'''
enum Status { ready, done }

final status = Status.values[0];
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Status.values[0]'), 'Status.values[0]'.length),
    ]);
  }

  Future<void> test_enumValueDirect_noLint() async {
    await assertNoDiagnostics(r'''
enum Status { ready, done }

final status = Status.ready;
''');
  }
}

@reflectiveTest
final class AvoidFutureToStringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidFutureToString();
    super.setUp();
  }

  Future<void> test_futureToString_lint() async {
    const source = r'''
Future<int> load() async => 1;

void f() {
  load().toString();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> test_nonFutureToString_noLint() async {
    await assertNoDiagnostics(r'''
void f(Object value) {
  value.toString();
}
''');
  }
}

@reflectiveTest
final class AvoidLateKeywordTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLateKeyword();
    super.setUp();
  }

  Future<void> test_lateLocal_lint() async {
    const source = r'''
void f() {
  late final int value;
  value = 1;
  print(value);
}
''';
    final path = '$testPackageLibPath/example.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(source.indexOf('late'), 'late'.length)]);
  }

  Future<void> test_eagerLocal_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  final value = 1;
  print(value);
}
''');
  }

  Future<void> test_lateInTestFile_noLint() async {
    const source = r'''
void main() {
  late final int value;
  value = 1;
  print(value);
}
''';
    final path = '$testPackageRootPath/test/example_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_lateFinalStateField_noLint() async {
    const source = r'''
class State<T> {}
class Widget {}

class ExampleState extends State<Widget> {
  late final int value;

  void initState() {
    value = 1;
  }
}
''';
    final path = '$testPackageLibPath/state_field.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_lateFinalConsumerStateField_noLint() async {
    const source = r'''
class ConsumerState<T> {}
class Widget {}

class ExampleState extends ConsumerState<Widget> {
  late final int value;

  void initState() {
    value = 1;
  }
}
''';
    final path = '$testPackageLibPath/consumer_state_field.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_lateMutableStateField_noLint() async {
    const source = r'''
class State<T> {}
class Widget {}

class ExampleState extends State<Widget> {
  late int value;
}
''';
    final path = '$testPackageLibPath/mutable_state_field.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_lateMutableNonStateField_lint() async {
    const source = r'''
class Cache {
  late int value;
}
''';
    final path = '$testPackageLibPath/mutable_non_state_field.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(source.indexOf('late'), 'late'.length)]);
  }
}

@reflectiveTest
final class AvoidMultiAssignmentTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMultiAssignment();
    super.setUp();
  }

  Future<void> test_chainedAssignment_lint() async {
    const source = r'''
void f() {
  var a = 0;
  var b = 0;
  a = b = 1;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('a = b = 1'), 'a = b = 1'.length)]);
  }

  Future<void> test_separateAssignments_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  var a = 0;
  var b = 0;
  b = 1;
  a = b;
}
''');
  }
}
