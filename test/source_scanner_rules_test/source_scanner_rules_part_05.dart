part of '../source_scanner_rules_test.dart';

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

  Future<void> _allowsFeatureWidgetTestFiles() async {
    final filePath = '$testPackageRootPath/test/features/todos/widgets/todo_widget_test.dart';
    newFile(filePath, 'class TodoWidgetTest {}');

    await assertNoDiagnosticsInFile(filePath);
  }
}

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

  Future<void> _reportsNavigationProviderRead() async {
    final analyzedSource = _analyzedSource(r'''
void build(ref, context) {
  ref.read(featureNavigationCoordinatorProvider).present(context, NumberPickerModalRoute());
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/core/widgets/molecules/number_stepper.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'ref.read', ruleName)]);
  }

  Future<void> _reportsSharedOrganismProviderWatch() async {
    final analyzedSource = _analyzedSource(r'''
void build(ref, provider) {
  ref.watch(provider);
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/core/widgets/organisms/order_summary.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'ref.watch', ruleName)]);
  }

  Future<void> _allowsProviderAccessInScreens() async {
    await assertAllows(r'''
void build(ref, provider) {
  ref.watch(provider);
}
''', path: '$testPackageLibPath/features/orders/presentation/screens/orders_screen.dart');
  }
}

final class AtomicPageConsumerWidgetTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'atomic_page_consumer_widget';
  @override
  String get needle => 'OrdersScreen extends StatelessWidget';
  @override
  String get path => '$testPackageLibPath/features/orders/presentation/screens/orders_screen.dart';
  @override
  String get source => r'''
import 'package:flutter/widgets.dart';

class OrdersScreen extends StatelessWidget {}
''';

  @override
  void setUp() {
    newPackage('flutter_riverpod').addFile('lib/flutter_riverpod.dart', r'''
import 'package:flutter/widgets.dart';

abstract class ConsumerStatefulWidget extends StatefulWidget {}
abstract class ConsumerWidget extends ConsumerStatefulWidget {}
abstract class ConsumerState<T extends ConsumerStatefulWidget> extends State<T> {}
''');
    super.setUp();
  }

  @override
  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
abstract class Widget {}
abstract class StatelessWidget extends Widget {}
abstract class StatefulWidget extends Widget {}
abstract class State<T extends StatefulWidget> {}
''');
  }

  void _reportsAsError() {
    expect((rule as ScannerRule).diagnosticCode.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> _reportsStatefulScreen() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:flutter/widgets.dart';

class OrdersScreen extends StatefulWidget {}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'OrdersScreen extends StatefulWidget', ruleName),
    ]);
  }

  Future<void> _allowsConsumerScreens() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrdersScreen extends ConsumerWidget {}

class OrderEditorScreen extends ConsumerStatefulWidget {}

class _OrderEditorScreenState extends ConsumerState<OrderEditorScreen> {}

class _OrdersBody extends StatelessWidget {}
''', path: path);
  }

  Future<void> _allowsStatelessWidgetsOutsideScreens() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

class OrderTile extends StatelessWidget {}
''', path: '$testPackageLibPath/features/orders/presentation/widgets/order_tile.dart');
  }
}

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

  Future<void> _reportsFreezedRawIntIds() async {
    const source = r'''
// ignore_for_file: redirect_to_non_class
class Order {
  const factory Order({required int userId, required int productId}) = _Order;
}
''';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [
      compatLint(source, '  const factory Order', ruleName, lineStart: true),
    ]);
  }

  Future<void> _allowsTypedIdsAndSingleRawId() async {
    await assertAllows(r'''
// ignore_for_file: redirect_to_non_class
extension type UserId(int value) {}
class Order {
  const factory Order({required UserId userId, required int productId, int? count}) = _Order;
}
''', path: path);
  }
}

final class RecordsMapReturnTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'records_map_return';
  @override
  String get needle => 'Map<String, dynamic> coordinates';
  @override
  String get path => '$testPackageLibPath/core/geometry.dart';
  @override
  String get source => 'Map<String, dynamic> coordinates() => {};';

  Future<void> _allowsToMapPayloadBoundary() async {
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

  Future<void> _allowsObjectMapDeclarations() async {
    await assertAllows(r'''
void read(Map<String, Object?> payload) {
  payload['ok'];
}
''');
  }

  Future<void> _allowsDynamicMapCasts() async {
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

final class StyleRawTokenTest extends _UiRuleTest {
  @override
  String get ruleName => 'style_raw_token';
  @override
  String get needle => 'EdgeInsets.all(8)';
  @override
  bool get lineStart => true;
  @override
  String get source => 'final inset = EdgeInsets.all(8);';

  void _reportsAsError() {
    expect((rule as ScannerRule).diagnosticCode.severity, DiagnosticSeverity.ERROR);
  }

  @override
  bool get addFlutterPackageDep => true;

  @override
  void _addFlutterPackage() {}

  Future<void> _reportsResolvedRawColors() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final material = Colors.red;
final cupertino = CupertinoColors.systemBlue;
const hex = Color(0xFF123456);
const argb = Color.fromARGB(255, 1, 2, 3);
const rgbo = Color.fromRGBO(1, 2, 3, 0.5);
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/core/widgets/atoms/palette_atom.dart';
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      for (final needle in [
        'final material',
        'final cupertino',
        'const hex',
        'const argb',
        'const rgbo',
      ])
        compatLint(analyzedSource, needle, ruleName, lineStart: true),
    ]);
  }

  Future<void> _reportsResolvedRawSizes() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:flutter/material.dart';

extension on TextStyle {
  TextStyle copyWith({double? fontSize}) => this;
}

Widget icon() => const Icon(null, size: 24);
TextStyle? body(TextStyle? base) => base?.copyWith(fontSize: 18);
const side = BorderSide(width: 3);
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/core/widgets/atoms/size_atom.dart';
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      for (final needle in ['Widget icon()', 'TextStyle? body', 'const side'])
        compatLint(analyzedSource, needle, ruleName, lineStart: true),
    ]);
  }

  Future<void> _allowsTokenSizesAndUnrelatedPalettes() async {
    await assertAllows(r'''
import 'package:flutter/material.dart';

abstract final class AppTokens {
  static const double iconMd = 24;
  static const double fontBody = 14;
  static const double hairline = 1;
}

abstract final class Palette {
  static const red = 1;
}

extension on TextStyle {
  TextStyle copyWith({double? fontSize}) => this;
}

Widget icon() => const Icon(null, size: AppTokens.iconMd);
TextStyle body(TextStyle base) => base.copyWith(fontSize: AppTokens.fontBody);
const side = BorderSide(width: AppTokens.hairline);
const none = BorderSide(width: 0);
final unrelated = Palette.red;
''', path: '$testPackageLibPath/core/widgets/atoms/token_atom.dart');
  }

  Future<void> _allowsRawTokensInThemeDefinitions() async {
    await assertAllows('''
class Color {
  const Color(int value);
}

abstract final class AppTheme {
  static const surface = Color(0xFF070707);
}
''', path: '$testPackageLibPath/core/theme/app_theme.dart');
  }

  Future<void> _allowsRawTokensInTests() async {
    await assertAllows('''
class EdgeInsets {
  const EdgeInsets.all(double value);
}

void main() {
  expect(segment.padding, equals(const EdgeInsets.all(8)));
}
''', path: '$testPackageRootPath/test/core/theme/app_theme_test.dart');
  }

  Future<void> _allowsDesignTokensWithDigits() async {
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

  Future<void> _allowsZeroAndDerivedGeometry() async {
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

  Future<void> _allowsSwitchArmIndicesNearTokenConstructors() async {
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

  Future<void> _allowsCollectionBoundArithmeticNearTokenConstructors() async {
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

  Future<void> _allowsTokenNamesEndingInDigits() async {
    await assertAllows('''
abstract final class Spacing {
  static const s8 = 8.0;
  static const s24 = 24.0;
}

class EdgeInsets {
  const EdgeInsets.all(double value);
}

EdgeInsets padding(bool isExpanded) => EdgeInsets.all(isExpanded ? Spacing.s24 : Spacing.s8);
''');
  }

  Future<void> _allowsLiteralsOutsideTheStyleValue() async {
    await assertAllows('''
abstract final class Spacing {
  static const s8 = 8.0;
  static const s24 = 24.0;
}

class EdgeInsets {
  const EdgeInsets.all(double value);
}

EdgeInsets padding(int count) => EdgeInsets.all(count > 1 ? Spacing.s24 : Spacing.s8);
final spacer = SizedBox(height: Spacing.s8, child: Text('x', maxLines: 2));
''');
  }

  Future<void> _reportsRawLiteralOnWrappedArgumentLine() async {
    final analyzedSource = _analyzedSource('''
class EdgeInsets {
  const EdgeInsets.symmetric({double? horizontal});
}

final padding = EdgeInsets.symmetric(
  horizontal: 16,
);
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'horizontal: 16', ruleName, lineStart: true),
    ]);
  }
}

final class StyleRawTextStyleTest extends _UiRuleTest {
  @override
  String get ruleName => 'style_raw_text_style';
  @override
  String get needle => 'TextStyle()';
  @override
  String get source => 'final style = TextStyle();';

  void _reportsAsError() {
    expect((rule as ScannerRule).diagnosticCode.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> _allowsTextStyleInThemeDefinitions() async {
    await assertAllows('''
class TextStyle {
  const TextStyle({double? fontSize});
}

TextStyle appTextStyle({double fontSize = 14}) => TextStyle(fontSize: fontSize);
''', path: '$testPackageLibPath/core/theme/bento_tokens.dart');
  }

  Future<void> _allowsTextStyleInTests() async {
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

final class StringsHardcodedTest extends _UiRuleTest {
  @override
  String get ruleName => 'strings_hardcoded';

  Future<void> _severityIsError() async {
    expect((rule as ScannerRule).diagnosticCode.severity, DiagnosticSeverity.ERROR);
  }

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

  Future<void> _reportsStringsDefinitionFiles() async {
    final filePath = '$testPackageLibPath/features/settings/settings_strings.dart';
    const source = r'''
class Text {
  Text(String data);
}

final text = Text('Save');
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, "final text = Text('Save')", ruleName),
    ]);
  }

  Future<void> _allowsSampleTextInsideResolvedPreview() async {
    await assertAllows(r'''
import 'package:flutter/widget_previews.dart';

class Text {
  Text(String data);
}

@Preview(name: 'Card')
Text cardPreview() => Text('Suture Kit');
''', path: '$testPackageLibPath/features/probe/presentation/widgets/card_preview.dart');
  }

  Future<void> _reportsTextUnderLookalikePreviewAnnotation() async {
    final filePath = '$testPackageLibPath/features/probe/presentation/widgets/card_preview.dart';
    final analyzedSource = _analyzedSource(r'''
class Preview {
  const Preview({String? name});
}

class Text {
  Text(String data);
}

@Preview(name: 'Card')
Text cardPreview() => Text('Suture Kit');
''', addIgnorePrefix: addIgnorePrefix);
    newFile(filePath, analyzedSource);

    await assertDiagnosticsInFile(filePath, [
      compatLint(
        analyzedSource,
        "Text cardPreview() => Text('Suture Kit')",
        ruleName,
        lineStart: true,
      ),
    ]);
  }

  Future<void> _allowsHardcodedLookingTextInsideDebugPrintWithParen() async {
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

final class L10nContextDirectAccessTest extends _UiRuleTest {
  @override
  String get ruleName => 'l10n_context_direct_access';

  Future<void> _severityIsError() async {
    expect((rule as ScannerRule).diagnosticCode.severity, DiagnosticSeverity.ERROR);
  }

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

  Future<void> _allowsLocalBinding() async {
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

  Future<void> _reportsSplitAccess() async {
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

  Future<void> _allowsTests() async {
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

  @override
  void setUp() {
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
abstract class AnyNotifier<StateT, ValueT> {
  late StateT state;
}
abstract class $Notifier<StateT> extends AnyNotifier<StateT, StateT> {}
abstract class Notifier<T> extends $Notifier<T> {}
''');
    super.setUp();
  }

  static const _snackBarUtils = '''
abstract final class SnackBarUtils {
  static void showError(String message) {}
}
''';

  // context-ui.md:69: do not call SnackBarUtils.show... from notifiers.
  Future<void> _reportsCodegenNotifierSnackBarUtilsCall() async {
    final source = _analyzedSource('''
import 'package:riverpod/riverpod.dart';

$_snackBarUtils
abstract class _\$ProfileNotifier extends \$Notifier<int> {}

class ProfileNotifier extends _\$ProfileNotifier {
  void save() {
    SnackBarUtils.showError('Save failed');
  }
}
''', addIgnorePrefix: true);
    final filePath =
        '$testPackageLibPath/features/profile/presentation/providers/profile_notifier.dart';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, "SnackBarUtils.showError('Save failed')", ruleName),
    ]);
  }

  // context-ui.md:69: do not call SnackBarUtils.show... from repositories.
  Future<void> _reportsRepositorySnackBarUtilsCall() async {
    final source = _analyzedSource('''
$_snackBarUtils
final class ProfileRepositoryImpl {
  Future<void> save() async {
    SnackBarUtils.showError('Save failed');
  }
}
''', addIgnorePrefix: true);
    final filePath =
        '$testPackageLibPath/features/profile/data/repositories/profile_repository_impl.dart';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, "SnackBarUtils.showError('Save failed')", ruleName),
    ]);
  }

  Future<void> _allowsNonSnackBarUtilsShowInNotifier() async {
    await assertAllows('''
import 'package:riverpod/riverpod.dart';

abstract final class Toast {
  static void showError(String message) {}
}

abstract class _\$ProfileNotifier extends \$Notifier<int> {}

class ProfileNotifier extends _\$ProfileNotifier {
  void save() {
    Toast.showError('Save failed');
  }
}
''', path: '$testPackageLibPath/features/profile/presentation/providers/profile_notifier.dart');
  }

  // context-ui.md:69: the UI helper may wrap SnackBarUtils.
  Future<void> _allowsUiHelperWrappingSnackBarUtils() async {
    await assertAllows('''
$_snackBarUtils
void showProfileSaveFailedSnackBar(String message) {
  SnackBarUtils.showError(message);
}
''', path: '$testPackageLibPath/core/utils/profile_snack_bars.dart');
  }
}

void _defineSourceScannerRulesPart05Tests() {
  analysisRuleSuite<ArchWidgetPathTest>('ArchWidgetPathTest', ArchWidgetPathTest.new, {
    'test_allowsFeatureWidgetTestFiles': (t) => t._allowsFeatureWidgetTestFiles(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<AtomicProviderAccessTest>(
    'AtomicProviderAccessTest',
    AtomicProviderAccessTest.new,
    {
      'test_reportsNavigationProviderRead': (t) => t._reportsNavigationProviderRead(),
      'test_reportsSharedOrganismProviderWatch': (t) => t._reportsSharedOrganismProviderWatch(),
      'test_allowsProviderAccessInScreens': (t) => t._allowsProviderAccessInScreens(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<AtomicPageConsumerWidgetTest>(
    'AtomicPageConsumerWidgetTest',
    AtomicPageConsumerWidgetTest.new,
    {
      'test_reportsAsError': (t) async => t._reportsAsError(),
      'test_reportsStatefulScreen': (t) => t._reportsStatefulScreen(),
      'test_allowsConsumerScreens': (t) => t._allowsConsumerScreens(),
      'test_allowsStatelessWidgetsOutsideScreens': (t) => t._allowsStatelessWidgetsOutsideScreens(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<TypedIdRawIdTest>('TypedIdRawIdTest', TypedIdRawIdTest.new, {
    'test_reportsFreezedRawIntIds': (t) => t._reportsFreezedRawIntIds(),
    'test_allowsTypedIdsAndSingleRawId': (t) => t._allowsTypedIdsAndSingleRawId(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<RecordsMapReturnTest>('RecordsMapReturnTest', RecordsMapReturnTest.new, {
    'test_allowsToMapPayloadBoundary': (t) => t._allowsToMapPayloadBoundary(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<ObjectMapCastTest>('ObjectMapCastTest', ObjectMapCastTest.new, {
    'test_allowsObjectMapDeclarations': (t) => t._allowsObjectMapDeclarations(),
    'test_allowsDynamicMapCasts': (t) => t._allowsDynamicMapCasts(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<StyleRawTokenTest>('StyleRawTokenTest', StyleRawTokenTest.new, {
    'test_reportsAsError': (t) async => t._reportsAsError(),
    'test_reportsResolvedRawColors': (t) => t._reportsResolvedRawColors(),
    'test_reportsResolvedRawSizes': (t) => t._reportsResolvedRawSizes(),
    'test_allowsTokenSizesAndUnrelatedPalettes': (t) => t._allowsTokenSizesAndUnrelatedPalettes(),
    'test_allowsRawTokensInThemeDefinitions': (t) => t._allowsRawTokensInThemeDefinitions(),
    'test_allowsRawTokensInTests': (t) => t._allowsRawTokensInTests(),
    'test_allowsDesignTokensWithDigits': (t) => t._allowsDesignTokensWithDigits(),
    'test_allowsZeroAndDerivedGeometry': (t) => t._allowsZeroAndDerivedGeometry(),
    'test_allowsSwitchArmIndicesNearTokenConstructors': (t) =>
        t._allowsSwitchArmIndicesNearTokenConstructors(),
    'test_allowsCollectionBoundArithmeticNearTokenConstructors': (t) =>
        t._allowsCollectionBoundArithmeticNearTokenConstructors(),
    'test_allowsTokenNamesEndingInDigits': (t) => t._allowsTokenNamesEndingInDigits(),
    'test_allowsLiteralsOutsideTheStyleValue': (t) => t._allowsLiteralsOutsideTheStyleValue(),
    'test_reportsRawLiteralOnWrappedArgumentLine': (t) =>
        t._reportsRawLiteralOnWrappedArgumentLine(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<StyleRawTextStyleTest>('StyleRawTextStyleTest', StyleRawTextStyleTest.new, {
    'test_reportsAsError': (t) async => t._reportsAsError(),
    'test_allowsTextStyleInThemeDefinitions': (t) => t._allowsTextStyleInThemeDefinitions(),
    'test_allowsTextStyleInTests': (t) => t._allowsTextStyleInTests(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<StringsHardcodedTest>('StringsHardcodedTest', StringsHardcodedTest.new, {
    'test_severityIsError': (t) => t._severityIsError(),
    'test_reportsStringsDefinitionFiles': (t) => t._reportsStringsDefinitionFiles(),
    'test_allowsSampleTextInsideResolvedPreview': (t) => t._allowsSampleTextInsideResolvedPreview(),
    'test_reportsTextUnderLookalikePreviewAnnotation': (t) =>
        t._reportsTextUnderLookalikePreviewAnnotation(),
    'test_allowsHardcodedLookingTextInsideDebugPrintWithParen': (t) =>
        t._allowsHardcodedLookingTextInsideDebugPrintWithParen(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<L10nContextDirectAccessTest>(
    'L10nContextDirectAccessTest',
    L10nContextDirectAccessTest.new,
    {
      'test_severityIsError': (t) => t._severityIsError(),
      'test_allowsLocalBinding': (t) => t._allowsLocalBinding(),
      'test_reportsSplitAccess': (t) => t._reportsSplitAccess(),
      'test_allowsTests': (t) => t._allowsTests(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<UiSnackbarBoundaryTest>('UiSnackbarBoundaryTest', UiSnackbarBoundaryTest.new, {
    'test_reportsCodegenNotifierSnackBarUtilsCall': (t) =>
        t._reportsCodegenNotifierSnackBarUtilsCall(),
    'test_reportsRepositorySnackBarUtilsCall': (t) => t._reportsRepositorySnackBarUtilsCall(),
    'test_allowsNonSnackBarUtilsShowInNotifier': (t) => t._allowsNonSnackBarUtilsShowInNotifier(),
    'test_allowsUiHelperWrappingSnackBarUtils': (t) => t._allowsUiHelperWrappingSnackBarUtils(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
}
