import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_one_field_records.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_positional_record_field_access.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_positional_record_fields.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_redundant_positional_field_name.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidOneFieldRecordsTest>(
    'AvoidOneFieldRecordsTest',
    _AvoidOneFieldRecordsTest.new,
    _AvoidOneFieldRecordsTest._allCases,
  );
  analysisRuleSuite<_AvoidPositionalRecordFieldsTest>(
    'AvoidPositionalRecordFieldsTest',
    _AvoidPositionalRecordFieldsTest.new,
    _AvoidPositionalRecordFieldsTest._allCases,
  );
  analysisRuleSuite<_AvoidPositionalRecordFieldAccessTest>(
    'AvoidPositionalRecordFieldAccessTest',
    _AvoidPositionalRecordFieldAccessTest.new,
    _AvoidPositionalRecordFieldAccessTest._allCases,
  );
  analysisRuleSuite<_AvoidRedundantPositionalFieldNameTest>(
    'AvoidRedundantPositionalFieldNameTest',
    _AvoidRedundantPositionalFieldNameTest.new,
    _AvoidRedundantPositionalFieldNameTest._allCases,
  );
}

final class _AvoidOneFieldRecordsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidOneFieldRecordsTest)> get _allCases =>
      caseSet<_AvoidOneFieldRecordsTest>(
        parent: const {},
        own: {
          'test_oneNamedFieldLiteral_lint': (t) => t._oneNamedFieldLiteralLint(),
          'test_onePositionalFieldType_lint': (t) => t._onePositionalFieldTypeLint(),
          'test_parenthesizedExpression_noLint': (t) => t._parenthesizedExpressionNoLint(),
          'test_twoFieldRecords_noLint': (t) => t._twoFieldRecordsNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidOneFieldRecords();
    super.setUp();
  }

  Future<void> _oneNamedFieldLiteralLint() async {
    const source = r'''
void f() {
  final value = (id: 1);
  print(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(id: 1)'), '(id: 1)'.length)]);
  }

  Future<void> _onePositionalFieldTypeLint() async {
    const source = r'''
typedef IdRecord = (int,);
''';

    await assertDiagnostics(source, [lint(source.indexOf('(int,)'), '(int,)'.length)]);
  }

  Future<void> _parenthesizedExpressionNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  final value = (1);
  print(value);
}
''');
  }

  Future<void> _twoFieldRecordsNoLint() async {
    await assertNoDiagnostics(r'''
typedef PointRecord = ({int x, int y});

void f() {
  final value = (1, 2);
  print(value);
}
''');
  }
}

final class _AvoidPositionalRecordFieldsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidPositionalRecordFieldsTest)> get _allCases =>
      caseSet<_AvoidPositionalRecordFieldsTest>(
        parent: const {},
        own: {
          'test_positionalLiteral_lint': (t) => t._positionalLiteralLint(),
          'test_skillPositionalPairAndWildcardDestructuring_noLint': (t) =>
              t._skillPositionalPairAndWildcardDestructuringNoLint(),
          'test_threePositionalFieldsBoundToVariable_lint': (t) =>
              t._threePositionalFieldsBoundToVariableLint(),
          'test_positionalType_lint': (t) => t._positionalTypeLint(),
          'test_namedRecord_noLint': (t) => t._namedRecordNoLint(),
          'test_sdkFutureRecordWait_noLint': (t) => t._sdkFutureRecordWaitNoLint(),
          'test_unrelatedWaitGetter_stillReports': (t) => t._unrelatedWaitGetterStillReports(),
        },
      );

  @override
  void setUp() {
    rule = AvoidPositionalRecordFields();
    super.setUp();
  }

  Future<void> _positionalLiteralLint() async {
    const source = r'''
void f() {
  final value = ('calendar', true, 3);
  print(value);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'calendar'"), "'calendar'".length),
      lint(source.indexOf('true'), 'true'.length),
      lint(source.indexOf('3)'), 1),
    ]);
  }

  Future<void> _skillPositionalPairAndWildcardDestructuringNoLint() async {
    await assertNoDiagnostics(r'''
(String, int) userInfo() => ('Alice', 30);

int wildcards(String id, String sku) {
  final (name, age) = userInfo();
  final (_, price, _) = (id, 9.99, sku);
  var total = 0.0;
  (_, total, _) = (id, price + age + name.length, sku);
  return total.round();
}
''');
  }

  Future<void> _threePositionalFieldsBoundToVariableLint() async {
    const source = r'''
(String, int, bool) profile() => throw 'todo';
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('String'), 'String'.length),
      lint(source.indexOf('int'), 'int'.length),
      lint(source.indexOf('bool'), 'bool'.length),
    ]);
  }

  Future<void> _positionalTypeLint() async {
    const source = r'''
typedef PreferencesProjection = (bool?, bool?, bool?);
''';
    final first = source.indexOf('bool?');
    final second = source.indexOf('bool?', first + 1);
    final third = source.indexOf('bool?', second + 1);

    await assertDiagnostics(source, [
      lint(first, 'bool?'.length),
      lint(second, 'bool?'.length),
      lint(third, 'bool?'.length),
    ]);
  }

  Future<void> _namedRecordNoLint() async {
    await assertNoDiagnostics(r'''
typedef PreferencesProjection = ({bool? calendar, bool? loggedExercises, bool? recentSessions});

void f() {
  PreferencesProjection value = (calendar: true, loggedExercises: null, recentSessions: false);
  print(value);
}
''');
  }

  Future<void> _sdkFutureRecordWaitNoLint() async {
    final asyncPath = '$dartSdkPath/lib/async/async.dart';
    newFile(asyncPath, '''
${getFile(asyncPath).readAsStringSync()}
extension FutureRecord2<T1, T2> on (Future<T1>, Future<T2>) {
  Future<(T1, T2)> get wait => throw UnimplementedError();
}
''');
    await assertNoDiagnostics(r'''
import 'dart:async';
Future<void> load() async {
  final (count, label) = await (Future.value(1), Future.value('ready')).wait;
  print('$count $label');
}
''');
  }

  Future<void> _unrelatedWaitGetterStillReports() async {
    const source = r'''
extension FakeWait on (int, String, bool) {
  int get wait => $1;
}
void load() {
  final count = (1, 'ready', true).wait;
  print(count);
}
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('int, String'), 'int'.length),
      lint(source.indexOf('String,'), 'String'.length),
      lint(source.indexOf('bool)'), 'bool'.length),
      lint(source.indexOf('1, '), 1),
      lint(source.indexOf("'ready',"), "'ready'".length),
      lint(source.indexOf('true).wait'), 'true'.length),
    ]);
  }
}

final class _AvoidPositionalRecordFieldAccessTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidPositionalRecordFieldAccessTest)> get _allCases =>
      caseSet<_AvoidPositionalRecordFieldAccessTest>(
        parent: const {},
        own: {
          'test_prefixedIdentifier_lint': (t) => t._prefixedIdentifierLint(),
          'test_propertyAccess_lint': (t) => t._propertyAccessLint(),
          'test_namedRecordAccess_noLint': (t) => t._namedRecordAccessNoLint(),
          'test_nonRecordDollarGetter_noLint': (t) => t._nonRecordDollarGetterNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidPositionalRecordFieldAccess();
    super.setUp();
  }

  Future<void> _prefixedIdentifierLint() async {
    const source = r'''
void f((int, String) value) {
  print(value.$1);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf(r'$1'), r'$1'.length)]);
  }

  Future<void> _propertyAccessLint() async {
    const source = r'''
void f((int, String) value) {
  print((value).$2);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf(r'$2'), r'$2'.length)]);
  }

  Future<void> _namedRecordAccessNoLint() async {
    await assertNoDiagnostics(r'''
void f(({int id, String label}) value) {
  print(value.id);
}
''');
  }

  Future<void> _nonRecordDollarGetterNoLint() async {
    await assertNoDiagnostics(r'''
class Value {
  int get $1 => 1;
}

void f(Value value) {
  print(value.$1);
}
''');
  }
}

final class _AvoidRedundantPositionalFieldNameTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidRedundantPositionalFieldNameTest)> get _allCases =>
      caseSet<_AvoidRedundantPositionalFieldNameTest>(
        parent: const {},
        own: {
          'test_positionalFieldName_lint': (t) => t._positionalFieldNameLint(),
          'test_namedFields_noLint': (t) => t._namedFieldsNoLint(),
          'test_unnamedPositionalFields_noLint': (t) => t._unnamedPositionalFieldsNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidRedundantPositionalFieldName();
    super.setUp();
  }

  Future<void> _positionalFieldNameLint() async {
    const source = r'''
typedef PointRecord = (int x, int y);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('x,'), 'x'.length),
      lint(source.indexOf('y)'), 'y'.length),
    ]);
  }

  Future<void> _namedFieldsNoLint() async {
    await assertNoDiagnostics(r'''
typedef PointRecord = ({int x, int y});
''');
  }

  Future<void> _unnamedPositionalFieldsNoLint() async {
    await assertNoDiagnostics(r'''
typedef PointRecord = (int, int);
''');
  }
}
