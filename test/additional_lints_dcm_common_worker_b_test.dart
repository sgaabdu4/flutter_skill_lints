// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_assignments_as_conditions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_extensions_on_records.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_non_empty_constructor_bodies.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidAssignmentsAsConditionsTest);
    defineReflectiveTests(AvoidExtensionsOnRecordsTest);
    defineReflectiveTests(AvoidNonEmptyConstructorBodiesTest);
  });
}

@reflectiveTest
final class AvoidAssignmentsAsConditionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidAssignmentsAsConditions();
    super.setUp();
  }

  Future<void> test_assignmentInForCondition_lint() async {
    const source = r'''
void f() {
  var keepGoing = true;
  for (; keepGoing = false;) {}
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('keepGoing = false'), 'keepGoing = false'.length),
    ]);
  }

  Future<void> test_assignmentInIfCondition_lint() async {
    const source = r'''
void f() {
  var ready = false;
  if (ready = true) {
    print(ready);
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('ready = true'), 'ready = true'.length)]);
  }

  Future<void> test_assignmentStatement_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  var ready = false;
  ready = true;
  if (ready) {
    print(ready);
  }
}
''');
  }
}

@reflectiveTest
final class AvoidExtensionsOnRecordsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidExtensionsOnRecords();
    super.setUp();
  }

  Future<void> test_namedRecordExtension_lint() async {
    const source = r'''
extension UserSummary on ({String name, int score}) {
  bool get hasScore => score > 0;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('({String name'), '({String name, int score})'.length),
    ]);
  }

  Future<void> test_positionalRecordExtension_lint() async {
    const source = r'''
extension PairMath on (int, int) {
  int get sum => $1 + $2;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(int, int)'), '(int, int)'.length)]);
  }

  Future<void> test_valueTypeExtension_noLint() async {
    await assertNoDiagnostics(r'''
class Pair {
  const Pair(this.left, this.right);

  final int left;
  final int right;
}

extension PairMath on Pair {
  int get sum => left + right;
}
''');
  }
}

@reflectiveTest
final class AvoidNonEmptyConstructorBodiesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNonEmptyConstructorBodies();
    super.setUp();
  }

  Future<void> test_emptyConstructorBody_noLint() async {
    await assertNoDiagnostics(r'''
class Session {
  Session() {}
}
''');
  }

  Future<void> test_initializerList_noLint() async {
    await assertNoDiagnostics(r'''
class Session {
  Session(String id) : normalizedId = id;

  final String normalizedId;
}
''');
  }

  Future<void> test_statementBody_lint() async {
    const source = r'''
class Session {
  Session(String id) {
    normalizedId = id;
  }

  late final String normalizedId;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('{\n    normalizedId'), '{\n    normalizedId = id;\n  }'.length),
    ]);
  }

  Future<void> test_freezedFactoryConstructorExpressionBody_noLint() async {
    await assertNoDiagnostics(r'''
class Freezed {
  const Freezed();
}

const freezed = Freezed();

@freezed
class ExerciseModel {
  factory ExerciseModel.fromRow(Map<String, Object?> row) {
    return _ExerciseModel(row['id'].toString());
  }
}

class _ExerciseModel implements ExerciseModel {
  const _ExerciseModel(this.id);

  final String id;
}
''');
  }
}
