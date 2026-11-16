part of '../source_scanner_rules_test.dart';

final class _TestMockConcreteTest extends _TestFileRuleTest {
  static Map<String, Future<void> Function(_TestMockConcreteTest)> get _allCases =>
      caseSet<_TestMockConcreteTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsAbstractContractsWithoutNamingPrefix': (t) =>
              t._allowsAbstractContractsWithoutNamingPrefix(),
          'test_reportsConcreteContractWithInterfacePrefix': (t) =>
              t._reportsConcreteContractWithInterfacePrefix(),
          'test_reportsExternalSdkPartDeclarations': (t) => t._reportsExternalSdkPartDeclarations(),
          'test_allowsExternalAbstractPartDeclaration': (t) =>
              t._allowsExternalAbstractPartDeclaration(),
          'test_reportsExternalPluginControllerMocks': (t) =>
              t._reportsExternalPluginControllerMocks(),
          'test_localConcreteSdkNameStillReports': (t) => t._localConcreteSdkNameStillReports(),
          'test_localFunctionsAndStorageConcreteNamesStillReport': (t) =>
              t._localFunctionsAndStorageConcreteNamesStillReport(),
          'test_allowsLocalFunctionsAndStorageInterfaces': (t) =>
              t._allowsLocalFunctionsAndStorageInterfaces(),
          'test_concreteAliasStillReports': (t) => t._concreteAliasStillReports(),
          'test_reportsFakeOfConcreteContract': (t) => t._reportsFakeOfConcreteContract(),
          'test_allowsSkillFakeOfInterface': (t) => t._allowsSkillFakeOfInterface(),
          'test_allowsLocalClassNamedMock': (t) => t._allowsLocalClassNamedMock(),
        },
      );

  @override
  void setUp() {
    final appwrite = newPackage('appwrite');
    appwrite.addFile('lib/appwrite.dart', r'''
part 'services/account.dart';
part 'services/functions.dart';
part 'services/storage.dart';
part 'services/tables_db.dart';
part 'services/teams.dart';
part 'services/service.dart';
''');
    appwrite.addFile(
      'lib/services/service.dart',
      "part of '../appwrite.dart'; abstract class Service { void call(); }",
    );
    appwrite.addFile('lib/services/account.dart', "part of '../appwrite.dart'; class Account {}");
    appwrite.addFile(
      'lib/services/functions.dart',
      "part of '../appwrite.dart'; class Functions {}",
    );
    appwrite.addFile('lib/services/storage.dart', "part of '../appwrite.dart'; class Storage {}");
    appwrite.addFile(
      'lib/services/tables_db.dart',
      "part of '../appwrite.dart'; class TablesDB {}",
    );
    appwrite.addFile('lib/services/teams.dart', "part of '../appwrite.dart'; class Teams {}");
    final youtube = newPackage('youtube_player_iframe');
    youtube.addFile('lib/youtube_player_iframe.dart', r'''
export 'src/controller/youtube_player_controller.dart';
export 'src/player_value.dart';
''');
    youtube.addFile(
      'lib/src/controller/youtube_player_controller.dart',
      'class YoutubePlayerController {}',
    );
    youtube.addFile('lib/src/player_value.dart', 'class YoutubePlayerValue {}');
    _addTestingNavigationPackages();
    super.setUp();
  }

  @override
  String get ruleName => 'test_mock_concrete';
  @override
  String get needle => 'class MockUserRepository';
  @override
  String get source => '''
import 'package:mocktail/mocktail.dart';
class UserRepository {}
class MockUserRepository extends Mock implements UserRepository {}
''';

  Future<void> _allowsAbstractContractsWithoutNamingPrefix() async {
    await assertAllows(r'''
import 'package:mocktail/mocktail.dart';
abstract interface class TestBridge { void send(); }
abstract class BackendPort { void send(); }
class MockTestBridge extends Mock implements TestBridge {}
class MockBackendPort extends Mock implements BackendPort {}
typedef BridgeAlias = TestBridge;
class MockAlias extends Mock implements BridgeAlias {}
''', path: '$testPackageRootPath/test/abstract_contract_test.dart');
  }

  Future<void> _reportsConcreteContractWithInterfacePrefix() async {
    const source = r'''
import 'package:mocktail/mocktail.dart';
interface class IConcreteBridge { void send() {} }
class MockBridge extends Mock implements IConcreteBridge {}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    final filePath = '$testPackageRootPath/test/bridge_test.dart';
    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, 'class MockBridge', ruleName),
    ]);
  }

  /// #77: concrete SDK classes are mocked concretes regardless of package.
  Future<void> _reportsExternalSdkPartDeclarations() async {
    const source = r'''
import 'package:appwrite/appwrite.dart';
import 'package:mocktail/mocktail.dart';
class MockFunctions extends Mock implements Functions {}
class MockStorage extends Mock implements Storage {}
class MockTablesDB extends Mock implements TablesDB {}
class MockAccount extends Mock implements Account {}
class MockTeams extends Mock implements Teams {}
''';
    final filePath = '$testPackageRootPath/test/helpers/appwrite_test_utils.dart';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      for (final name in ['Functions', 'Storage', 'TablesDB', 'Account', 'Teams'])
        compatLint(source, 'class Mock$name', ruleName),
    ]);
  }

  /// #77: abstract contracts declared in a package part file stay allowed.
  Future<void> _allowsExternalAbstractPartDeclaration() async {
    final filePath = '$testPackageRootPath/test/helpers/appwrite_service_test_utils.dart';
    newFile(filePath, r'''
import 'package:appwrite/appwrite.dart';
import 'package:mocktail/mocktail.dart';
class MockService extends Mock implements Service {}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  /// #77: concrete plugin controllers are mocked concretes too.
  Future<void> _reportsExternalPluginControllerMocks() async {
    const source = r'''
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:mocktail/mocktail.dart';
class MockYoutubePlayerController extends Mock implements YoutubePlayerController {}
class MockYoutubePlayerValue extends Mock implements YoutubePlayerValue {}
''';
    final filePath = '$testPackageRootPath/test/core/widgets/exercise_demo_sheet_test.dart';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'class MockYoutubePlayerController', ruleName),
      compatLint(source, 'class MockYoutubePlayerValue', ruleName),
    ]);
  }

  Future<void> _localConcreteSdkNameStillReports() async {
    const source = r'''
import 'package:mocktail/mocktail.dart';
class Account {}
class MockAccount extends Mock implements Account {}
''';
    final filePath = '$testPackageRootPath/test/local_account_test.dart';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, 'class MockAccount', ruleName),
    ]);
  }

  Future<void> _localFunctionsAndStorageConcreteNamesStillReport() async {
    const source = r'''
import 'package:mocktail/mocktail.dart';
class Functions {}
class Storage {}
class MockFunctions extends Mock implements Functions {}
class MockStorage extends Mock implements Storage {}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    final filePath = '$testPackageRootPath/test/local_sdk_services_test.dart';
    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, 'class MockFunctions', ruleName),
      compatLint(analyzedSource, 'class MockStorage', ruleName),
    ]);
  }

  Future<void> _allowsLocalFunctionsAndStorageInterfaces() async {
    await assertAllows(r'''
import 'package:mocktail/mocktail.dart';
abstract interface class Functions { void execute(); }
abstract interface class Storage { void save(); }
class MockFunctions extends Mock implements Functions {}
class MockStorage extends Mock implements Storage {}
''', path: '$testPackageRootPath/test/sdk_interface_mocks_test.dart');
  }

  Future<void> _concreteAliasStillReports() async {
    const source = r'''
import 'package:mocktail/mocktail.dart';
class ConcreteBridge {}
typedef BridgeAlias = ConcreteBridge;
class MockBridge extends Mock implements BridgeAlias {}
''';
    final filePath = '$testPackageRootPath/test/concrete_alias_test.dart';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, 'class MockBridge', ruleName),
    ]);
  }

  Future<void> _reportsFakeOfConcreteContract() async {
    const source = r'''
import 'package:mocktail/mocktail.dart';
class ProductRepository {}
class FakeProductRepository extends Fake implements ProductRepository {}
''';
    final filePath = '$testPackageRootPath/test/fake_concrete_test.dart';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, 'class FakeProductRepository', ruleName),
    ]);
  }

  Future<void> _allowsSkillFakeOfInterface() async {
    await assertAllows(r'''
import 'package:mocktail/mocktail.dart';
abstract interface class IProductRepository { Future<List<Object>> fetchAll(); }
class FakeProductRepository extends Fake implements IProductRepository {
  List<Object> items = [];
  @override
  Future<List<Object>> fetchAll() async => items;
}
''', path: '$testPackageRootPath/test/fake_interface_test.dart');
  }

  Future<void> _allowsLocalClassNamedMock() async {
    await assertAllows(r'''
class Mock {}
class ProductRepository {}
class MockProductRepository extends Mock implements ProductRepository {}
''', path: '$testPackageRootPath/test/local_mock_name_test.dart');
  }
}

final class _TestPumpAndSettleTest extends _TestFileRuleTest {
  static Map<String, Future<void> Function(_TestPumpAndSettleTest)> get _allCases =>
      caseSet<_TestPumpAndSettleTest>(
        parent: _SourceRuleTest._allCases,
        own: {'test_allowsExplicitDurationArgument': (t) => t._allowsExplicitDurationArgument()},
      );

  @override
  String get ruleName => 'test_pump_and_settle';
  @override
  String get needle => 'pumpAndSettle()';
  @override
  String get source => 'void main(tester) { tester.pumpAndSettle(); }';

  Future<void> _allowsExplicitDurationArgument() async {
    final filePath = '$testPackageRootPath/test/widget_test.dart';
    newFile(filePath, r'''
void main(tester) {
  tester.pumpAndSettle(const Duration(seconds: 10));
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

final class _TestTapAtTest extends _TestFileRuleTest {
  static Map<String, Future<void> Function(_TestTapAtTest)> get _allCases =>
      caseSet<_TestTapAtTest>(parent: _SourceRuleTest._allCases, own: {});

  @override
  String get ruleName => 'test_tap_at';
  @override
  String get needle => 'tapAt(Object())';
  @override
  String get source => 'void main(tester) { tester.tapAt(Object()); }';
}

final class _TestInlineValueKeyTest extends _TestRuleTest {
  static Map<String, Future<void> Function(_TestInlineValueKeyTest)> get _allCases =>
      caseSet<_TestInlineValueKeyTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsInlineKeyFactoryString': (t) => t._reportsInlineKeyFactoryString(),
          'test_allowsRegistryConstantKeys': (t) => t._allowsRegistryConstantKeys(),
        },
      );

  @override
  void setUp() {
    _addTestingNavigationPackages();
    super.setUp();
  }

  @override
  String get ruleName => 'test_inline_value_key';
  @override
  String get needle => "ValueKey('todo-row')";
  @override
  String get source => r'''
import 'package:flutter/foundation.dart';

void main() {
  const ValueKey('todo-row');
}
''';

  Future<void> _reportsInlineKeyFactoryString() async {
    const source = r'''
import 'package:flutter/foundation.dart';

void main() {
  const Key('probe.save');
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, "Key('probe.save')", ruleName),
    ]);
  }

  Future<void> _allowsRegistryConstantKeys() async {
    await assertAllows(r'''
import 'package:flutter/foundation.dart';

abstract final class AppWidgetKeys {
  static const productCloseButton = 'product.close.button';
}

void main() {
  const ValueKey(AppWidgetKeys.productCloseButton);
  const Key(AppWidgetKeys.productCloseButton);
}
''');
  }
}

final class _TestFirstMatchFinderTest extends _TestFileRuleTest {
  static Map<String, Future<void> Function(_TestFirstMatchFinderTest)> get _allCases =>
      caseSet<_TestFirstMatchFinderTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsIterableFirstAccess': (t) => t._allowsIterableFirstAccess(),
          'test_reportsFirstOnFinder': (t) => t._reportsFirstOnFinder(),
          'test_allowsIterableFirstInsideFinderArgument': (t) =>
              t._allowsIterableFirstInsideFinderArgument(),
        },
      );

  @override
  void setUp() {
    _addTestingNavigationPackages();
    super.setUp();
  }

  @override
  String get ruleName => 'test_first_match_finder';
  @override
  String get needle => 'find.byIcon';
  @override
  bool get lineStart => true;
  @override
  String get source => 'void main() { find.byIcon(Object()); }';

  Future<void> _allowsIterableFirstAccess() async {
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

  Future<void> _reportsFirstOnFinder() async {
    const source = r'''
import 'package:flutter_test/flutter_test.dart';

Future<void> tapFirst(WidgetTester tester) async {
  await tester.tap(find.byType(Object).first);
}
''';
    final filePath = '$testPackageRootPath/test/first_finder_test.dart';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [compatLint(analyzedSource, 'first);', ruleName)]);
  }

  Future<void> _allowsIterableFirstInsideFinderArgument() async {
    await assertAllows(r'''
import 'package:flutter_test/flutter_test.dart';

void main() {
  final names = <String>['a'];
  find.text(names.first);
}
''', path: '$testPackageRootPath/test/finder_argument_test.dart');
  }
}

final class _TestNotifierOverrideTest extends _TestFileRuleTest {
  static Map<String, Future<void> Function(_TestNotifierOverrideTest)> get _allCases =>
      caseSet<_TestNotifierOverrideTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsFamilyNotifierOverride': (t) => t._reportsFamilyNotifierOverride(),
          'test_allowsSkillBuildValueAndRepositoryOverrides': (t) =>
              t._allowsSkillBuildValueAndRepositoryOverrides(),
          'test_allowsNotifierOverrideOutsideTests': (t) => t._allowsNotifierOverrideOutsideTests(),
        },
      );

  @override
  void setUp() {
    _addTestingNavigationPackages();
    super.setUp();
  }

  @override
  String get ruleName => 'test_notifier_override';
  @override
  String get needle => 'overrideWith(FakeProductNames.new)';
  @override
  String get source => '''
import 'package:riverpod/riverpod.dart';

class ProductNames extends Notifier<List<String>> {
  @override
  List<String> build() => const [];
}

class FakeProductNames extends ProductNames {
  @override
  List<String> build() => const ['fake'];
}

final productNamesProvider = NotifierProvider<ProductNames, List<String>>(ProductNames.new);
final overrides = [productNamesProvider.overrideWith(FakeProductNames.new)];
''';

  Future<void> _reportsFamilyNotifierOverride() async {
    const source = '''
import 'package:riverpod/riverpod.dart';

class ProductDetail extends AsyncNotifier<String> {
  @override
  Future<String> build() async => '';
}

final NotifierProviderFamily<ProductDetail, Object?, String> productDetailProvider =
    throw ArgumentError('stub');
final overrides = [productDetailProvider.overrideWith2((id) => ProductDetail())];
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    final filePath = '$testPackageRootPath/test/product_detail_test.dart';
    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, 'overrideWith2((id)', ruleName),
    ]);
  }

  Future<void> _allowsSkillBuildValueAndRepositoryOverrides() async {
    await assertAllows('''
import 'package:riverpod/riverpod.dart';

abstract interface class IProductRepository {}
class FakeProductRepository implements IProductRepository {}

class Counter extends Notifier<int> {
  @override
  int build() => 0;
}

final counterProvider = NotifierProvider<Counter, int>(Counter.new);
final productRepositoryProvider = Provider<IProductRepository>((ref) => FakeProductRepository());
final overrides = [
  counterProvider.overrideWithBuild((ref, notifier) => 42),
  counterProvider.overrideWithValue(1),
  productRepositoryProvider.overrideWith((ref) => FakeProductRepository()),
  productRepositoryProvider.overrideWithValue(FakeProductRepository()),
];
''', path: '$testPackageRootPath/test/overrides_test.dart');
  }

  Future<void> _allowsNotifierOverrideOutsideTests() async {
    await assertAllows('''
import 'package:riverpod/riverpod.dart';

class Auth extends Notifier<bool> {
  @override
  bool build() => true;
}

class SignedOutAuth extends Auth {
  @override
  bool build() => false;
}

final authProvider = NotifierProvider<Auth, bool>(Auth.new);
final overrides = [authProvider.overrideWith(SignedOutAuth.new)];
''', path: '$testPackageLibPath/main_dev.dart');
  }
}

final class _TestE2eBlindSleepTest extends _TestRuleTest {
  static Map<String, Future<void> Function(_TestE2eBlindSleepTest)> get _allCases =>
      caseSet<_TestE2eBlindSleepTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsHostDriverDelay': (t) => t._reportsHostDriverDelay(),
          'test_allowsPollingLoopAndUnawaitedDelay': (t) => t._allowsPollingLoopAndUnawaitedDelay(),
          'test_allowsDelayOutsideE2e': (t) => t._allowsDelayOutsideE2e(),
          'test_allowsLocalDelayedLookalike': (t) => t._allowsLocalDelayedLookalike(),
        },
      );

  @override
  void setUp() {
    _addTestingNavigationPackages();
    super.setUp();
  }

  @override
  String get ruleName => 'test_e2e_blind_sleep';
  @override
  String get path => '$testPackageRootPath/integration_test/app_flow_test.dart';
  @override
  String get needle => 'Future<void>.delayed(const Duration(seconds: 2));';
  @override
  String get source => '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('flow', (tester) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    await tester.pump();
  });
}
''';

  Future<void> _reportsHostDriverDelay() async {
    const source = '''
Future<void> main() async {
  await Future.delayed(const Duration(milliseconds: 500));
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    final filePath = '$testPackageRootPath/test_driver/app_driver.dart';
    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, 'Future.delayed(const Duration(milliseconds: 500));', ruleName),
    ]);
  }

  Future<void> _allowsPollingLoopAndUnawaitedDelay() async {
    await assertAllows('''
import 'dart:async';

Future<void> waitUntil(bool Function() ready) async {
  while (!ready()) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void scheduleLater() {
  unawaited(Future<void>.delayed(const Duration(seconds: 1)));
}
''', path: '$testPackageRootPath/integration_test/helpers/wait_helpers.dart');
  }

  Future<void> _allowsDelayOutsideE2e() async {
    await assertAllows('''
Future<void> settle() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}
''', path: '$testPackageRootPath/test/unit/settle_test.dart');
  }

  Future<void> _allowsLocalDelayedLookalike() async {
    await assertAllows('''
class Clock {
  static Future<void> delayed(Duration duration) async {}
}

Future<void> main() async {
  await Clock.delayed(const Duration(seconds: 1));
}
''', path: '$testPackageRootPath/integration_test/clock_test.dart');
  }
}

final class _TestTextLabelSelectorTest extends _TestFileRuleTest {
  static Map<String, Future<void> Function(_TestTextLabelSelectorTest)> get _allCases =>
      caseSet<_TestTextLabelSelectorTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsWidgetWithTextAndNestedLabelFinders': (t) =>
              t._reportsWidgetWithTextAndNestedLabelFinders(),
          'test_allowsSkillTextAssertionsAndKeyTaps': (t) =>
              t._allowsSkillTextAssertionsAndKeyTaps(),
          'test_allowsStableTextInE2e': (t) => t._allowsStableTextInE2e(),
          'test_allowsNonLiteralLabel': (t) => t._allowsNonLiteralLabel(),
        },
      );

  @override
  void setUp() {
    _addTestingNavigationPackages();
    super.setUp();
  }

  @override
  String get ruleName => 'test_text_label_selector';
  @override
  String get needle => "find.text('Save'));";
  @override
  String get source => '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('saves', (tester) async {
    await tester.tap(find.text('Save'));
  });
}
''';

  Future<void> _reportsWidgetWithTextAndNestedLabelFinders() async {
    const source = '''
import 'package:flutter_test/flutter_test.dart';

class ElevatedButton {}

void main() {
  testWidgets('edits', (tester) async {
    await tester.longPress(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.enterText(find.descendant(of: find.byType(ElevatedButton), matching: find.textContaining('Name')), 'x');
  });
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    final filePath = '$testPackageRootPath/test/edit_test.dart';
    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, "find.widgetWithText(ElevatedButton, 'Delete'));", ruleName),
      compatLint(analyzedSource, "find.textContaining('Name')), 'x');", ruleName),
    ]);
  }

  Future<void> _allowsSkillTextAssertionsAndKeyTaps() async {
    await assertAllows('''
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

abstract final class AppWidgetKeys {
  static const saveButton = ValueKey<String>('save_button');
}

void main() {
  testWidgets('lists products', (tester) async {
    await tester.tap(find.byKey(AppWidgetKeys.saveButton));
    expect(find.text('Widget'), findsOneWidget);
  });
}
''', path: '$testPackageRootPath/test/product_list_test.dart');
  }

  Future<void> _allowsStableTextInE2e() async {
    await assertAllows('''
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('e2e', (tester) async {
    await tester.tap(find.text('Save'));
  });
}
''', path: '$testPackageRootPath/integration_test/save_flow_test.dart');
  }

  Future<void> _allowsNonLiteralLabel() async {
    await assertAllows('''
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('localized', (tester) async {
    const label = 'Save';
    await tester.tap(find.text(label));
  });
}
''', path: '$testPackageRootPath/test/localized_test.dart');
  }
}

abstract class _ValueObjectRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => valueObjectSourceRules;
}

final class _DomainEmptyStringSentinelTest extends _ValueObjectRuleTest {
  static Map<String, Future<void> Function(_DomainEmptyStringSentinelTest)> get _allCases =>
      caseSet<_DomainEmptyStringSentinelTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsConstructorDefaultThisField': (t) => t._reportsConstructorDefaultThisField(),
          'test_allowsOptionalDomainTextAsNullable': (t) => t._allowsOptionalDomainTextAsNullable(),
          'test_allowsDataModelWireEmptyDefault': (t) => t._allowsDataModelWireEmptyDefault(),
        },
      );

  @override
  String get ruleName => 'domain_empty_string_sentinel';
  @override
  String get needle => "@Default('') final String id";
  @override
  String get path => '$testPackageLibPath/features/users/domain/user.dart';
  @override
  String get source => r'''
class Default {
  const Default(Object value);
}

class User {
  const User({required this.id});

  @Default('') final String id;
}
''';

  Future<void> _reportsConstructorDefaultThisField() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    final analyzedSource = _analyzedSource(r'''
class User {
  const User({this.id = ''});

  final String id;
}
''', addIgnorePrefix: addIgnorePrefix);

    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [compatLint(analyzedSource, "this.id = ''", ruleName)]);
  }

  Future<void> _allowsOptionalDomainTextAsNullable() async {
    await assertAllows(r'''
class User {
  const User({this.bio});

  final String? bio;
}
''', path: '$testPackageLibPath/features/users/domain/user.dart');
  }

  Future<void> _allowsDataModelWireEmptyDefault() async {
    await assertAllows(r'''
class UserModel {
  const UserModel({this.id = ''});

  final String id;
}
''', path: '$testPackageLibPath/features/users/data/models/user_model.dart');
  }
}

void _defineSourceScannerRulesPart12Tests() {
  analysisRuleSuite<_TestMockConcreteTest>(
    'TestMockConcreteTest',
    _TestMockConcreteTest.new,
    _TestMockConcreteTest._allCases,
  );
  analysisRuleSuite<_TestPumpAndSettleTest>(
    'TestPumpAndSettleTest',
    _TestPumpAndSettleTest.new,
    _TestPumpAndSettleTest._allCases,
  );
  analysisRuleSuite<_TestTapAtTest>('TestTapAtTest', _TestTapAtTest.new, _TestTapAtTest._allCases);
  analysisRuleSuite<_TestInlineValueKeyTest>(
    'TestInlineValueKeyTest',
    _TestInlineValueKeyTest.new,
    _TestInlineValueKeyTest._allCases,
  );
  analysisRuleSuite<_TestFirstMatchFinderTest>(
    'TestFirstMatchFinderTest',
    _TestFirstMatchFinderTest.new,
    _TestFirstMatchFinderTest._allCases,
  );
  analysisRuleSuite<_TestNotifierOverrideTest>(
    'TestNotifierOverrideTest',
    _TestNotifierOverrideTest.new,
    _TestNotifierOverrideTest._allCases,
  );
  analysisRuleSuite<_TestE2eBlindSleepTest>(
    'TestE2eBlindSleepTest',
    _TestE2eBlindSleepTest.new,
    _TestE2eBlindSleepTest._allCases,
  );
  analysisRuleSuite<_TestTextLabelSelectorTest>(
    'TestTextLabelSelectorTest',
    _TestTextLabelSelectorTest.new,
    _TestTextLabelSelectorTest._allCases,
  );
  analysisRuleSuite<_DomainEmptyStringSentinelTest>(
    'DomainEmptyStringSentinelTest',
    _DomainEmptyStringSentinelTest.new,
    _DomainEmptyStringSentinelTest._allCases,
  );
}
