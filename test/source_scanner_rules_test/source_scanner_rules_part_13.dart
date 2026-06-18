// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class DomainCustomCopyWithTest extends _ValueObjectRuleTest {
  @override
  String get ruleName => 'domain_custom_copy_with';
  @override
  String get needle => 'copyWith';
  @override
  String get path => '$testPackageLibPath/features/users/domain/user.dart';
  @override
  String get source => r'''
class User {
  const User({required this.id});
  final String id;
  User copyWith({String? id}) => User(id: id ?? this.id);
}
''';

  Future<void> test_allowsCopyWithCallSite() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
// ignore_for_file: undefined_method
class User {
  const User({required this.id});
  final String id;
}

void use(User u) {
  final next = u.copyWith();
  next.toString();
}

extension on User {
  User copyAgain() => this;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsCopyWithOutsideDomain() async {
    final filePath = '$testPackageLibPath/features/users/presentation/user_state.dart';
    newFile(filePath, r'''
class UserState {
  const UserState({required this.id});
  final String id;
  UserState copyWith({String? id}) => UserState(id: id ?? this.id);
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsCopyWithCommentInDomain() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
class User {
  const User({required this.id});
  final String id;
  // Note: Freezed generates copyWith automatically; do not declare manually.
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsCopyWithInGeneratedMixin() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
// ignore_for_file: undefined_class, undefined_method
mixin _$User {
  User copyWith({String? id}) => throw UnimplementedError();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsGenericCopyWith() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    const source = r'''
class User {
  const User({required this.id});
  final String id;
  User copyWith<T>({String? id}) => User(id: id ?? this.id);
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [compatLint(source, 'copyWith<T>', ruleName)]);
  }

  Future<void> test_reportsAbstractCopyWithSignature() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    const source = r'''
abstract class User {
  const User();
  User copyWith({String? id});
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'copyWith({String? id})', ruleName),
    ]);
  }

  Future<void> test_allowsCopyWithInExtensionOutsideClass() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
class User {
  const User({required this.id});
  final String id;
}

extension UserCopy on User {
  User copyWith({String? id}) => User(id: id ?? this.id);
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

@reflectiveTest
final class FreezedDisableMapWhenRequiredTest extends _ValueObjectRuleTest {
  @override
  String get ruleName => 'freezed_disable_map_when_required';
  @override
  String get needle => 'sealed class Distance';
  @override
  String get path => '$testPackageLibPath/core/domain/values/distance.dart';
  @override
  bool get addIgnorePrefix => false;

  @override
  void setUp() {
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed {
  const Freezed({Object? map, Object? when});
}
class FreezedMapOptions {
  static const Object none = Object();
}
class FreezedWhenOptions {
  static const Object none = Object();
}
const freezed = Freezed();
''');
    super.setUp();
  }

  @override
  String get source => r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, mixin_of_non_class, redirect_to_non_class, extends_non_class
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class Distance with _$Distance {
  const Distance._();
  const factory Distance._meters(double value) = _Meters;
}
''';

  Future<void> test_allowsFullOptOut() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, mixin_of_non_class, redirect_to_non_class, extends_non_class
import 'package:freezed_annotation/freezed_annotation.dart';

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
sealed class Distance with _$Distance {
  const Distance._();
  const factory Distance._meters(double value) = _Meters;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsPartialOptOutMissingWhen() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    const partialSource = r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, mixin_of_non_class, redirect_to_non_class, extends_non_class
import 'package:freezed_annotation/freezed_annotation.dart';

@Freezed(map: FreezedMapOptions.none)
sealed class Distance with _$Distance {
  const Distance._();
  const factory Distance._meters(double value) = _Meters;
}
''';
    newFile(filePath, partialSource);

    await assertDiagnosticsInFile(filePath, [
      compatLint(partialSource, 'sealed class Distance', ruleName),
    ]);
  }

  Future<void> test_reportsPartialOptOutMissingMap() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    const partialSource = r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, mixin_of_non_class, redirect_to_non_class, extends_non_class
import 'package:freezed_annotation/freezed_annotation.dart';

@Freezed(when: FreezedWhenOptions.none)
sealed class Distance with _$Distance {
  const Distance._();
  const factory Distance._meters(double value) = _Meters;
}
''';
    newFile(filePath, partialSource);

    await assertDiagnosticsInFile(filePath, [
      compatLint(partialSource, 'sealed class Distance', ruleName),
    ]);
  }

  Future<void> test_allowsNonSealedFreezedClass() async {
    final filePath = '$testPackageLibPath/core/domain/values/money.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, mixin_of_non_class, redirect_to_non_class, extends_non_class
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
class Money with _$Money {
  const Money._();
  const factory Money({required int cents}) = _Money;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsOutsideValueObjectsPath() async {
    final filePath = '$testPackageLibPath/features/users/domain/entities/user.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, mixin_of_non_class, redirect_to_non_class, extends_non_class
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class User with _$User {
  const User._();
  const factory User({required String id}) = _User;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsMultilineFullOptOut() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, mixin_of_non_class, redirect_to_non_class, extends_non_class
import 'package:freezed_annotation/freezed_annotation.dart';

@Freezed(
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class Distance with _$Distance {
  const Distance._();
  const factory Distance._meters(double value) = _Meters;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsNoFreezedAnnotation() async {
    final filePath = '$testPackageLibPath/core/domain/values/state.dart';
    newFile(filePath, r'''
sealed class AppState {
  const AppState();
}
class IdleState extends AppState {
  const IdleState();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

abstract class _HivePersistenceRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => hivePersistenceSourceRules;
}

@reflectiveTest
final class HiveFieldNoVoTypeTest extends _HivePersistenceRuleTest {
  @override
  String get ruleName => 'hive_field_no_vo_type';
  @override
  String get needle => 'Distance distance';
  @override
  String get path => '$testPackageLibPath/features/items/data/models/item_set_model.dart';
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
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class EntryModel {
  const factory EntryModel({
    required String id,
    required Distance distance,
  }) = _EntryModel;
}
class _EntryModel implements EntryModel {
  const _EntryModel({required this.id, required this.distance});
  final String id;
  final Distance distance;
}
''';

  Future<void> test_allowsPrimitiveTypedParams() async {
    final filePath = '$testPackageLibPath/features/items/data/models/item_set_model.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class EntryModel {
  const factory EntryModel({
    /// HiveField(0)
    required String id,
    /// HiveField(1)
    required double distanceMeters,
    /// HiveField(2)
    required int durationSeconds,
  }) = _EntryModel;
}
class _EntryModel implements EntryModel {
  const _EntryModel({required this.id, required this.distanceMeters, required this.durationSeconds});
  final String id;
  final double distanceMeters;
  final int durationSeconds;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsImportedVoNotInBaselineList() async {
    final filePath = '$testPackageLibPath/features/cycling/data/models/ride_model.dart';
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:test_package/features/cycling/domain/values/cadence.dart';

@freezed
sealed class RideModel {
  const factory RideModel({required Cadence cadence}) = _RideModel;
}
class _RideModel implements RideModel {
  const _RideModel({required this.cadence});
  final Cadence cadence;
}
''';
    newFile('$testPackageLibPath/features/cycling/domain/values/cadence.dart', r'''
class Cadence {
  const Cadence._(this.rpm);
  final int rpm;
}
''');
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'Cadence cadence', 'hive_field_no_vo_type'),
    ]);
  }

  Future<void> test_allowsVoTypeOutsideDataModelsPath() async {
    final filePath = '$testPackageLibPath/features/items/domain/entities/item_set.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class ItemSet {
  const factory ItemSet({
    required String id,
    required Distance distance,
  }) = _ItemSet;
}
class _ItemSet implements ItemSet {
  const _ItemSet({required this.id, required this.distance});
  final String id;
  final Distance distance;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsNullableVoParam() async {
    final filePath = '$testPackageLibPath/features/items/data/models/item_set_model.dart';
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class EntryModel {
  const factory EntryModel({
    required String id,
    Distance? distance,
  }) = _EntryModel;
}
class _EntryModel implements EntryModel {
  const _EntryModel({required this.id, this.distance});
  final String id;
  final Distance? distance;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [compatLint(source, 'Distance? distance', ruleName)]);
  }

  Future<void> test_reportsVoInsideListGeneric() async {
    final filePath = '$testPackageLibPath/features/items/data/models/item_set_model.dart';
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, non_type_as_type_argument
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class EntryModel {
  const factory EntryModel({
    required List<Distance> distances,
  }) = _EntryModel;
}
class _EntryModel implements EntryModel {
  const _EntryModel({required this.distances});
  final List distances;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [compatLint(source, 'Distance> distances', ruleName)]);
  }

  Future<void> test_reportsVoInsideMapGeneric() async {
    final filePath = '$testPackageLibPath/features/items/data/models/item_set_model.dart';
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, non_type_as_type_argument
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class EntryModel {
  const factory EntryModel({
    required Map<String, Money> totals,
  }) = _EntryModel;
}
class _EntryModel implements EntryModel {
  const _EntryModel({required this.totals});
  final Map totals;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [compatLint(source, 'Money> totals', ruleName)]);
  }

  Future<void> test_reportsMultiVoFromShowClause() async {
    final filePath = '$testPackageLibPath/features/cycling/data/models/ride_model.dart';
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:test_package/features/cycling/domain/values/units.dart' show Cadence, Tempo;

@freezed
sealed class RideModel {
  const factory RideModel({
    required Cadence cadence,
    required Tempo tempo,
  }) = _RideModel;
}
class _RideModel implements RideModel {
  const _RideModel({required this.cadence, required this.tempo});
  final Cadence cadence;
  final Tempo tempo;
}
''';
    newFile('$testPackageLibPath/features/cycling/domain/values/units.dart', r'''
class Cadence { const Cadence._(this.rpm); final int rpm; }
class Tempo { const Tempo._(this.bpm); final int bpm; }
''');
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'Cadence cadence', ruleName),
      compatLint(source, 'Tempo tempo', ruleName),
    ]);
  }
}

abstract class _DialogRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => dialogSourceRules;
}
