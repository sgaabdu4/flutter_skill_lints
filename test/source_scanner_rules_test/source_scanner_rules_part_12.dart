// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class TestMockConcreteTest extends _TestFileRuleTest {
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

  Future<void> test_allowsAbstractContractsWithoutNamingPrefix() async {
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

  Future<void> test_reportsConcreteContractWithInterfacePrefix() async {
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
  Future<void> test_reportsExternalSdkPartDeclarations() async {
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
  Future<void> test_allowsExternalAbstractPartDeclaration() async {
    final filePath = '$testPackageRootPath/test/helpers/appwrite_service_test_utils.dart';
    newFile(filePath, r'''
import 'package:appwrite/appwrite.dart';
import 'package:mocktail/mocktail.dart';
class MockService extends Mock implements Service {}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  /// #77: concrete plugin controllers are mocked concretes too.
  Future<void> test_reportsExternalPluginControllerMocks() async {
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

  Future<void> test_localConcreteSdkNameStillReports() async {
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

  Future<void> test_localFunctionsAndStorageConcreteNamesStillReport() async {
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

  Future<void> test_allowsLocalFunctionsAndStorageInterfaces() async {
    await assertAllows(r'''
import 'package:mocktail/mocktail.dart';
abstract interface class Functions { void execute(); }
abstract interface class Storage { void save(); }
class MockFunctions extends Mock implements Functions {}
class MockStorage extends Mock implements Storage {}
''', path: '$testPackageRootPath/test/sdk_interface_mocks_test.dart');
  }

  Future<void> test_concreteAliasStillReports() async {
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

  Future<void> test_reportsFakeOfConcreteContract() async {
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

  Future<void> test_allowsSkillFakeOfInterface() async {
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

  Future<void> test_allowsLocalClassNamedMock() async {
    await assertAllows(r'''
class Mock {}
class ProductRepository {}
class MockProductRepository extends Mock implements ProductRepository {}
''', path: '$testPackageRootPath/test/local_mock_name_test.dart');
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

  Future<void> test_reportsInlineKeyFactoryString() async {
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

  Future<void> test_allowsRegistryConstantKeys() async {
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

@reflectiveTest
final class TestFirstMatchFinderTest extends _TestFileRuleTest {
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

  Future<void> test_reportsFirstOnFinder() async {
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

  Future<void> test_allowsIterableFirstInsideFinderArgument() async {
    await assertAllows(r'''
import 'package:flutter_test/flutter_test.dart';

void main() {
  final names = <String>['a'];
  find.text(names.first);
}
''', path: '$testPackageRootPath/test/finder_argument_test.dart');
  }
}

abstract class _ValueObjectRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => valueObjectSourceRules;
}

@reflectiveTest
final class DomainEmptyStringSentinelTest extends _ValueObjectRuleTest {
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

  Future<void> test_reportsConstructorDefaultThisField() async {
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

  Future<void> test_allowsOptionalDomainTextAsNullable() async {
    await assertAllows(r'''
class User {
  const User({this.bio});

  final String? bio;
}
''', path: '$testPackageLibPath/features/users/domain/user.dart');
  }

  Future<void> test_allowsDataModelWireEmptyDefault() async {
    await assertAllows(r'''
class UserModel {
  const UserModel({this.id = ''});

  final String id;
}
''', path: '$testPackageLibPath/features/users/data/models/user_model.dart');
  }
}

@reflectiveTest
final class VoPublicRawConstructorTest extends _ValueObjectRuleTest {
  @override
  String get ruleName => 'vo_public_raw_constructor';
  @override
  String get needle => 'const factory Distance.meters';
  @override
  String get path => '$testPackageLibPath/core/domain/values/distance.dart';
  @override
  String get source => r'''
class Distance {
  const factory Distance.meters(double value) = _Meters;
  const Distance._();
}
class _Meters extends Distance {
  const _Meters(this.value) : super._();
  final double value;
}
''';

  Future<void> test_allowsPrivateRawRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    newFile(filePath, r'''
class Distance {
  const factory Distance._meters(double value) = _Meters;
  const Distance._();
  factory Distance.fromMeters(double m) {
    assert(m >= 0);
    return Distance._meters(m);
  }
}
class _Meters extends Distance {
  const _Meters(this.value) : super._();
  final double value;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsValidatedFactoryWithoutRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/email.dart';
    newFile(filePath, r'''
// ignore_for_file: undefined_method, undefined_identifier
class Email {
  const Email._raw(this.value);
  factory Email(String input) {
    return Email._raw(input);
  }
  final String value;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsRedirectOutsideValueObjectsPath() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
class User {
  const factory User.empty(double placeholder) = _User;
  const User._();
}
class _User extends User {
  const _User(this.placeholder) : super._();
  final double placeholder;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsParameterlessPublicRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    newFile(filePath, r'''
class Distance {
  const factory Distance.zero() = _DistanceZero;
  const Distance._();
}
class _DistanceZero extends Distance {
  const _DistanceZero() : super._();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsAnonymousPublicRawRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/email.dart';
    const source = r'''
// ignore_for_file: undefined_method
class Email {
  const factory Email(String value) = _Email;
  const Email._();
}
class _Email extends Email {
  const _Email(this.value) : super._();
  final String value;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'const factory Email(String value) = _Email;', ruleName),
    ]);
  }

  Future<void> test_reportsNullablePrimitiveParam() async {
    final filePath = '$testPackageLibPath/core/domain/values/email.dart';
    const source = r'''
// ignore_for_file: undefined_method
class Email {
  const factory Email.raw(String? value) = _Email;
  const Email._();
}
class _Email extends Email {
  const _Email(this.value) : super._();
  final String? value;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'const factory Email.raw(String? value) = _Email;', ruleName),
    ]);
  }

  Future<void> test_reportsMultiParamPublicRawRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/money.dart';
    const source = r'''
// ignore_for_file: undefined_method, undefined_class
class Money {
  const factory Money.usd(int cents, Currency currency) = _UsdMoney;
  const Money._();
}
class _UsdMoney extends Money {
  const _UsdMoney(this.cents, this.currency) : super._();
  final int cents;
  final Currency currency;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(
        source,
        'const factory Money.usd(int cents, Currency currency) = _UsdMoney;',
        ruleName,
      ),
    ]);
  }

  Future<void> test_reportsPassthroughPublicFactory() async {
    final filePath = '$testPackageLibPath/core/domain/values/weight_adjustment.dart';
    const source = r'''
// ignore_for_file: undefined_method
class WeightAdjustment {
  const factory WeightAdjustment._kilograms(double value) = _Kg;
  const WeightAdjustment._();
  factory WeightAdjustment.kilograms(double value) => WeightAdjustment._kilograms(value);
}
class _Kg extends WeightAdjustment {
  const _Kg(this.value) : super._();
  final double value;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'factory WeightAdjustment.kilograms', ruleName),
    ]);
  }

  Future<void> test_allowsValidatedFactoryWithAssert() async {
    final filePath = '$testPackageLibPath/core/domain/values/weight.dart';
    newFile(filePath, r'''
// ignore_for_file: undefined_method
class Weight {
  const factory Weight._kilograms(double value) = _Kg;
  const Weight._();
  factory Weight.kilograms(double value) {
    assert(value >= 0, 'Weight cannot be negative');
    return Weight._kilograms(value);
  }
}
class _Kg extends Weight {
  const _Kg(this.value) : super._();
  final double value;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsTransformingFactory() async {
    final filePath = '$testPackageLibPath/core/domain/values/email.dart';
    newFile(filePath, r'''
// ignore_for_file: undefined_method
class Email {
  const factory Email._raw(String value) = _Email;
  const Email._();
  factory Email(String input) => Email._raw(input.trim());
}
class _Email extends Email {
  const _Email(this.value) : super._();
  final String value;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsMultiLinePublicRawRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    const source = r'''
// ignore_for_file: undefined_method
class Distance {
  const factory Distance.meters(
    double value,
  ) = _Meters;
  const Distance._();
}
class _Meters extends Distance {
  const _Meters(this.value) : super._();
  final double value;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'const factory Distance.meters(', ruleName),
    ]);
  }
}
