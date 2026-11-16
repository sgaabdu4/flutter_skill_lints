import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_double_slash_imports.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_enum_values_by_index.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_future_tostring.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_late_keyword.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_multi_assignment.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidDoubleSlashImportsTest>(
    'AvoidDoubleSlashImportsTest',
    _AvoidDoubleSlashImportsTest.new,
    _AvoidDoubleSlashImportsTest._allCases,
  );
  analysisRuleSuite<_AvoidEnumValuesByIndexTest>(
    'AvoidEnumValuesByIndexTest',
    _AvoidEnumValuesByIndexTest.new,
    _AvoidEnumValuesByIndexTest._allCases,
  );
  analysisRuleSuite<_AvoidFutureToStringTest>(
    'AvoidFutureToStringTest',
    _AvoidFutureToStringTest.new,
    _AvoidFutureToStringTest._allCases,
  );
  analysisRuleSuite<_AvoidLateKeywordTest>(
    'AvoidLateKeywordTest',
    _AvoidLateKeywordTest.new,
    _AvoidLateKeywordTest._allCases,
  );
  analysisRuleSuite<_AvoidMultiAssignmentTest>(
    'AvoidMultiAssignmentTest',
    _AvoidMultiAssignmentTest.new,
    _AvoidMultiAssignmentTest._allCases,
  );
}

final class _AvoidDoubleSlashImportsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidDoubleSlashImportsTest)> get _allCases =>
      caseSet<_AvoidDoubleSlashImportsTest>(
        parent: const {},
        own: {
          'test_exportWithDoubleSlash_lint': (t) => t._exportWithDoubleSlashLint(),
          'test_importWithDoubleSlash_lint': (t) => t._importWithDoubleSlashLint(),
          'test_normalizedImport_noLint': (t) => t._normalizedImportNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidDoubleSlashImports();
    super.setUp();
    newFile('$testPackageLibPath/src/models.dart', '');
  }

  Future<void> _exportWithDoubleSlashLint() async {
    const source = r'''
// ignore_for_file: uri_does_not_exist

export 'src//models.dart';
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'src//models.dart'"), "'src//models.dart'".length),
    ]);
  }

  Future<void> _importWithDoubleSlashLint() async {
    const source = r'''
// ignore_for_file: uri_does_not_exist

import 'package:app/src//models.dart';
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'package:app"), "'package:app/src//models.dart'".length),
    ]);
  }

  Future<void> _normalizedImportNoLint() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: unused_import

import 'src/models.dart';
''');
  }
}

final class _AvoidEnumValuesByIndexTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidEnumValuesByIndexTest)> get _allCases =>
      caseSet<_AvoidEnumValuesByIndexTest>(
        parent: const {},
        own: {
          'test_enumValuesByIndex_lint': (t) => t._enumValuesByIndexLint(),
          'test_importPrefixedEnumValuesByIndex_lint': (t) =>
              t._importPrefixedEnumValuesByIndexLint(),
          'test_enumTypeAliasValuesByIndex_lint': (t) => t._enumTypeAliasValuesByIndexLint(),
          'test_importPrefixedEnumTypeAliasValuesByIndex_lint': (t) =>
              t._importPrefixedEnumTypeAliasValuesByIndexLint(),
          'test_enumValueDirect_noLint': (t) => t._enumValueDirectNoLint(),
          'test_mapFieldNamedValuesByIndex_noLint': (t) => t._mapFieldNamedValuesByIndexNoLint(),
          'test_nonEnumStaticValuesByIndex_noLint': (t) => t._nonEnumStaticValuesByIndexNoLint(),
          'test_nonEnumTypeAliasValuesByIndex_noLint': (t) =>
              t._nonEnumTypeAliasValuesByIndexNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidEnumValuesByIndex();
    super.setUp();
  }

  Future<void> _enumValuesByIndexLint() async {
    const source = r'''
enum Status { ready, done }

final status = Status.values[0];
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Status.values[0]'), 'Status.values[0]'.length),
    ]);
  }

  Future<void> _importPrefixedEnumValuesByIndexLint() async {
    newFile('$testPackageLibPath/status.dart', 'enum Status { ready, done }');
    const source = r'''
import 'status.dart' as model;

final status = model.Status.values[0];
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('model.Status.values[0]'), 'model.Status.values[0]'.length),
    ]);
  }

  Future<void> _enumTypeAliasValuesByIndexLint() async {
    const source = r'''
enum Status { ready, done }
typedef StatusAlias = Status;

final status = StatusAlias.values[0];
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('StatusAlias.values[0]'), 'StatusAlias.values[0]'.length),
    ]);
  }

  Future<void> _importPrefixedEnumTypeAliasValuesByIndexLint() async {
    newFile('$testPackageLibPath/status.dart', '''
enum Status { ready, done }
typedef StatusAlias = Status;
''');
    const source = r'''
import 'status.dart' as model;

final status = model.StatusAlias.values[0];
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('model.StatusAlias.values[0]'), 'model.StatusAlias.values[0]'.length),
    ]);
  }

  Future<void> _enumValueDirectNoLint() async {
    await assertNoDiagnostics(r'''
enum Status { ready, done }

final status = Status.ready;
''');
  }

  Future<void> _mapFieldNamedValuesByIndexNoLint() async {
    await assertNoDiagnostics(r'''
final class MemoryStore {
  final Map<String, Object?> values = {};
}

Object? read(MemoryStore store) => store.values['key'];
''');
  }

  Future<void> _nonEnumStaticValuesByIndexNoLint() async {
    await assertNoDiagnostics(r'''
abstract final class Lookup {
  static const values = ['first'];
}

String read() => Lookup.values[0];
''');
  }

  Future<void> _nonEnumTypeAliasValuesByIndexNoLint() async {
    await assertNoDiagnostics(r'''
abstract final class Lookup {
  static const values = ['first'];
}
typedef LookupAlias = Lookup;

String read() => LookupAlias.values[0];
''');
  }
}

final class _AvoidFutureToStringTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidFutureToStringTest)> get _allCases =>
      caseSet<_AvoidFutureToStringTest>(
        parent: const {},
        own: {
          'test_futureToString_lint': (t) => t._futureToStringLint(),
          'test_nonFutureToString_noLint': (t) => t._nonFutureToStringNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidFutureToString();
    super.setUp();
  }

  Future<void> _futureToStringLint() async {
    const source = r'''
Future<int> load() async => 1;

void f() {
  load().toString();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> _nonFutureToStringNoLint() async {
    await assertNoDiagnostics(r'''
void f(Object value) {
  value.toString();
}
''');
  }
}

final class _AvoidLateKeywordTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidLateKeywordTest)> get _allCases =>
      caseSet<_AvoidLateKeywordTest>(
        parent: const {},
        own: {
          'test_lateLocal_lint': (t) => t._lateLocalLint(),
          'test_eagerLocal_noLint': (t) => t._eagerLocalNoLint(),
          'test_lateInTestFile_noLint': (t) => t._lateInTestFileNoLint(),
          'test_lateFinalStateField_noLint': (t) => t._lateFinalStateFieldNoLint(),
          'test_lateFinalConsumerStateField_noLint': (t) => t._lateFinalConsumerStateFieldNoLint(),
          'test_lateMutableStateField_noLint': (t) => t._lateMutableStateFieldNoLint(),
          'test_lateMutableNonStateField_lint': (t) => t._lateMutableNonStateFieldLint(),
          'test_lateFinalDerivedInstanceField_noLint': (t) =>
              t._lateFinalDerivedInstanceFieldNoLint(),
          'test_lateFinalFieldWithoutInitializer_lint': (t) =>
              t._lateFinalFieldWithoutInitializerLint(),
          'test_lateMutableFieldWithInitializer_lint': (t) =>
              t._lateMutableFieldWithInitializerLint(),
          'test_lateFinalStaticFieldWithInitializer_lint': (t) =>
              t._lateFinalStaticFieldWithInitializerLint(),
          'test_lateFinalLocalWithInitializer_lint': (t) => t._lateFinalLocalWithInitializerLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidLateKeyword();
    super.setUp();
  }

  Future<void> _lateLocalLint() async {
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

  Future<void> _eagerLocalNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  final value = 1;
  print(value);
}
''');
  }

  Future<void> _lateInTestFileNoLint() async {
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

  Future<void> _lateFinalStateFieldNoLint() async {
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

  Future<void> _lateFinalConsumerStateFieldNoLint() async {
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

  Future<void> _lateMutableStateFieldNoLint() async {
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

  Future<void> _lateMutableNonStateFieldLint() async {
    const source = r'''
class Cache {
  late int value;
}
''';
    final path = '$testPackageLibPath/mutable_non_state_field.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(source.indexOf('late'), 'late'.length)]);
  }

  Future<void> _lateFinalDerivedInstanceFieldNoLint() async {
    const source = r'''
class Item {
  const Item(this.groupId);
  final String groupId;
}

class Catalog {
  Catalog(this.items);

  final List<Item> items;

  late final Map<String, List<Item>> itemsByGroup = _indexItemsByGroup(items);
}

Map<String, List<Item>> _indexItemsByGroup(List<Item> items) {
  final map = <String, List<Item>>{};
  for (final item in items) {
    (map[item.groupId] ??= <Item>[]).add(item);
  }
  return map;
}
''';
    final path = '$testPackageLibPath/derived_field.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> _lateFinalFieldWithoutInitializerLint() async {
    const source = r'''
class Cache {
  late final int value;
}
''';
    final path = '$testPackageLibPath/late_final_no_initializer.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(source.indexOf('late'), 'late'.length)]);
  }

  Future<void> _lateMutableFieldWithInitializerLint() async {
    const source = r'''
class Cache {
  late int value = _compute();
}

int _compute() => 1;
''';
    final path = '$testPackageLibPath/late_mutable_initializer.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(source.indexOf('late'), 'late'.length)]);
  }

  Future<void> _lateFinalStaticFieldWithInitializerLint() async {
    const source = r'''
class Cache {
  static late final int value = _compute();
}

int _compute() => 1;
''';
    final path = '$testPackageLibPath/late_static_initializer.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(source.indexOf('late'), 'late'.length)]);
  }

  Future<void> _lateFinalLocalWithInitializerLint() async {
    const source = r'''
void f(int Function() compute) {
  late final value = compute();
  print(value);
}
''';
    final path = '$testPackageLibPath/late_local_initializer.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(source.indexOf('late'), 'late'.length)]);
  }
}

final class _AvoidMultiAssignmentTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidMultiAssignmentTest)> get _allCases =>
      caseSet<_AvoidMultiAssignmentTest>(
        parent: const {},
        own: {
          'test_chainedAssignment_lint': (t) => t._chainedAssignmentLint(),
          'test_separateAssignments_noLint': (t) => t._separateAssignmentsNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidMultiAssignment();
    super.setUp();
  }

  Future<void> _chainedAssignmentLint() async {
    const source = r'''
void f() {
  var a = 0;
  var b = 0;
  a = b = 1;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('a = b = 1'), 'a = b = 1'.length)]);
  }

  Future<void> _separateAssignmentsNoLint() async {
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
