// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_parameter_aliases.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_repeated_property_aliases.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unassigned_local_variable.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unused_assignment.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unused_local_variable.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_type_over_var.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidUnusedAssignmentTest);
    defineReflectiveTests(AvoidParameterAliasesTest);
    defineReflectiveTests(AvoidRepeatedPropertyAliasesTest);
    defineReflectiveTests(AvoidUnassignedLocalVariableTest);
    defineReflectiveTests(AvoidUnusedLocalVariableTest);
    defineReflectiveTests(PreferTypeOverVarTest);
  });
}

@reflectiveTest
final class AvoidUnusedAssignmentTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnusedAssignment();
    super.setUp();
  }

  Future<void> test_assignedTwiceBeforeRead_lint() async {
    const source = r'''
void f() {
  var count = 1;
  count = 2;
  print(count);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('count = 2'), 'count'.length)]);
  }

  Future<void> test_readBetweenAssignments_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  var count = 1;
  print(count);
  count = 2;
  print(count);
}
''');
  }

  Future<void> test_shadowedVariable_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  var value = 1;
  {
    var value = 2;
    print(value);
  }
  print(value);
}
''');
  }
}

@reflectiveTest
final class AvoidRepeatedPropertyAliasesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidRepeatedPropertyAliases();
    super.setUp();
  }

  Future<void> test_threeAliasesFromSameReceiver_lint() async {
    const source = r'''
class Preferences {
  bool? calendar;
  bool? recentSessions;
  bool? loggedExercises;
}

void f(Preferences preferences) {
  final calendar = preferences.calendar;
  final recentSessions = preferences.recentSessions;
  final loggedExercises = preferences.loggedExercises;
  print((calendar, recentSessions, loggedExercises));
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('calendar ='), 'calendar'.length)]);
  }

  Future<void> test_twoAliases_noLint() async {
    await assertNoDiagnostics(r'''
class Preferences {
  bool? calendar;
  bool? recentSessions;
}

void f(Preferences preferences) {
  final calendar = preferences.calendar;
  final recentSessions = preferences.recentSessions;
  print((calendar, recentSessions));
}
''');
  }

  Future<void> test_useSourceObjectDirectly_noLint() async {
    await assertNoDiagnostics(r'''
class Preferences {
  bool? calendar;
  bool? recentSessions;
  bool? loggedExercises;
}

void f(Preferences preferences) {
  print(preferences.calendar);
  print(preferences.recentSessions);
  print(preferences.loggedExercises);
}
''');
  }

  Future<void> test_namedRecordProjection_noLint() async {
    await assertNoDiagnostics(r'''
class Preferences {
  bool? calendar;
  bool? recentSessions;
  bool? loggedExercises;
}

typedef PreferencesProjection = ({bool? calendar, bool? loggedExercises, bool? recentSessions});

void f(Preferences preferences) {
  final PreferencesProjection projection = (
    calendar: preferences.calendar,
    loggedExercises: preferences.loggedExercises,
    recentSessions: preferences.recentSessions,
  );
  print(projection);
}
''');
  }

  Future<void> test_l10nAliases_noLint() async {
    await assertNoDiagnostics(r'''
class AppLocalizations {
  String get save => '';
  String get cancel => '';
  String get delete => '';
}

void f(AppLocalizations l10n) {
  final save = l10n.save;
  final cancel = l10n.cancel;
  final delete = l10n.delete;
  print((save, cancel, delete));
}
''');
  }
}

@reflectiveTest
final class AvoidParameterAliasesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidParameterAliases();
    super.setUp();
  }

  Future<void> test_directParameterAlias_lint() async {
    const source = r'''
void f(double dataMin) {
  double adjustedDataMin = dataMin;
  print(adjustedDataMin);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('adjustedDataMin'), 'adjustedDataMin'.length),
    ]);
  }

  Future<void> test_finalParameterAlias_lint() async {
    const source = r'''
void f(String name) {
  final label = name;
  print(label);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('label'), 'label'.length)]);
  }

  Future<void> test_derivedFromParameter_noLint() async {
    await assertNoDiagnostics(r'''
void f(double dataMin) {
  final adjusted = dataMin * 0.9;
  print(adjusted);
}
''');
  }

  Future<void> test_forLoopCursor_noLint() async {
    await assertNoDiagnostics(r'''
void f(int start) {
  for (int index = start; index < 3; index++) {
    print(index);
  }
}
''');
  }

  Future<void> test_localAliasOfLocal_lint() async {
    const source = r'''
void f() {
  final source = 1;
  final copy = source;
  print(copy);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('copy'), 'copy'.length)]);
  }

  Future<void> test_reassignedAlias_lint() async {
    const source = r'''
void f(int start) {
  int cursor = start;
  cursor = cursor - 1;
  print(cursor);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('cursor'), 'cursor'.length)]);
  }

  Future<void> test_reassignedAdjustedBoundsAliases_lint() async {
    const source = r'''
void f(double dataMin, double dataMax) {
  double adjustedDataMin = dataMin;
  double adjustedDataMax = dataMax;
  adjustedDataMin = adjustedDataMin - 5;
  adjustedDataMax = adjustedDataMax + 5;
  print(adjustedDataMin + adjustedDataMax);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('adjustedDataMin'), 'adjustedDataMin'.length),
      lint(source.indexOf('adjustedDataMax'), 'adjustedDataMax'.length),
    ]);
  }

  Future<void> test_topLevelValueAlias_noLint() async {
    await assertNoDiagnostics(r'''
const source = 1;

void f() {
  final copy = source;
  print(copy);
}
''');
  }

  Future<void> test_parenthesizedParameterAlias_lint() async {
    const source = r'''
void f(int count) {
  final total = (count);
  print(total);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('total'), 'total'.length)]);
  }
}

@reflectiveTest
final class AvoidUnassignedLocalVariableTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnassignedLocalVariable();
    super.setUp();
  }

  Future<void> test_readBeforeAssignment_lint() async {
    const source = r'''
void f() {
  late int value;
  print(value);
  value = 1;
}
''';

    final offset = source.indexOf('value);');
    final unassignedLateLocal = errorCodeByUniqueName('definitely_unassigned_late_local_variable')!;

    await assertDiagnostics(source, [
      error(unassignedLateLocal, offset, 'value'.length),
      lint(offset, 'value'.length),
    ]);
  }

  Future<void> test_assignmentBeforeRead_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  late int value;
  value = 1;
  print(value);
}
''');
  }

  Future<void> test_initializerMakesVariableAssigned_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  var value = 1;
  print(value);
}
''');
  }

  Future<void> test_severity_info() async {
    expect(AvoidUnassignedLocalVariable.code.severity, DiagnosticSeverity.INFO);
  }
}

@reflectiveTest
final class AvoidUnusedLocalVariableTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnusedLocalVariable();
    super.setUp();
  }

  Future<void> test_neverRead_lint() async {
    const source = r'''
void f() {
  final unused = 1;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('unused'), 'unused'.length)]);
  }

  Future<void> test_readInNestedBlock_noLint() async {
    await assertNoDiagnostics(r'''
void f(bool enabled) {
  final value = 1;
  if (enabled) {
    print(value);
  }
}
''');
  }

  Future<void> test_readInClosure_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  final value = 1;
  final callback = () {
    print(value);
  };
  callback();
}
''');
  }

  Future<void> test_readInLocalFunction_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  final value = 1;
  void log() {
    print(value);
  }
  log();
}
''');
  }

  Future<void> test_wildcardLikeName_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  final _ignored = 1;
}
''');
  }
}

@reflectiveTest
final class PreferTypeOverVarTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferTypeOverVar();
    super.setUp();
  }

  Future<void> test_localVar_lint() async {
    const source = r'''
void f() {
  var hasMore = true;
  print(hasMore);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('var'), 'var'.length)]);
  }

  Future<void> test_forLoopVar_lint() async {
    const source = r'''
void f() {
  for (var index = 0; index < 3; index++) {
    print(index);
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('var'), 'var'.length)]);
  }

  Future<void> test_fieldVar_lint() async {
    const source = r'''
final class Counter {
  var value = 0;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('var'), 'var'.length)]);
  }

  Future<void> test_patternDeclarationVar_lint() async {
    const source = r'''
void f() {
  var (:hasMore) = (hasMore: true);
  print(hasMore);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('var'), 'var'.length)]);
  }

  Future<void> test_casePatternVar_lint() async {
    const source = r'''
void f(Object value) {
  switch (value) {
    case var hasMore:
      print(hasMore);
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('var hasMore'), 'var'.length)]);
  }

  Future<void> test_explicitType_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  bool hasMore = true;
  for (int index = 0; index < 3; index++) {
    print(index);
  }
  print(hasMore);
}
''');
  }
}
