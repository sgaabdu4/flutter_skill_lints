// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:flutter_skill_lints/src/rules/architecture_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/data_crash_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/freezed_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/notifier_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/riverpod_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/router_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/services_mixins_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/showcase_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';
import 'package:flutter_skill_lints/src/rules/state_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/test_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/ui_source_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RiverpodReadInitStateTest);
    defineReflectiveTests(RiverpodServiceLocatorTest);
    defineReflectiveTests(RiverpodWatchNoSelectTest);
    defineReflectiveTests(RiverpodKeepaliveFamilyTest);
    defineReflectiveTests(DartStaticNamespaceTest);
    defineReflectiveTests(FreezedPerClassExplicitToJsonTest);
    defineReflectiveTests(FreezedToJsonWithFromJsonTest);
    defineReflectiveTests(FreezedLegacyWhenMapTest);
    defineReflectiveTests(FreezedRequiredValueClassTest);
    defineReflectiveTests(ArchDomainImportTest);
    defineReflectiveTests(ArchDomainSerializationTest);
    defineReflectiveTests(ArchInterfaceContractTest);
    defineReflectiveTests(ArchConcreteDependencyTest);
    defineReflectiveTests(ArchDatasourceTryCatchTest);
    defineReflectiveTests(ArchWidgetPathTest);
    defineReflectiveTests(AtomicProviderAccessTest);
    defineReflectiveTests(TypedIdRawIdTest);
    defineReflectiveTests(RecordsMapReturnTest);
    defineReflectiveTests(StyleRawTokenTest);
    defineReflectiveTests(StyleRawTextStyleTest);
    defineReflectiveTests(StringsHardcodedTest);
    defineReflectiveTests(UiSnackbarBoundaryTest);
    defineReflectiveTests(A11yTextScaleClampTest);
    defineReflectiveTests(PerfBuildWorkTest);
    defineReflectiveTests(PerfListviewChildrenTest);
    defineReflectiveTests(StateRawResponseTest);
    defineReflectiveTests(StateBroadInvalidationTest);
    defineReflectiveTests(AsyncContextMountedStyleTest);
    defineReflectiveTests(RouterStringNavTest);
    defineReflectiveTests(RouterPopThenPushTest);
    defineReflectiveTests(RouterRedirectWatchTest);
    defineReflectiveTests(RouterRedirectLoadingBounceTest);
    defineReflectiveTests(ShowcaseListenManualHandleTest);
    defineReflectiveTests(ShowcasePrevNullGuardTest);
    defineReflectiveTests(ShowcaseDefaultScopeTest);
    defineReflectiveTests(ShowcaseDisposeOnTapTest);
    defineReflectiveTests(NotifierEnsureDepsTest);
    defineReflectiveTests(NotifierWatchMethodTest);
    defineReflectiveTests(ServiceSingletonTest);
    defineReflectiveTests(MixinMixinClassTest);
    defineReflectiveTests(MixinNameSuffixTest);
    defineReflectiveTests(MixinMutableStateTest);
    defineReflectiveTests(DataLogRethrowTest);
    defineReflectiveTests(CrashPossiblePiiTest);
    defineReflectiveTests(TestProviderContainerTest);
    defineReflectiveTests(TestUncontrolledScopeTest);
    defineReflectiveTests(TestCreateContainerTest);
    defineReflectiveTests(TestMockConcreteTest);
    defineReflectiveTests(TestPumpAndSettleTest);
    defineReflectiveTests(TestTapAtTest);
    defineReflectiveTests(TestInlineValueKeyTest);
    defineReflectiveTests(TestFirstMatchFinderTest);
  });
}

abstract class _SourceRuleTest extends AnalysisRuleTest {
  List<ScannerRule> get rules;
  String get ruleName;
  String get source;
  String get needle;
  String? get path => null;
  bool get lineStart => false;
  bool get addIgnorePrefix => true;

  @override
  void setUp() {
    rule = rules.singleWhere((rule) => rule.name == ruleName);
    _addFlutterPackage();
    super.setUp();
  }

  Future<void> test_reportsDiagnostic() async {
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    final expected = compatLint(analyzedSource, needle, ruleName, lineStart: lineStart);
    final filePath = path;
    if (filePath == null) {
      await assertDiagnostics(analyzedSource, [expected]);
      return;
    }

    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [expected]);
  }

  Future<void> assertAllows(String source, {String? path, bool addIgnorePrefix = true}) async {
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    if (path == null) {
      await assertNoDiagnostics(analyzedSource);
      return;
    }

    newFile(path, analyzedSource);
    await assertNoDiagnosticsInFile(path);
  }

  String _analyzedSource(String source, {required bool addIgnorePrefix}) {
    if (!addIgnorePrefix) return source;
    return '''
// ignore_for_file: extends_non_class, final_not_initialized, implements_non_class, undefined_function, undefined_identifier, undefined_method, unused_import
$source''';
  }

  ExpectedDiagnostic compatLint(
    String source,
    String needle,
    String name, {
    bool lineStart = false,
  }) {
    var offset = source.indexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    if (lineStart) {
      offset = source.lastIndexOf('\n', offset) + 1;
    }

    final lineEnd = source.indexOf('\n', offset);
    final end = lineEnd < 0 ? source.length : lineEnd;
    return lint(offset, math.max(1, end - offset), name: name);
  }

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}
class Widget {}
''');
  }
}

abstract class _RiverpodRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => riverpodSourceRules;
}

@reflectiveTest
final class RiverpodReadInitStateTest extends _RiverpodRuleTest {
  @override
  String get ruleName => 'riverpod_read_init_state';
  @override
  String get needle => 'ref.read(provider)';
  @override
  String get source => r'''
final provider = Object();

class WidgetRef {
  Object read(Object provider) => Object();
}

class TodosState {
  final ref = WidgetRef();

  void initState() {
    ref.read(provider);
  }
}
''';
}

@reflectiveTest
final class RiverpodServiceLocatorTest extends _RiverpodRuleTest {
  @override
  String get ruleName => 'riverpod_service_locator';
  @override
  String get needle => 'class ServiceLocator';
  @override
  String get source => 'class ServiceLocator {}';
}

@reflectiveTest
final class RiverpodWatchNoSelectTest extends _RiverpodRuleTest {
  @override
  String get ruleName => 'riverpod_watch_no_select';
  @override
  String get needle => 'ref.watch(provider)';
  @override
  String get source => r'''
final provider = Object();

class WidgetRef {
  Object watch(Object provider) => Object();
}

class TodoList {
  Object build() {
    final ref = WidgetRef();
    return ref.watch(provider);
  }
}
''';

  Future<void> test_allowsMultilineFamilyProviderSelect() async {
    await assertNoDiagnostics(r'''
final workoutByIdProvider = WorkoutFamily();

class ProviderArg<T> {
  Object select(Object Function(T? value) selector) => Object();
}

class Workout {
  const Workout(this.name);

  final String name;
}

class WorkoutFamily {
  ProviderArg<Workout> call(String id) => ProviderArg<Workout>();
}

class WorkoutConfig {
  const WorkoutConfig(this.workoutId);

  final String workoutId;
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

class TodoList {
  Object build(WorkoutConfig config) {
    final ref = WidgetRef();
    final isNewWorkout = ref.watch(
      workoutByIdProvider(config.workoutId).select((w) => w?.name.isEmpty ?? true),
    );
    return isNewWorkout;
  }
}
''');
  }
}

@reflectiveTest
final class RiverpodKeepaliveFamilyTest extends _RiverpodRuleTest {
  @override
  String get ruleName => 'riverpod_keepalive_family';
  @override
  String get needle => '@Riverpod';
  @override
  String get source => r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

@Riverpod(keepAlive: true)
Object todoProvider({required String todoId}) => Object();
''';
}

abstract class _FreezedRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => freezedSourceRules;
}

@reflectiveTest
final class DartStaticNamespaceTest extends _FreezedRuleTest {
  @override
  String get ruleName => 'dart_static_namespace';
  @override
  String get needle => 'class Tokens';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class Tokens {
  Tokens._();
  static const spacing = 8;
}
''';
}

@reflectiveTest
final class FreezedPerClassExplicitToJsonTest extends _FreezedRuleTest {
  @override
  String get ruleName => 'freezed_per_class_explicit_to_json';
  @override
  String get needle => '@JsonSerializable';
  @override
  String get source => r'''
class JsonSerializable {
  const JsonSerializable({bool explicitToJson = false});
}

@JsonSerializable(explicitToJson: true)
class UserDto {}
''';
}

@reflectiveTest
final class FreezedToJsonWithFromJsonTest extends _FreezedRuleTest {
  @override
  String get ruleName => 'freezed_to_json_with_from_json';
  @override
  String get needle => '@Freezed';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class Freezed {
  const Freezed({bool toJson = false});
}

@Freezed(toJson: true)
class User {
  const User._();

  factory User.fromJson(Map<String, dynamic> json) => const User._();
}
''';
}

@reflectiveTest
final class FreezedLegacyWhenMapTest extends _FreezedRuleTest {
  @override
  String get ruleName => 'freezed_legacy_when_map';
  @override
  String get needle => 'when();';
  @override
  String get source => r'''
class User {
  Object label(Union union) => union.when();
}

class Union {}
''';

  Future<void> test_allowsBareMocktailWhenCall() async {
    await assertNoDiagnostics(r'''
dynamic when(Object callback) => _Stub();

class _Stub {
  void thenReturn(Object value) {}
}

class Repository {
  int load() => 1;
}

void main() {
  final repository = Repository();
  when(() => repository.load()).thenReturn(1);
}
''');
  }
}

@reflectiveTest
final class FreezedRequiredValueClassTest extends _FreezedRuleTest {
  @override
  String get ruleName => 'freezed_required_value_class';
  @override
  String get needle => 'class User';
  @override
  bool get lineStart => true;
  @override
  String get path => '$testPackageLibPath/features/users/domain/user.dart';
  @override
  String get source => r'''
class User {
  const User({required this.id});

  final String id;
}
''';

  @override
  void setUp() {
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed {
  const Freezed();
}

const freezed = Freezed();
''');
    newPackage('equatable').addFile('lib/equatable.dart', r'''
class Equatable {}
''');
    super.setUp();
  }

  Future<void> test_reportsEquatableDataModel() async {
    final filePath = '$testPackageLibPath/features/users/data/models/user_model.dart';
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  UserModel(this.id);

  final String id;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'class UserModel extends Equatable', ruleName, lineStart: true),
    ]);
  }

  Future<void> test_allowsFreezedDomainEntity() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile('$testPackageLibPath/features/users/domain/user.freezed.dart', r'''
part of 'user.dart';

mixin _$User {}

final class _User implements User {
  const _User({
    required this.id,
  });

  final String id;
}
''');
    newFile(filePath, r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed
sealed class User with _$User {
  const factory User({
    required String id,
  }) = _User;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsFreezedDataModel() async {
    final filePath = '$testPackageLibPath/features/users/data/models/user_model.dart';
    newFile('$testPackageLibPath/features/users/data/models/user_model.freezed.dart', r'''
part of 'user_model.dart';

mixin _$UserModel {}

final class _UserModel implements UserModel {
  const _UserModel({
    required this.id,
  });

  final String id;
}
''');
    newFile(filePath, r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';

@freezed
sealed class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
  }) = _UserModel;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsDomainInterfaceContracts() async {
    final filePath = '$testPackageLibPath/features/users/domain/user_repository.dart';
    newFile(filePath, r'''
abstract interface class IUserRepository {
  Future<void> save();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsNonModelDataClassOutsideModelsFolder() async {
    final filePath = '$testPackageLibPath/features/users/data/datasources/user_datasource.dart';
    newFile(filePath, r'''
class UserDatasource {
  Future<void> load() async {}
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

abstract class _ArchitectureRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => architectureSourceRules;
}

@reflectiveTest
final class ArchDomainImportTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_domain_import';
  @override
  String get needle => 'import';
  @override
  String get path => '$testPackageLibPath/features/users/domain/user.dart';
  @override
  bool get addIgnorePrefix => false;

  @override
  void setUp() {
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed {
  const Freezed();
}

const freezed = Freezed();
''');
    super.setUp();
  }

  @override
  String get source => r'''
import 'package:flutter/widgets.dart';

class User {
  Widget? widget;
}
''';

  Future<void> test_allowsFreezedAnnotationDomainEntity() async {
    final filePath = '$testPackageLibPath/features/workouts/domain/workout.dart';
    newFile('$testPackageLibPath/features/workouts/domain/workout.freezed.dart', r'''
part of 'workout.dart';

mixin _$Workout {}

final class _Workout implements Workout {
  const _Workout({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}
''');
    newFile(filePath, r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout.freezed.dart';

@freezed
sealed class Workout with _$Workout {
  const factory Workout({
    required String id,
    required String name,
  }) = _Workout;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsDomainToDomainPackageImport() async {
    final filePath = '$testPackageLibPath/features/workouts/domain/workout.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:test_package/features/shared/domain/enums.dart';

final class Workout {}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsCoreConstantsImportFromDomain() async {
    final filePath = '$testPackageLibPath/features/auth/domain/auth_error.dart';
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:test_package/core/constants/auth_strings.dart';

final class AuthError {}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(
        source,
        "import 'package:test_package/core/constants/auth_strings.dart';",
        ruleName,
      ),
    ]);
  }
}

@reflectiveTest
final class ArchDomainSerializationTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_domain_serialization';
  @override
  String get needle => 'Map<String, dynamic> toJson';
  @override
  bool get lineStart => true;
  @override
  String get path => '$testPackageLibPath/features/users/domain/user.dart';
  @override
  String get source => 'class User { Map<String, dynamic> toJson() => {}; }';
}

@reflectiveTest
final class ArchInterfaceContractTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_interface_contract';
  @override
  String get needle => 'class UserDatasource';
  @override
  bool get lineStart => true;
  @override
  bool get addIgnorePrefix => false;
  @override
  String get path => '$testPackageLibPath/features/users/data/datasources/user_datasource.dart';
  @override
  String get source => 'class UserDatasource {}';
}

@reflectiveTest
final class ArchConcreteDependencyTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_concrete_dependency';
  @override
  String get needle => 'final UserDatasource';
  @override
  bool get lineStart => true;
  @override
  String get path => '$testPackageLibPath/features/users/data/repositories/user_repository.dart';
  @override
  String get source => r'''
abstract interface class IUserRepository {}

class UserDatasource {}

class UserRepository {
  final UserDatasource _datasource;
}
''';
}

@reflectiveTest
final class ArchDatasourceTryCatchTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_datasource_try_catch';
  @override
  String get needle => 'try {';
  @override
  String get path => '$testPackageLibPath/features/users/data/datasources/user_datasource.dart';
  @override
  String get source => r'''
class UserDatasource {
  Future<void> load() async {
    try {
      await Future<void>.value();
    } catch (_) {
      rethrow;
    }
  }
}
''';
}

@reflectiveTest
final class ArchWidgetPathTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_widget_path';
  @override
  String get needle => 'class TodoWidget';
  @override
  bool get addIgnorePrefix => false;
  @override
  String get path => '$testPackageLibPath/features/todos/widgets/todo_widget.dart';
  @override
  String get source => 'class TodoWidget {}';

  Future<void> test_allowsFeatureWidgetTestFiles() async {
    final filePath = '$testPackageRootPath/test/features/todos/widgets/todo_widget_test.dart';
    newFile(filePath, 'class TodoWidgetTest {}');

    await assertNoDiagnosticsInFile(filePath);
  }
}

@reflectiveTest
final class AtomicProviderAccessTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'atomic_provider_access';
  @override
  String get needle => 'ref.read';
  @override
  String get path => '$testPackageLibPath/core/widgets/atoms/atom_button.dart';
  @override
  String get source => r'''
void build(ref, provider) {
  ref.read(provider);
}
''';
}

@reflectiveTest
final class TypedIdRawIdTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'typed_id_raw_id';
  @override
  String get needle => 'final String userId';
  @override
  bool get lineStart => true;
  @override
  String get path => '$testPackageLibPath/features/users/domain/user.dart';
  @override
  String get source => r'''
class User {
  final String userId;
  final String orgId;
}
''';
}

@reflectiveTest
final class RecordsMapReturnTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'records_map_return';
  @override
  String get needle => 'Map<String, dynamic> coordinates';
  @override
  String get path => '$testPackageLibPath/core/geometry.dart';
  @override
  String get source => 'Map<String, dynamic> coordinates() => {};';

  Future<void> test_allowsToMapPayloadBoundary() async {
    await assertNoDiagnostics(r'''
final class RestTimerActivityData {
  const RestTimerActivityData({
    required this.exerciseName,
    required this.currentSet,
    required this.totalSets,
    required this.endTime,
  });

  final String exerciseName;
  final int currentSet;
  final int totalSets;
  final DateTime endTime;

  Map<String, dynamic> toMap() => {
    'exerciseName': exerciseName,
    'currentSet': currentSet,
    'totalSets': totalSets,
    'endTimeEpoch': endTime.millisecondsSinceEpoch ~/ 1000,
  };
}
''');
  }
}

abstract class _UiRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => uiSourceRules;
}

@reflectiveTest
final class StyleRawTokenTest extends _UiRuleTest {
  @override
  String get ruleName => 'style_raw_token';
  @override
  String get needle => 'EdgeInsets.all(8)';
  @override
  bool get lineStart => true;
  @override
  String get source => 'final inset = EdgeInsets.all(8);';

  Future<void> test_allowsRawTokensInThemeDefinitions() async {
    await assertAllows('''
class Color {
  const Color(int value);
}

abstract final class AppTheme {
  static const surface = Color(0xFF070707);
}
''', path: '$testPackageLibPath/core/theme/app_theme.dart');
  }

  Future<void> test_allowsRawTokensInTests() async {
    await assertAllows('''
class EdgeInsets {
  const EdgeInsets.all(double value);
}

void main() {
  expect(segment.padding, equals(const EdgeInsets.all(8)));
}
''', path: '$testPackageRootPath/test/core/theme/app_theme_test.dart');
  }

  Future<void> test_allowsDesignTokensWithDigits() async {
    await assertAllows('''
abstract final class DesignTokens {
  static const spacing0 = 0.0;
  static const spacingMd2 = 14.0;
  static const spacing3xl = 32.0;
}

class EdgeInsets {
  const EdgeInsets.symmetric({double? horizontal, double? vertical});
}

class SizedBox extends Widget {
  const SizedBox({double? height});
}

final padding = EdgeInsets.symmetric(vertical: DesignTokens.spacingMd2);
final spacer = SizedBox(height: DesignTokens.spacing3xl);
final empty = SizedBox(height: DesignTokens.spacing0);
''');
  }

  Future<void> test_allowsZeroAndDerivedGeometry() async {
    await assertAllows('''
abstract final class DesignTokens {
  static const spacingSm = 8.0;
}

class EdgeInsets {
  const EdgeInsets.only({double? left});
}

class Radius {
  const Radius.circular(double value);
}

final leadingPadding = EdgeInsets.only(left: index == 0 ? 0 : DesignTokens.spacingSm);
final pillRadius = Radius.circular(height / 2);
''');
  }

  Future<void> test_allowsSwitchArmIndicesNearTokenConstructors() async {
    await assertAllows('''
abstract final class DesignTokens {
  static const spacingSm = 8.0;
}

class SizedBox extends Widget {
  const SizedBox({double? height});
}

Object itemBuilder(int index) => switch (index) {
  0 => const SizedBox(height: DesignTokens.spacingSm),
  1 => const SizedBox(height: DesignTokens.spacingSm),
  2 => const Object(),
  _ => const Object(),
};
''');
  }

  Future<void> test_allowsCollectionBoundArithmeticNearTokenConstructors() async {
    await assertAllows('''
abstract final class DesignTokens {
  static const spacingLg = 16.0;
}

class EdgeInsets {
  const EdgeInsets.only({double? right});
}

final padding = EdgeInsets.only(right: i < labels.length - 1 ? DesignTokens.spacingLg : 0);
''');
  }
}

@reflectiveTest
final class StyleRawTextStyleTest extends _UiRuleTest {
  @override
  String get ruleName => 'style_raw_text_style';
  @override
  String get needle => 'TextStyle()';
  @override
  String get source => 'final style = TextStyle();';

  Future<void> test_allowsTextStyleInThemeDefinitions() async {
    await assertAllows('''
class TextStyle {
  const TextStyle({double? fontSize});
}

TextStyle appTextStyle({double fontSize = 14}) => TextStyle(fontSize: fontSize);
''', path: '$testPackageLibPath/core/theme/bento_tokens.dart');
  }

  Future<void> test_allowsTextStyleInTests() async {
    await assertAllows('''
class TextStyle {
  const TextStyle({double? fontSize});
}

void main() {
  expect(style, equals(const TextStyle(fontSize: 14)));
}
''', path: '$testPackageRootPath/test/core/theme/app_theme_test.dart');
  }
}

@reflectiveTest
final class StringsHardcodedTest extends _UiRuleTest {
  @override
  String get ruleName => 'strings_hardcoded';
  @override
  String get needle => "Text('Save'";
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class Text {
  Text(String data);
}

final text = Text('Save');
''';

  Future<void> test_allowsStringsDefinitionFiles() async {
    final filePath = '$testPackageLibPath/features/settings/settings_strings.dart';
    newFile(filePath, r'''
class Text {
  Text(String data);
}

final text = Text('Save');
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

@reflectiveTest
final class UiSnackbarBoundaryTest extends _UiRuleTest {
  @override
  String get ruleName => 'ui_snackbar_boundary';
  @override
  String get needle => 'ScaffoldMessenger.of';
  @override
  bool get lineStart => true;
  @override
  String get path => '$testPackageLibPath/features/todos/presentation/widgets/todo_view.dart';
  @override
  String get source =>
      'void build(context) { ScaffoldMessenger.of(context).showSnackBar(Object()); }';
}

@reflectiveTest
final class A11yTextScaleClampTest extends _UiRuleTest {
  @override
  String get ruleName => 'a11y_text_scale_clamp';
  @override
  String get needle => 'TextScaler.linear(1';
  @override
  String get path => '$testPackageLibPath/app.dart';
  @override
  bool get lineStart => true;
  @override
  String get source => 'final scaler = TextScaler.linear(1);';
}

@reflectiveTest
final class PerfBuildWorkTest extends _UiRuleTest {
  @override
  String get ruleName => 'perf_build_work';
  @override
  String get needle => 'items.sort()';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class Screen {
  Object build() {
    final items = <int>[2, 1];
    items.sort();
    return Object();
  }
}
''';
}

@reflectiveTest
final class PerfListviewChildrenTest extends _UiRuleTest {
  @override
  String get ruleName => 'perf_listview_children';
  @override
  String get needle => 'ListView(children';
  @override
  String get source => 'final list = ListView(children: []);';
}

abstract class _StateRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => stateSourceRules;
}

@reflectiveTest
final class StateRawResponseTest extends _StateRuleTest {
  @override
  String get ruleName => 'state_raw_response';
  @override
  String get needle => 'state = state.copyWith';
  @override
  String get source => r'''
void f(state) {
  state = state.copyWith(response: Object());
}
''';
}

@reflectiveTest
final class StateBroadInvalidationTest extends _StateRuleTest {
  @override
  String get ruleName => 'state_broad_invalidation';
  @override
  String get needle => 'ref.invalidate(provider)';
  @override
  String get source => r'''
class Todos {
  void saveTodo(context, ref, provider) {
    ref.invalidate(provider);
    context.go('/todos');
  }
}
''';
}

@reflectiveTest
final class AsyncContextMountedStyleTest extends _StateRuleTest {
  @override
  String get ruleName => 'async_context_mounted_style';
  @override
  String get needle => 'mounted) return';
  @override
  String get source => r'''
class Screen {
  Future<void> save() async {
    await Future<void>.value();
    if (!mounted) return;
  }
}
''';
}

abstract class _RouterRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => routerSourceRules;
}

@reflectiveTest
final class RouterStringNavTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_string_nav';
  @override
  String get needle => "context.go('/home')";
  @override
  String get source => r'''
void navigate(context) {
  context.go('/home');
}
''';
}

@reflectiveTest
final class RouterPopThenPushTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_pop_then_push';
  @override
  String get needle => 'context.pop()';
  @override
  String get source => r'''
void navigate(context) {
  context.pop();
  context.push('/next');
}
''';
}

@reflectiveTest
final class RouterRedirectWatchTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_redirect_watch';
  @override
  String get needle => 'ref.watch(provider)';
  @override
  String get source => r'''
final router = GoRouter(
  redirect: () {
    ref.watch(provider);
    return null;
  },
);
''';
}

@reflectiveTest
final class RouterRedirectLoadingBounceTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_redirect_loading_bounce';
  @override
  String get needle => "if (isLoading) return '/loading';";
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
final router = GoRouter(
  redirect: () {
    if (isLoading) return '/loading';
    return null;
  },
);
''';
}

abstract class _ShowcaseRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => showcaseSourceRules;
}

@reflectiveTest
final class ShowcaseListenManualHandleTest extends _ShowcaseRuleTest {
  @override
  String get ruleName => 'showcase_listen_manual_handle';
  @override
  String get needle => 'ref.listenManual';
  @override
  String get source => 'void f(ref, provider) { ref.listenManual(provider, (prev, next) {}); }';
}

@reflectiveTest
final class ShowcasePrevNullGuardTest extends _ShowcaseRuleTest {
  @override
  String get ruleName => 'showcase_prev_null_guard';
  @override
  String get needle => 'prev != null';
  @override
  String get source => r'''
void f(prev, showcase) {
  if (prev != null) {
    showcase.start();
  }
}
''';
}

@reflectiveTest
final class ShowcaseDefaultScopeTest extends _ShowcaseRuleTest {
  @override
  String get ruleName => 'showcase_default_scope';
  @override
  String get needle => 'ShowcaseView.register';
  @override
  String get source => 'void f() { ShowcaseView.register(); }';
}

@reflectiveTest
final class ShowcaseDisposeOnTapTest extends _ShowcaseRuleTest {
  @override
  String get ruleName => 'showcase_dispose_on_tap';
  @override
  String get needle => 'disposeOnTap: true';
  @override
  String get source => 'final showcase = Showcase(disposeOnTap: true);';
}

abstract class _NotifierRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => notifierSourceRules;
}

abstract class _NotifierFixtureTest extends _NotifierRuleTest {
  @override
  String get needle => 'void updateTodo';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class Notifier<T> {
  Ref get ref => Ref();
}

class Ref {
  Object watch(Object provider) => Object();
}

class Repository {
  void save() {}
}

final provider = Object();

class TodosNotifier extends Notifier<int> {
  final Repository _repository = Repository();

  void updateTodo() {
    ref.watch(provider);
    _repository.save();
  }
}
''';
}

@reflectiveTest
final class NotifierEnsureDepsTest extends _NotifierFixtureTest {
  @override
  String get ruleName => 'notifier_ensure_deps';
}

@reflectiveTest
final class NotifierWatchMethodTest extends _NotifierFixtureTest {
  @override
  String get ruleName => 'notifier_watch_method';
}

abstract class _ServicesMixinsRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => servicesMixinsSourceRules;
}

@reflectiveTest
final class ServiceSingletonTest extends _ServicesMixinsRuleTest {
  @override
  String get ruleName => 'service_singleton';
  @override
  String get needle => 'static final instance';
  @override
  String get source => 'class UserService { static final instance = UserService(); }';
}

@reflectiveTest
final class MixinMixinClassTest extends _ServicesMixinsRuleTest {
  @override
  String get ruleName => 'mixin_mixin_class';
  @override
  String get needle => 'mixin class Trackable';
  @override
  String get source => 'mixin class Trackable {}';
}

@reflectiveTest
final class MixinNameSuffixTest extends _ServicesMixinsRuleTest {
  @override
  String get ruleName => 'mixin_name_suffix';
  @override
  String get needle => 'mixin class Trackable';
  @override
  String get source => 'mixin class Trackable {}';
}

@reflectiveTest
final class MixinMutableStateTest extends _ServicesMixinsRuleTest {
  @override
  String get ruleName => 'mixin_mutable_state';
  @override
  String get needle => 'var count = 0';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
mixin class Trackable {
  var count = 0;
}
''';

  Future<void> test_allowsPrivateLifecycleFieldsInConsumerStateMixin() async {
    final filePath = '$testPackageLibPath/core/mixins/showcase_screen_mixin.dart';
    newFile(filePath, r'''
class StatefulWidget {}
class State<T extends StatefulWidget> {}
class ConsumerStatefulWidget extends StatefulWidget {}
class ConsumerState<T extends ConsumerStatefulWidget> extends State<T> {}

mixin ShowcaseScreenMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _hasAttemptedTour = false;
  bool _needsShowcaseRetry = false;
  bool _dependenciesInitialised = false;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsPublicMutableFieldInStateMixin() async {
    final filePath = '$testPackageLibPath/core/mixins/scroll_mixin.dart';
    const source = r'''
class StatefulWidget {}
class State<T extends StatefulWidget> {}

mixin ScrollMixin<T extends StatefulWidget> on State<T> {
  bool isReady = false;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'bool isReady = false', ruleName, lineStart: true),
    ]);
  }

  Future<void> test_reportsPrivateMutableFieldInUnconstrainedMixin() async {
    final filePath = '$testPackageLibPath/core/mixins/cache_mixin.dart';
    const source = r'''
mixin CacheMixin {
  bool _isReady = false;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'bool _isReady = false', ruleName, lineStart: true),
    ]);
  }
}

abstract class _DataCrashRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => dataCrashSourceRules;
}

@reflectiveTest
final class DataLogRethrowTest extends _DataCrashRuleTest {
  @override
  String get ruleName => 'data_log_rethrow';
  @override
  String get needle => 'log(error);';
  @override
  bool get lineStart => true;
  @override
  String get path => '$testPackageLibPath/features/todos/data/repositories/todo_repository.dart';
  @override
  String get source => r'''
void log(Object value) {}

void load() {
  try {
    throw Object();
  } catch (error) {
    log(error);
    rethrow;
  }
}
''';
}

@reflectiveTest
final class CrashPossiblePiiTest extends _DataCrashRuleTest {
  @override
  String get ruleName => 'crash_possible_pii';
  @override
  String get needle => 'Crash.error(email)';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class Crash {
  static void error(Object value) {}
}

final email = Object();

void recordCrash() {
  Crash.error(email);
}
''';
}

abstract class _TestRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => testSourceRules;
}

abstract class _TestFileRuleTest extends _TestRuleTest {
  @override
  String get path => '$testPackageRootPath/test/widget_test.dart';
}

@reflectiveTest
final class TestProviderContainerTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_provider_container';
  @override
  String get needle => 'ProviderContainer()';
  @override
  String get source => 'void main() { ProviderContainer(); }';
}

@reflectiveTest
final class TestUncontrolledScopeTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_uncontrolled_scope';
  @override
  String get needle => 'ProviderScope()';
  @override
  String get source => 'void main() { ProviderScope(); }';
}

@reflectiveTest
final class TestCreateContainerTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_create_container';
  @override
  String get needle => 'createContainer()';
  @override
  String get source => 'void main() { createContainer(); }';
}

@reflectiveTest
final class TestMockConcreteTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_mock_concrete';
  @override
  String get needle => 'class MockUserRepository';
  @override
  String get source => 'class MockUserRepository extends Mock implements UserRepository {}';

  Future<void> test_allowsExternalSdkBoundaryMocks() async {
    final filePath = '$testPackageRootPath/test/helpers/appwrite_test_utils.dart';
    newFile(filePath, r'''
class Mock {}
class TablesDB {}
class Account {}
class Teams {}
class MockTablesDB extends Mock implements TablesDB {}
class MockAccount extends Mock implements Account {}
class MockTeams extends Mock implements Teams {}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsExternalPluginControllerMocks() async {
    final filePath = '$testPackageRootPath/test/core/widgets/exercise_demo_sheet_test.dart';
    newFile(filePath, r'''
class Mock {}
class YoutubePlayerController {}
class YoutubePlayerValue {}
class MockYoutubePlayerController extends Mock implements YoutubePlayerController {}
class MockYoutubePlayerValue extends Mock implements YoutubePlayerValue {}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

@reflectiveTest
final class TestPumpAndSettleTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_pump_and_settle';
  @override
  String get needle => 'pumpAndSettle()';
  @override
  String get source => 'void main(tester) { tester.pumpAndSettle(); }';

  Future<void> test_allowsExplicitDurationArgument() async {
    final filePath = '$testPackageRootPath/test/widget_test.dart';
    newFile(filePath, r'''
void main(tester) {
  tester.pumpAndSettle(const Duration(seconds: 10));
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

@reflectiveTest
final class TestTapAtTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_tap_at';
  @override
  String get needle => 'tapAt(Object())';
  @override
  String get source => 'void main(tester) { tester.tapAt(Object()); }';
}

@reflectiveTest
final class TestInlineValueKeyTest extends _TestRuleTest {
  @override
  String get ruleName => 'test_inline_value_key';
  @override
  String get needle => "ValueKey('todo-row')";
  @override
  String get source => r'''
class ValueKey<T> {
  const ValueKey(T value);
}

void main() {
  const ValueKey('todo-row');
}
''';
}

@reflectiveTest
final class TestFirstMatchFinderTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_first_match_finder';
  @override
  String get needle => 'find.byIcon';
  @override
  bool get lineStart => true;
  @override
  String get source => 'void main() { find.byIcon(Object()); }';

  Future<void> test_allowsIterableFirstAccess() async {
    final filePath = '$testPackageRootPath/test/widget_test.dart';
    newFile(filePath, r'''
void main() {
  final values = [1, 2, 3];
  final first = values.first;
  first.toString();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}
