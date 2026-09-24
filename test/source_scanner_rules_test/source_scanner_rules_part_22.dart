// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
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

  Future<void> test_allowsAnonymousFreezedRedirect() async {
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

  Future<void> test_allowsNamedFactoryInValueObjectsPath() async {
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

  Future<void> test_allowsNamedFactoryInDataPath() async {
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

  Future<void> test_allowsPrivateNamedFactory() async {
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

  Future<void> test_allowsClassWithoutFreezedAnnotation() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
class User {
  const User._();
  factory User.fromPrimitives(String id) => const User._();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsFromJsonFactoryInDomain() async {
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

  Future<void> test_reportsConstFactoryNamedVariant() async {
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

    await assertDiagnosticsInFile(filePath, [compatLint(source, 'factory User.empty', ruleName)]);
  }

  Future<void> test_allowsParameterlessFreezedUnionVariants() async {
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

  Future<void> test_allowsMultilineAndValueObjectVariants() async {
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

@reflectiveTest
final class DomainRawRequiredStringTest extends _DomainEntityParameterRuleTest {
  @override
  String get ruleName => 'domain_raw_required_string';
  @override
  String get needle => 'String title,';
  @override
  String get path => '$testPackageLibPath/core/domain/entities/product.dart';
  @override
  String get source => entity('    required String title,\n    required DateTime createdAt,');

  Future<void> test_reportsEveryRawStringAroundAnnotatedParameters() async {
    final source = entity(
      '    required String id,\n    @Default(0) int stock,\n    required String description,',
    );
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      compatLint(source, 'String id,', ruleName),
      compatLint(source, 'String description,', ruleName),
    ]);
  }

  Future<void> test_allowsValueObjectsOptionalTextAndNamedUnionFactories() async {
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

  Future<void> test_allowsDataModelsAndValueObjects() async {
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

@reflectiveTest
final class DomainUnitPrimitiveTest extends _DomainEntityParameterRuleTest {
  @override
  String get ruleName => 'domain_unit_primitive';
  @override
  String get needle => 'int lengthCm,';
  @override
  String get path => '$testPackageLibPath/core/domain/entities/product.dart';
  @override
  String get source => entity('    required int lengthCm,\n    required DateTime createdAt,');

  Future<void> test_reportsDefaultedAndNullableUnitNumbers() async {
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

  Future<void> test_allowsShippedHiveEntityLockedSlots() async {
    await assertAllows(
      entity('    required String id,\n    /// HiveField(1)\n    required double distanceMeters,'),
      path: path,
      addIgnorePrefix: false,
    );
  }

  Future<void> test_allowsCountsAndTypedUnits() async {
    await assertAllows(
      entity(
        '    required int quantity,\n    required int items,\n    required Duration duration,',
      ),
      path: path,
      addIgnorePrefix: false,
    );
  }
}
