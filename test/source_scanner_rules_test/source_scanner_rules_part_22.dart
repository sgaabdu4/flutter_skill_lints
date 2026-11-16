part of '../source_scanner_rules_test.dart';

final class DomainEntityPrimitiveFactoryTest extends _ValueObjectRuleTest {
  @override
  String get ruleName => 'domain_entity_primitive_factory';
  @override
  String get needle => 'factory User.fromPrimitives';
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
// ignore_for_file: uri_does_not_exist, unused_import, redirect_to_invalid_function_type
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class User {
  const factory User({required String id}) = _User;
  factory User.fromPrimitives(String id, int age) => User(id: id);
}
class _User implements User {
  const _User({required this.id});
  final String id;
}
''';

  Future<void> _allowsAnonymousFreezedRedirect() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class User {
  const factory User({required String id}) = _User;
}
class _User implements User {
  const _User({required this.id});
  final String id;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsNamedFactoryInValueObjectsPath() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class Distance {
  factory Distance.fromMeters(double m) {
    return _Meters(m);
  }
}
class _Meters implements Distance {
  const _Meters(this.value);
  final double value;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsNamedFactoryInDataPath() async {
    final filePath = '$testPackageLibPath/features/users/data/models/user_model.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class UserModel {
  const factory UserModel({required String id}) = _UserModel;
  factory UserModel.fromPrimitives(String id) => UserModel(id: id);
}
class _UserModel implements UserModel {
  const _UserModel({required this.id});
  final String id;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsPrivateNamedFactory() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class User {
  const factory User({required String id}) = _User;
  factory User._fromInternal(String id) => User(id: id);
}
class _User implements User {
  const _User({required this.id});
  final String id;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsClassWithoutFreezedAnnotation() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
class User {
  const User._();
  factory User.fromPrimitives(String id) => const User._();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsFromJsonFactoryInDomain() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_method, redirect_to_invalid_function_type
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class User {
  const factory User({required String id}) = _User;
  factory User.fromJson(Map<String, Object?> json) => const _User();
}
class _User implements User {
  const _User({this.id = ''});
  final String id;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  // Issue #38: a redirecting union case carrying a primitive declares a variant; it converts nothing.
  Future<void> _allowsNamedUnionCaseCarryingPrimitive() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import, redirect_to_invalid_function_type
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class User {
  const factory User({required String id}) = _User;
  const factory User.empty(String placeholder) = _EmptyUser;
}
class _User implements User {
  const _User({required this.id});
  final String id;
}
class _EmptyUser implements User {
  const _EmptyUser(this.placeholder);
  final String placeholder;
}
''';
    newFile(filePath, source);

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsParameterlessFreezedUnionVariants() async {
    final filePath = '$testPackageLibPath/features/users/domain/backend_failure.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import, redirect_to_invalid_function_type
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class BackendFailure {
  const factory BackendFailure.network() = NetworkFailure;
  const factory BackendFailure.auth() = AuthFailure;
}
class NetworkFailure implements BackendFailure {
  const NetworkFailure();
}
class AuthFailure implements BackendFailure {
  const AuthFailure();
}
''');
    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsMultilineAndValueObjectVariants() async {
    final filePath = '$testPackageLibPath/features/users/domain/backend_failure.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import, redirect_to_invalid_function_type
import 'package:freezed_annotation/freezed_annotation.dart';

class RequiredText { const RequiredText(); }
@freezed
sealed class BackendFailure {
  const factory BackendFailure.network(
  ) = NetworkFailure;
  const factory BackendFailure.invalid(RequiredText reason) = InvalidFailure;
}
class NetworkFailure implements BackendFailure { const NetworkFailure(); }
class InvalidFailure implements BackendFailure {
  const InvalidFailure(this.reason);
  final RequiredText reason;
}
''');
    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsNullableDiagnosticPayloadOnExceptionUnion() async {
    final filePath = '$testPackageLibPath/core/domain/backend_failure.dart';
    newFile(filePath, r'''
// ignore_for_file: redirect_to_invalid_function_type
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class BackendFailure implements Exception {
  const factory BackendFailure.network({
    String? message,
    int? code,
    String? type,
    Object? response,
  }) = NetworkFailure;
  const factory BackendFailure.auth({String? message}) = AuthFailure;
}
class NetworkFailure implements BackendFailure {
  const NetworkFailure({this.message, this.code, this.type, this.response});
  final String? message;
  final int? code;
  final String? type;
  final Object? response;
}
class AuthFailure implements BackendFailure {
  const AuthFailure({this.message});
  final String? message;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  // Issue #64: exception union cases may carry required or optional primitives.
  Future<void> _allowsExceptionUnionCasesCarryingPrimitives() async {
    final filePath = '$testPackageLibPath/core/domain/backend_failure.dart';
    const source = r'''
// ignore_for_file: redirect_to_invalid_function_type
import 'package:freezed_annotation/freezed_annotation.dart';
@freezed
sealed class BackendFailure implements Exception {
  const factory BackendFailure.http({int? statusCode}) = HttpFailure;
  const factory BackendFailure.requiredStatus({required int statusCode}) = RequiredFailure;
  const factory BackendFailure.textStatus({String? statusCode}) = TextFailure;
}
class HttpFailure implements BackendFailure { const HttpFailure({this.statusCode}); final int? statusCode; }
class RequiredFailure implements BackendFailure { const RequiredFailure({required this.statusCode}); final int statusCode; }
class TextFailure implements BackendFailure { const TextFailure({this.statusCode}); final String? statusCode; }
''';
    newFile(filePath, source);
    await assertNoDiagnosticsInFile(filePath);
  }

  // Issues #38/#64: union cases are allowed; body factories that take primitives still report.
  Future<void> _reportsBodyFactoriesBesideUnionCases() async {
    final filePath = '$testPackageLibPath/core/domain/backend_failure.dart';
    const source = r'''
// ignore_for_file: redirect_to_invalid_function_type
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class BackendFailure implements Exception {
  const factory BackendFailure.network({String? message}) = NetworkFailure;
  const factory BackendFailure.invalidId({String? userId}) = InvalidIdFailure;
  const factory BackendFailure.requiredMessage({required String message}) = RequiredFailure;
  const factory BackendFailure.positional([String? message]) = PositionalFailure;
  factory BackendFailure.translated({String? message}) => NetworkFailure(message: message);
  factory BackendFailure.fromPrimitives(String id) => const NetworkFailure();
}
class NetworkFailure implements BackendFailure { const NetworkFailure({this.message}); final String? message; }
class InvalidIdFailure implements BackendFailure { const InvalidIdFailure({this.userId}); final String? userId; }
class RequiredFailure implements BackendFailure { const RequiredFailure({required this.message}); final String message; }
class PositionalFailure implements BackendFailure { const PositionalFailure([this.message]); final String? message; }
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'factory BackendFailure.translated', ruleName),
      compatLint(source, 'factory BackendFailure.fromPrimitives', ruleName),
    ]);
  }

  // Issue #38: data unions outside Exception hierarchies are also union cases.
  Future<void> _allowsNonExceptionUnionCaseCarryingPrimitive() async {
    final filePath = '$testPackageLibPath/core/domain/result.dart';
    const source = r'''
// ignore_for_file: redirect_to_invalid_function_type
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class Result {
  const factory Result.ready({String? message}) = ReadyResult;
  const factory Result.empty() = EmptyResult;
}
class ReadyResult implements Result { const ReadyResult({this.message}); final String? message; }
class EmptyResult implements Result { const EmptyResult(); }
''';
    newFile(filePath, source);

    await assertNoDiagnosticsInFile(filePath);
  }

  // Issues #38/#64: the skill's AppError (state-management-lifecycle.md:126-135) verbatim in core/domain.
  Future<void> _allowsSkillAppErrorUnion() async {
    final filePath = '$testPackageLibPath/core/domain/app_error.dart';
    newFile(filePath, r'''
// ignore_for_file: redirect_to_invalid_function_type
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class AppError {
  const factory AppError.network(String message) = NetworkError;
  const factory AppError.validation(String field, String message) = ValidationError;
  const factory AppError.notFound(String resource) = NotFoundError;
  const factory AppError.unauthorized() = UnauthorizedError;
  const factory AppError.unexpected(Object error) = UnexpectedError;
}
class NetworkError implements AppError { const NetworkError(this.message); final String message; }
class ValidationError implements AppError {
  const ValidationError(this.field, this.message);
  final String field;
  final String message;
}
class NotFoundError implements AppError { const NotFoundError(this.resource); final String resource; }
class UnauthorizedError implements AppError { const UnauthorizedError(); }
class UnexpectedError implements AppError { const UnexpectedError(this.error); final Object error; }
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _reportsBodyFactoryOnDataUnion() async {
    final filePath = '$testPackageLibPath/core/domain/result.dart';
    const source = r'''
// ignore_for_file: redirect_to_invalid_function_type
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class Result {
  const factory Result.ready({String? message}) = ReadyResult;
  factory Result.fromCode(int code) => ReadyResult(message: '$code');
}
class ReadyResult implements Result { const ReadyResult({this.message}); final String? message; }
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'factory Result.fromCode', ruleName),
    ]);
  }
}

abstract class _DomainEntityParameterRuleTest extends _ValueObjectRuleTest {
  @override
  bool get addIgnorePrefix => false;

  @override
  void setUp() {
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed {
  const Freezed();
}

class Default {
  const Default(Object value);
}

const freezed = Freezed();
''');
    super.setUp();
  }

  String entity(String parameters) =>
      '''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, redirect_to_invalid_function_type, redirect_to_non_class
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class Product {
  const factory Product({
$parameters
  }) = _Product;
}
''';
}

final class DomainRawRequiredStringTest extends _DomainEntityParameterRuleTest {
  @override
  String get ruleName => 'domain_raw_required_string';
  @override
  String get needle => 'String title,';
  @override
  String get path => '$testPackageLibPath/core/domain/entities/product.dart';
  @override
  String get source => entity('    required String title,\n    required DateTime createdAt,');

  Future<void> _reportsEveryRawStringAroundAnnotatedParameters() async {
    final source = entity(
      '    required String id,\n    @Default(0) int stock,\n    required String description,',
    );
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      compatLint(source, 'String id,', ruleName),
      compatLint(source, 'String description,', ruleName),
    ]);
  }

  Future<void> _reportsNonConstRedirectingFactory() async {
    final source = entity('    required String label,').replaceFirst('const factory', 'factory');
    newFile(path, source);

    await assertDiagnosticsInFile(path, [compatLint(source, 'String label,', ruleName)]);
  }

  Future<void> _reportsUnmarkedStringBesideHiveFieldSlots() async {
    final source = entity(
      '    /// HiveField(0)\n    required String id,\n    required String nickname,',
    );
    newFile(path, source);

    await assertDiagnosticsInFile(path, [compatLint(source, 'String nickname,', ruleName)]);
  }

  Future<void> _allowsValueObjectsOptionalTextAndNamedUnionFactories() async {
    await assertAllows(
      '''
${entity('    required ProductId id,\n    String? note,\n    required List<String> tags,')}
@freezed
sealed class AppError {
  const factory AppError.network(String message) = NetworkError;
}
''',
      path: path,
      addIgnorePrefix: false,
    );
  }

  Future<void> _allowsDataModelsAndValueObjects() async {
    final source = entity('    required String title,');
    await assertAllows(
      source,
      path: '$testPackageLibPath/core/data/models/product_model.dart',
      addIgnorePrefix: false,
    );
    await assertAllows(
      source,
      path: '$testPackageLibPath/core/domain/values/product.dart',
      addIgnorePrefix: false,
    );
  }
}

final class DomainUnitPrimitiveTest extends _DomainEntityParameterRuleTest {
  @override
  String get ruleName => 'domain_unit_primitive';
  @override
  String get needle => 'int lengthCm,';
  @override
  String get path => '$testPackageLibPath/core/domain/entities/product.dart';
  @override
  String get source => entity('    required int lengthCm,\n    required DateTime createdAt,');

  Future<void> _reportsDefaultedAndNullableUnitNumbers() async {
    final source = entity(
      '    @Default(0) int discountPercent,\n    double? weightKg,\n    num price,',
    );
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      compatLint(source, 'int discountPercent,', ruleName),
      compatLint(source, 'double? weightKg,', ruleName),
      compatLint(source, 'num price,', ruleName),
    ]);
  }

  Future<void> _allowsShippedHiveEntityLockedSlots() async {
    await assertAllows(
      entity('    required String id,\n    /// HiveField(1)\n    required double distanceMeters,'),
      path: path,
      addIgnorePrefix: false,
    );
  }

  Future<void> _reportsNonConstFactoryAndUnmarkedHiveNeighbour() async {
    final source = entity(
      '    /// HiveField(1)\n    required double distanceMeters,\n    required double weightKg,',
    ).replaceFirst('const factory', 'factory');
    newFile(path, source);

    await assertDiagnosticsInFile(path, [compatLint(source, 'double weightKg,', ruleName)]);
  }

  Future<void> _allowsCountsAndTypedUnits() async {
    await assertAllows(
      entity(
        '    required int quantity,\n    required int items,\n    required Duration duration,',
      ),
      path: path,
      addIgnorePrefix: false,
    );
  }
}

void _defineSourceScannerRulesPart22Tests() {
  analysisRuleSuite<DomainEntityPrimitiveFactoryTest>(
    'DomainEntityPrimitiveFactoryTest',
    DomainEntityPrimitiveFactoryTest.new,
    {
      'test_allowsAnonymousFreezedRedirect': (t) => t._allowsAnonymousFreezedRedirect(),
      'test_allowsNamedFactoryInValueObjectsPath': (t) => t._allowsNamedFactoryInValueObjectsPath(),
      'test_allowsNamedFactoryInDataPath': (t) => t._allowsNamedFactoryInDataPath(),
      'test_allowsPrivateNamedFactory': (t) => t._allowsPrivateNamedFactory(),
      'test_allowsClassWithoutFreezedAnnotation': (t) => t._allowsClassWithoutFreezedAnnotation(),
      'test_allowsFromJsonFactoryInDomain': (t) => t._allowsFromJsonFactoryInDomain(),
      'test_allowsNamedUnionCaseCarryingPrimitive': (t) =>
          t._allowsNamedUnionCaseCarryingPrimitive(),
      'test_allowsParameterlessFreezedUnionVariants': (t) =>
          t._allowsParameterlessFreezedUnionVariants(),
      'test_allowsMultilineAndValueObjectVariants': (t) =>
          t._allowsMultilineAndValueObjectVariants(),
      'test_allowsNullableDiagnosticPayloadOnExceptionUnion': (t) =>
          t._allowsNullableDiagnosticPayloadOnExceptionUnion(),
      'test_allowsExceptionUnionCasesCarryingPrimitives': (t) =>
          t._allowsExceptionUnionCasesCarryingPrimitives(),
      'test_reportsBodyFactoriesBesideUnionCases': (t) => t._reportsBodyFactoriesBesideUnionCases(),
      'test_allowsNonExceptionUnionCaseCarryingPrimitive': (t) =>
          t._allowsNonExceptionUnionCaseCarryingPrimitive(),
      'test_allowsSkillAppErrorUnion': (t) => t._allowsSkillAppErrorUnion(),
      'test_reportsBodyFactoryOnDataUnion': (t) => t._reportsBodyFactoryOnDataUnion(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<DomainRawRequiredStringTest>(
    'DomainRawRequiredStringTest',
    DomainRawRequiredStringTest.new,
    {
      'test_reportsEveryRawStringAroundAnnotatedParameters': (t) =>
          t._reportsEveryRawStringAroundAnnotatedParameters(),
      'test_reportsNonConstRedirectingFactory': (t) => t._reportsNonConstRedirectingFactory(),
      'test_reportsUnmarkedStringBesideHiveFieldSlots': (t) =>
          t._reportsUnmarkedStringBesideHiveFieldSlots(),
      'test_allowsValueObjectsOptionalTextAndNamedUnionFactories': (t) =>
          t._allowsValueObjectsOptionalTextAndNamedUnionFactories(),
      'test_allowsDataModelsAndValueObjects': (t) => t._allowsDataModelsAndValueObjects(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<DomainUnitPrimitiveTest>(
    'DomainUnitPrimitiveTest',
    DomainUnitPrimitiveTest.new,
    {
      'test_reportsDefaultedAndNullableUnitNumbers': (t) =>
          t._reportsDefaultedAndNullableUnitNumbers(),
      'test_allowsShippedHiveEntityLockedSlots': (t) => t._allowsShippedHiveEntityLockedSlots(),
      'test_reportsNonConstFactoryAndUnmarkedHiveNeighbour': (t) =>
          t._reportsNonConstFactoryAndUnmarkedHiveNeighbour(),
      'test_allowsCountsAndTypedUnits': (t) => t._allowsCountsAndTypedUnits(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
}
