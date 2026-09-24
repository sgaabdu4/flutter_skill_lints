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
''');
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
    super.setUp();
  }

  @override
  String get ruleName => 'test_mock_concrete';
  @override
  String get needle => 'class MockUserRepository';
  @override
  String get source => '''
class Mock {}
class UserRepository {}
class MockUserRepository extends Mock implements UserRepository {}
''';

  Future<void> test_allowsAbstractContractsWithoutNamingPrefix() async {
    await assertAllows(r'''
class Mock { dynamic noSuchMethod(Invocation invocation) => null; }
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
class Mock { dynamic noSuchMethod(Invocation invocation) => null; }
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

  Future<void> test_allowsExternalSdkPartDeclarations() async {
    final filePath = '$testPackageRootPath/test/helpers/appwrite_test_utils.dart';
    newFile(filePath, r'''
import 'package:appwrite/appwrite.dart';
class Mock {}
class MockFunctions extends Mock implements Functions {}
class MockStorage extends Mock implements Storage {}
class MockTablesDB extends Mock implements TablesDB {}
class MockAccount extends Mock implements Account {}
class MockTeams extends Mock implements Teams {}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsExternalPluginControllerMocks() async {
    final filePath = '$testPackageRootPath/test/core/widgets/exercise_demo_sheet_test.dart';
    newFile(filePath, r'''
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
class Mock {}
class MockYoutubePlayerController extends Mock implements YoutubePlayerController {}
class MockYoutubePlayerValue extends Mock implements YoutubePlayerValue {}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_localConcreteSdkNameStillReports() async {
    const source = r'''
class Mock {}
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
class Mock {}
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
class Mock { dynamic noSuchMethod(Invocation invocation) => null; }
abstract interface class Functions { void execute(); }
abstract interface class Storage { void save(); }
class MockFunctions extends Mock implements Functions {}
class MockStorage extends Mock implements Storage {}
''', path: '$testPackageRootPath/test/sdk_interface_mocks_test.dart');
  }

  Future<void> test_concreteAliasStillReports() async {
    const source = r'''
class Mock {}
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

  Future<void> test_allowsCompositeCanonicalRedirect() async {
    await assertAllows(r'''
// ignore_for_file: redirect_to_non_class
enum Currency { usd, eur }
class Money {
  const Money._();
  const factory Money({required int cents, required Currency currency}) = _Money;
  factory Money.usd(double dollars) => Money(cents: (dollars * 100).round(), currency: .usd);
}
''', path: '$testPackageLibPath/core/domain/values/money.dart');
  }

  Future<void> test_reportsSingleFieldAndNonConstPublicRedirects() async {
    final filePath = '$testPackageLibPath/core/domain/values/email.dart';
    const source = r'''
// ignore_for_file: redirect_to_non_class
class Email {
  const factory Email({required String value}) = _Email;
  factory Email.raw(String value) = _RawEmail;
  const Email._();
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'const factory Email({required String value}) = _Email;', ruleName),
      compatLint(source, 'factory Email.raw(String value) = _RawEmail;', ruleName),
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
