import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_assignments_as_conditions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_extensions_on_records.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_non_empty_constructor_bodies.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidAssignmentsAsConditionsTest>(
    'AvoidAssignmentsAsConditionsTest',
    AvoidAssignmentsAsConditionsTest.new,
    {
      'test_assignmentInForCondition_lint': (t) => t._assignmentInForConditionLint(),
      'test_assignmentInIfCondition_lint': (t) => t._assignmentInIfConditionLint(),
      'test_assignmentStatement_noLint': (t) => t._assignmentStatementNoLint(),
    },
  );
  analysisRuleSuite<AvoidExtensionsOnRecordsTest>(
    'AvoidExtensionsOnRecordsTest',
    AvoidExtensionsOnRecordsTest.new,
    {
      'test_namedRecordExtension_lint': (t) => t._namedRecordExtensionLint(),
      'test_positionalRecordExtension_lint': (t) => t._positionalRecordExtensionLint(),
      'test_valueTypeExtension_noLint': (t) => t._valueTypeExtensionNoLint(),
    },
  );
  analysisRuleSuite<AvoidNonEmptyConstructorBodiesTest>(
    'AvoidNonEmptyConstructorBodiesTest',
    AvoidNonEmptyConstructorBodiesTest.new,
    {
      'test_emptyConstructorBody_noLint': (t) => t._emptyConstructorBodyNoLint(),
      'test_initializerList_noLint': (t) => t._initializerListNoLint(),
      'test_statementBody_lint': (t) => t._statementBodyLint(),
      'test_freezedFactoryConstructorExpressionBody_noLint': (t) =>
          t._freezedFactoryConstructorExpressionBodyNoLint(),
    },
  );
}

final class AvoidAssignmentsAsConditionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidAssignmentsAsConditions();
    super.setUp();
  }

  Future<void> _assignmentInForConditionLint() async {
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

  Future<void> _assignmentInIfConditionLint() async {
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

  Future<void> _assignmentStatementNoLint() async {
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

final class AvoidExtensionsOnRecordsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidExtensionsOnRecords();
    super.setUp();
  }

  Future<void> _namedRecordExtensionLint() async {
    const source = r'''
extension UserSummary on ({String name, int score}) {
  bool get hasScore => score > 0;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('({String name'), '({String name, int score})'.length),
    ]);
  }

  Future<void> _positionalRecordExtensionLint() async {
    const source = r'''
extension PairMath on (int, int) {
  int get sum => $1 + $2;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(int, int)'), '(int, int)'.length)]);
  }

  Future<void> _valueTypeExtensionNoLint() async {
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

final class AvoidNonEmptyConstructorBodiesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNonEmptyConstructorBodies();
    super.setUp();
  }

  Future<void> _emptyConstructorBodyNoLint() async {
    await assertNoDiagnostics(r'''
class Session {
  Session() {}
}
''');
  }

  Future<void> _initializerListNoLint() async {
    await assertNoDiagnostics(r'''
class Session {
  Session(String id) : normalizedId = id;

  final String normalizedId;
}
''');
  }

  Future<void> _statementBodyLint() async {
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

  Future<void> _freezedFactoryConstructorExpressionBodyNoLint() async {
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
