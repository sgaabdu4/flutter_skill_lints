import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_parameter_aliases.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_repeated_property_aliases.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unassigned_local_variable.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unused_assignment.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unused_local_variable.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_type_over_var.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidUnusedAssignmentTest>(
    'AvoidUnusedAssignmentTest',
    _AvoidUnusedAssignmentTest.new,
    _AvoidUnusedAssignmentTest._allCases,
  );
  analysisRuleSuite<_AvoidParameterAliasesTest>(
    'AvoidParameterAliasesTest',
    _AvoidParameterAliasesTest.new,
    _AvoidParameterAliasesTest._allCases,
  );
  analysisRuleSuite<_AvoidRepeatedPropertyAliasesTest>(
    'AvoidRepeatedPropertyAliasesTest',
    _AvoidRepeatedPropertyAliasesTest.new,
    _AvoidRepeatedPropertyAliasesTest._allCases,
  );
  analysisRuleSuite<_AvoidUnassignedLocalVariableTest>(
    'AvoidUnassignedLocalVariableTest',
    _AvoidUnassignedLocalVariableTest.new,
    _AvoidUnassignedLocalVariableTest._allCases,
  );
  analysisRuleSuite<_AvoidUnusedLocalVariableTest>(
    'AvoidUnusedLocalVariableTest',
    _AvoidUnusedLocalVariableTest.new,
    _AvoidUnusedLocalVariableTest._allCases,
  );
  analysisRuleSuite<_PreferTypeOverVarTest>(
    'PreferTypeOverVarTest',
    _PreferTypeOverVarTest.new,
    _PreferTypeOverVarTest._allCases,
  );
}

final class _AvoidUnusedAssignmentTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidUnusedAssignmentTest)> get _allCases =>
      caseSet<_AvoidUnusedAssignmentTest>(
        parent: const {},
        own: {
          'test_assignedTwiceBeforeRead_lint': (t) => t._assignedTwiceBeforeReadLint(),
          'test_readBetweenAssignments_noLint': (t) => t._readBetweenAssignmentsNoLint(),
          'test_registeredInlineCallbackReadsAcrossAwaits_noLint': (t) =>
              t._registeredInlineCallbackReadsAcrossAwaitsNoLint(),
          'test_callbackCaptureStillRequiresExecution_lint': (t) =>
              t._callbackCaptureStillRequiresExecutionLint(),
          'test_storedClosureReadsValue_noLint': (t) => t._storedClosureReadsValueNoLint(),
          'test_escapedClosureDoesNotHideAdjacentOverwrite_lint': (t) =>
              t._escapedClosureDoesNotHideAdjacentOverwriteLint(),
          'test_shadowedCallbackReadDoesNotConsumeOuter_lint': (t) =>
              t._shadowedCallbackReadDoesNotConsumeOuterLint(),
          'test_shadowedVariable_noLint': (t) => t._shadowedVariableNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidUnusedAssignment();
    super.setUp();
  }

  Future<void> _assignedTwiceBeforeReadLint() async {
    const source = r'''
void f() {
  var count = 1;
  count = 2;
  print(count);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('count = 2'), 'count'.length)]);
  }

  Future<void> _readBetweenAssignmentsNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  var count = 1;
  print(count);
  count = 2;
  print(count);
}
''');
  }

  Future<void> _registeredInlineCallbackReadsAcrossAwaitsNoLint() async {
    await assertNoDiagnostics(r'''
void Function()? listener;
void register(void Function() callback) { listener = callback; }
Future<void> flush() async { listener!(); }

Future<void> f() async {
  var ready = false;
  register(() { print(ready); });
  await flush();
  ready = true;
  await flush();
  ready = false;
  await flush();
}
''');
  }

  Future<void> _callbackCaptureStillRequiresExecutionLint() async {
    const source = r'''
Future<void> unrelated() async {}

Future<void> f() async {
  var value = 1;
  final read = () => value;
  await unrelated();
  value = 2;
  print(value);
  value = 3;
  await unrelated();
  value = 4;
  print(value);
  print(read);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('value = 2'), 'value'.length),
      lint(source.indexOf('value = 4'), 'value'.length),
    ]);
  }

  Future<void> _storedClosureReadsValueNoLint() async {
    await assertNoDiagnostics(r'''
void Function()? listener;
Future<void> flush() async { listener!(); }

Future<void> f() async {
  var ready = false;
  listener = () { print(ready); };
  await flush();
  ready = true;
  await flush();
}
''');
  }

  Future<void> _escapedClosureDoesNotHideAdjacentOverwriteLint() async {
    const source = r'''
void Function()? listener;
void register(void Function() callback) { listener = callback; }
Future<void> flush() async { listener!(); }

Future<void> f() async {
  var value = 1;
  register(() { print(value); });
  await flush();
  value = 2;
  value = 3;
  await flush();
  value = 4;
  final token = const Object();
  final same = identical(1, 1);
  value = 5;
  await flush();
  print(token);
  print(same);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('value = 3'), 'value'.length),
      lint(source.indexOf('value = 5'), 'value'.length),
    ]);
  }

  Future<void> _shadowedCallbackReadDoesNotConsumeOuterLint() async {
    const source = r'''
void register(void Function(int) callback) { callback(0); }

void f() {
  var value = 1;
  register((value) { print(value); });
  value = 2;
  print(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value = 2'), 'value'.length)]);
  }

  Future<void> _shadowedVariableNoLint() async {
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

final class _AvoidRepeatedPropertyAliasesTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidRepeatedPropertyAliasesTest)> get _allCases =>
      caseSet<_AvoidRepeatedPropertyAliasesTest>(
        parent: const {},
        own: {
          'test_threeAliasesFromSameReceiver_lint': (t) => t._threeAliasesFromSameReceiverLint(),
          'test_twoAliases_noLint': (t) => t._twoAliasesNoLint(),
          'test_useSourceObjectDirectly_noLint': (t) => t._useSourceObjectDirectlyNoLint(),
          'test_namedRecordProjection_noLint': (t) => t._namedRecordProjectionNoLint(),
          'test_l10nAliases_noLint': (t) => t._l10nAliasesNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidRepeatedPropertyAliases();
    super.setUp();
  }

  Future<void> _threeAliasesFromSameReceiverLint() async {
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

  Future<void> _twoAliasesNoLint() async {
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

  Future<void> _useSourceObjectDirectlyNoLint() async {
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

  Future<void> _namedRecordProjectionNoLint() async {
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

  Future<void> _l10nAliasesNoLint() async {
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

final class _AvoidParameterAliasesTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidParameterAliasesTest)> get _allCases =>
      caseSet<_AvoidParameterAliasesTest>(
        parent: const {},
        own: {
          'test_directParameterAlias_lint': (t) => t._directParameterAliasLint(),
          'test_finalParameterAlias_lint': (t) => t._finalParameterAliasLint(),
          'test_derivedFromParameter_noLint': (t) => t._derivedFromParameterNoLint(),
          'test_forLoopCursor_noLint': (t) => t._forLoopCursorNoLint(),
          'test_localAliasOfLocal_lint': (t) => t._localAliasOfLocalLint(),
          'test_reassignedAlias_lint': (t) => t._reassignedAliasLint(),
          'test_reassignedAdjustedBoundsAliases_lint': (t) =>
              t._reassignedAdjustedBoundsAliasesLint(),
          'test_topLevelValueAlias_noLint': (t) => t._topLevelValueAliasNoLint(),
          'test_parenthesizedParameterAlias_lint': (t) => t._parenthesizedParameterAliasLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidParameterAliases();
    super.setUp();
  }

  Future<void> _directParameterAliasLint() async {
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

  Future<void> _finalParameterAliasLint() async {
    const source = r'''
void f(String name) {
  final label = name;
  print(label);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('label'), 'label'.length)]);
  }

  Future<void> _derivedFromParameterNoLint() async {
    await assertNoDiagnostics(r'''
void f(double dataMin) {
  final adjusted = dataMin * 0.9;
  print(adjusted);
}
''');
  }

  Future<void> _forLoopCursorNoLint() async {
    await assertNoDiagnostics(r'''
void f(int start) {
  for (int index = start; index < 3; index++) {
    print(index);
  }
}
''');
  }

  Future<void> _localAliasOfLocalLint() async {
    const source = r'''
void f() {
  final source = 1;
  final copy = source;
  print(copy);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('copy'), 'copy'.length)]);
  }

  Future<void> _reassignedAliasLint() async {
    const source = r'''
void f(int start) {
  int cursor = start;
  cursor = cursor - 1;
  print(cursor);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('cursor'), 'cursor'.length)]);
  }

  Future<void> _reassignedAdjustedBoundsAliasesLint() async {
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

  Future<void> _topLevelValueAliasNoLint() async {
    await assertNoDiagnostics(r'''
const source = 1;

void f() {
  final copy = source;
  print(copy);
}
''');
  }

  Future<void> _parenthesizedParameterAliasLint() async {
    const source = r'''
void f(int count) {
  final total = (count);
  print(total);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('total'), 'total'.length)]);
  }
}

final class _AvoidUnassignedLocalVariableTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidUnassignedLocalVariableTest)> get _allCases =>
      caseSet<_AvoidUnassignedLocalVariableTest>(
        parent: const {},
        own: {
          'test_readBeforeAssignment_lint': (t) => t._readBeforeAssignmentLint(),
          'test_assignmentBeforeRead_noLint': (t) => t._assignmentBeforeReadNoLint(),
          'test_nullableDefaultIsInitialized_noLint': (t) =>
              t._nullableDefaultIsInitializedNoLint(),
          'test_lateNullableStillNeedsAssignment_lint': (t) =>
              t._lateNullableStillNeedsAssignmentLint(),
          'test_finalNullableStillNeedsAssignment_lint': (t) =>
              t._finalNullableStillNeedsAssignmentLint(),
          'test_initializerMakesVariableAssigned_noLint': (t) =>
              t._initializerMakesVariableAssignedNoLint(),
          'test_severity_info': (t) => t._severityInfo(),
        },
      );

  @override
  void setUp() {
    rule = AvoidUnassignedLocalVariable();
    super.setUp();
  }

  Future<void> _readBeforeAssignmentLint() async {
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

  Future<void> _assignmentBeforeReadNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  late int value;
  value = 1;
  print(value);
}
''');
  }

  Future<void> _nullableDefaultIsInitializedNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  int? count;
  dynamic value;
  print(count);
  print(value);
}
''');
  }

  Future<void> _lateNullableStillNeedsAssignmentLint() async {
    const source = r'''
void f() {
  late int? value;
  print(value);
}
''';
    final offset = source.indexOf('value);');
    await assertDiagnostics(source, [
      error(errorCodeByUniqueName('definitely_unassigned_late_local_variable')!, offset, 5),
      lint(offset, 5),
    ]);
  }

  Future<void> _finalNullableStillNeedsAssignmentLint() async {
    const source = r'''
void f() {
  final int? value;
  print(value);
}
''';
    final offset = source.indexOf('value);');
    await assertDiagnostics(source, [
      error(errorCodeByUniqueName('read_potentially_unassigned_final')!, offset, 5),
      lint(offset, 5),
    ]);
  }

  Future<void> _initializerMakesVariableAssignedNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  var value = 1;
  print(value);
}
''');
  }

  Future<void> _severityInfo() async {
    expect(AvoidUnassignedLocalVariable.code.severity, DiagnosticSeverity.INFO);
  }
}

final class _AvoidUnusedLocalVariableTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidUnusedLocalVariableTest)> get _allCases =>
      caseSet<_AvoidUnusedLocalVariableTest>(
        parent: const {},
        own: {
          'test_neverRead_lint': (t) => t._neverReadLint(),
          'test_readInNestedBlock_noLint': (t) => t._readInNestedBlockNoLint(),
          'test_readInClosure_noLint': (t) => t._readInClosureNoLint(),
          'test_readInLocalFunction_noLint': (t) => t._readInLocalFunctionNoLint(),
          'test_wildcardLikeName_noLint': (t) => t._wildcardLikeNameNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidUnusedLocalVariable();
    super.setUp();
  }

  Future<void> _neverReadLint() async {
    const source = r'''
void f() {
  final unused = 1;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('unused'), 'unused'.length)]);
  }

  Future<void> _readInNestedBlockNoLint() async {
    await assertNoDiagnostics(r'''
void f(bool enabled) {
  final value = 1;
  if (enabled) {
    print(value);
  }
}
''');
  }

  Future<void> _readInClosureNoLint() async {
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

  Future<void> _readInLocalFunctionNoLint() async {
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

  Future<void> _wildcardLikeNameNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  final _ignored = 1;
}
''');
  }
}

final class _PreferTypeOverVarTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_PreferTypeOverVarTest)> get _allCases =>
      caseSet<_PreferTypeOverVarTest>(
        parent: const {},
        own: {
          'test_localVar_lint': (t) => t._localVarLint(),
          'test_forLoopVar_lint': (t) => t._forLoopVarLint(),
          'test_fieldVar_lint': (t) => t._fieldVarLint(),
          'test_patternDeclarationVar_lint': (t) => t._patternDeclarationVarLint(),
          'test_casePatternVar_lint': (t) => t._casePatternVarLint(),
          'test_topLevelVar_lint': (t) => t._topLevelVarLint(),
          'test_forInLoopVar_lint': (t) => t._forInLoopVarLint(),
          'test_awaitForLoopVar_lint': (t) => t._awaitForLoopVarLint(),
          'test_forInPatternVar_lint': (t) => t._forInPatternVarLint(),
          'test_inferredFinal_noLint': (t) => t._inferredFinalNoLint(),
          'test_explicitType_noLint': (t) => t._explicitTypeNoLint(),
        },
      );

  @override
  void setUp() {
    rule = PreferTypeOverVar();
    super.setUp();
  }

  Future<void> _localVarLint() async {
    const source = r'''
void f() {
  var hasMore = true;
  print(hasMore);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('var'), 'var'.length)]);
  }

  Future<void> _forLoopVarLint() async {
    const source = r'''
void f() {
  for (var index = 0; index < 3; index++) {
    print(index);
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('var'), 'var'.length)]);
  }

  Future<void> _fieldVarLint() async {
    const source = r'''
final class Counter {
  var value = 0;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('var'), 'var'.length)]);
  }

  Future<void> _patternDeclarationVarLint() async {
    const source = r'''
void f() {
  var (:hasMore) = (hasMore: true);
  print(hasMore);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('var'), 'var'.length)]);
  }

  Future<void> _casePatternVarLint() async {
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

  Future<void> _topLevelVarLint() async {
    const source = r'''
var count = 0;
''';

    await assertDiagnostics(source, [lint(source.indexOf('var'), 'var'.length)]);
  }

  Future<void> _forInLoopVarLint() async {
    const source = r'''
void f(List<int> values) {
  for (var value in values) {
    print(value);
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('var'), 'var'.length)]);
  }

  Future<void> _awaitForLoopVarLint() async {
    const source = r'''
Future<void> f(Stream<int> values) async {
  await for (var value in values) {
    print(value);
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('var'), 'var'.length)]);
  }

  Future<void> _forInPatternVarLint() async {
    const source = r'''
void f(List<(int, int)> pairs) {
  for (var (first, second) in pairs) {
    print(first + second);
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('var'), 'var'.length)]);
  }

  Future<void> _inferredFinalNoLint() async {
    await assertNoDiagnostics(r'''
final total = 0;
void f(List<int> values) {
  final count = values.length;
  for (final value in values) {
    print(value + count + total);
  }
  final (first, second) = (1, 2);
  print(first + second);
}
''');
  }

  Future<void> _explicitTypeNoLint() async {
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
