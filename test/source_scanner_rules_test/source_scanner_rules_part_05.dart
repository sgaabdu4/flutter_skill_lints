// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

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

  Future<void> test_reportsNavigationProviderRead() async {
    final analyzedSource = _analyzedSource(r'''
void build(ref, context) {
  ref.read(featureNavigationCoordinatorProvider).present(context, NumberPickerModalRoute());
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/core/widgets/molecules/number_stepper.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'ref.read', ruleName)]);
  }
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

@reflectiveTest
final class ObjectMapCastTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'avoid_object_map_cast';
  @override
  String get needle => 'as Map<String, Object?>';
  @override
  String get source => r'''
void read(Object? value) {
  final payload = value as Map<String, Object?>;
}
''';

  Future<void> test_allowsObjectMapDeclarations() async {
    await assertAllows(r'''
void read(Map<String, Object?> payload) {
  payload['ok'];
}
''');
  }

  Future<void> test_allowsDynamicMapCasts() async {
    await assertAllows(r'''
void read(Object? value) {
  final payload = value as Map<String, dynamic>;
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

  Future<void> test_allowsHardcodedLookingTextInsideDebugPrintWithParen() async {
    await assertAllows(r'''
class Text {
  Text(String data);
}

void log() {
  debugPrint(") Text('Save')");
}
''');
  }
}

@reflectiveTest
final class L10nContextDirectAccessTest extends _UiRuleTest {
  @override
  String get ruleName => 'l10n_context_direct_access';
  @override
  String get needle => 'context.l10n.deleteTitle';
  @override
  String get source => r'''
class Text {
  Text(String data);
}

void build(context) {
  Text(context.l10n.deleteTitle);
}
''';

  Future<void> test_allowsLocalBinding() async {
    await assertAllows(r'''
class Text {
  Text(String data);
}

void build(context) {
  final l10n = context.l10n;
  Text(l10n.deleteTitle);
}
''');
  }

  Future<void> test_reportsSplitAccess() async {
    final analyzedSource = _analyzedSource(r'''
class Text {
  Text(String data);
}

void build(context) {
  Text(
    context
        .l10n
        .deleteTitle,
  );
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'context\n        .l10n', ruleName),
    ]);
  }

  Future<void> test_allowsTests() async {
    final filePath = '$testPackageRootPath/test/widgets/delete_button_test.dart';
    newFile(
      filePath,
      _analyzedSource(r'''
class Text {
  Text(String data);
}

void build(context) {
  Text(context.l10n.deleteTitle);
}
''', addIgnorePrefix: addIgnorePrefix),
    );

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
final class WidgetInfraDependencyBoundaryTest extends _UiRuleTest {
  @override
  String get ruleName => 'widget_infra_dependency_boundary';
  @override
  String get needle => 'cacheManager: DefaultCacheManager';
  @override
  String get path => '$testPackageLibPath/features/social/presentation/widgets/avatar.dart';
  @override
  String get source => r'''
class DefaultCacheManager {}

class Avatar extends StatelessWidget {
  Widget build(BuildContext context) => CachedNetworkAvatar(
    url: avatarUrl,
    cacheManager: DefaultCacheManager(),
  );
}
''';

  Future<void> test_reportsInfraField() async {
    final analyzedSource = _analyzedSource(r'''
class BaseCacheManager {}

class Avatar extends StatelessWidget {
  final BaseCacheManager cacheManager;

  const Avatar({required this.cacheManager});
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'BaseCacheManager cacheManager', ruleName),
    ]);
  }

  Future<void> test_reportsTypedConstructorParam() async {
    final analyzedSource = _analyzedSource(r'''
class UserService {}

class Avatar extends StatelessWidget {
  const Avatar({required UserService userService});
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'UserService userService', ruleName),
    ]);
  }

  Future<void> test_reportsLocalInfraConstructor() async {
    final analyzedSource = _analyzedSource(r'''
class DefaultCacheManager {}

class Avatar extends StatelessWidget {
  Widget build(BuildContext context) {
    final cacheManager = DefaultCacheManager();
    return CachedNetworkAvatar(cacheManager: cacheManager);
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'final cacheManager', ruleName),
    ]);
  }

  Future<void> test_allowsInfraWiringOutsideUiFiles() async {
    await assertAllows(r'''
class BaseCacheManager {}
class DefaultCacheManager extends BaseCacheManager {}

final BaseCacheManager cacheManager = DefaultCacheManager();
''', path: '$testPackageLibPath/core/utils/cached_avatar_bytes_loader.dart');
  }

  Future<void> test_allowsPrimitiveWidgetProps() async {
    await assertAllows(r'''
class Avatar extends StatelessWidget {
  final String seed;
  final double size;
  final VoidCallback? onTap;

  const Avatar({required this.seed, required this.size, this.onTap});
}
''', path: path);
  }
}

@reflectiveTest
final class WidgetTopLevelFunctionBoundaryTest extends _UiRuleTest {
  @override
  String get ruleName => 'widget_top_level_function_boundary';
  @override
  String get needle => 'Future<void> createSquad';
  @override
  bool get lineStart => true;
  @override
  String get path => '$testPackageLibPath/features/social/presentation/widgets/squad_actions.dart';
  @override
  String get source => r'''
Future<void> createSquad(BuildContext context, WidgetRef ref) async {}
''';

  Future<void> test_reportsPrivateTopLevelHelper() async {
    final analyzedSource = _analyzedSource(r'''
bool _canShowAction(Object state) => true;
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'bool _canShowAction', ruleName, lineStart: true),
    ]);
  }

  Future<void> test_allowsStaticClassApi() async {
    await assertAllows(r'''
abstract final class SquadActions {
  static Future<void> createSquad(BuildContext context, WidgetRef ref) async {}
}
''', path: path);
  }

  Future<void> test_allowsProviderFiles() async {
    await assertAllows(r'''
Future<void> createSquad(BuildContext context, WidgetRef ref) async {}
''', path: '$testPackageLibPath/features/social/presentation/notifiers/squad_actions.dart');
  }
}

@reflectiveTest
final class WidgetActionsNamespaceBoundaryTest extends _UiRuleTest {
  @override
  String get ruleName => 'widget_actions_namespace_boundary';
  @override
  String get needle => 'class SquadActions';
  @override
  String get path => '$testPackageLibPath/features/social/presentation/widgets/squad_actions.dart';
  @override
  String get source => r'''
abstract final class SquadActions {
  static Future<void> createSquad(BuildContext context, WidgetRef ref) async {
    ref.read(squadProvider.notifier).createSquad();
  }
}
''';

  Future<void> test_allowsCoordinatorActionNamespace() async {
    await assertAllows(r'''
abstract final class SquadActions {
  static Future<void> createSquad(BuildContext context, WidgetRef ref) async {
    ref.read(squadProvider.notifier).createSquad();
  }
}
''', path: '$testPackageLibPath/features/social/presentation/coordinators/squad_actions.dart');
  }

  Future<void> test_allowsRenderOnlyWidgetActions() async {
    await assertAllows(r'''
abstract final class EmptySquadActions {
  static Widget iconButton(VoidCallback onTap) => IconButton(onPressed: onTap);
}
''', path: '$testPackageLibPath/features/social/presentation/widgets/empty_squad_actions.dart');
  }
}
