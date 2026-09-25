// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

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
    final filePath = '$testPackageLibPath/features/items/domain/item.dart';
    newFile('$testPackageLibPath/features/items/domain/item.freezed.dart', r'''
part of 'item.dart';

mixin _$Item {}

final class _Item implements Item {
  const _Item({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}
''');
    newFile(filePath, r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'item.freezed.dart';

@freezed
sealed class Item with _$Item {
  const factory Item({
    required String id,
    required String name,
  }) = _Item;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsDomainToDomainPackageImport() async {
    final filePath = '$testPackageLibPath/features/items/domain/item.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:test_package/features/shared/domain/enums.dart';

final class Item {}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsMirroredDomainTestFlutterImport() async {
    final filePath =
        '$testPackageRootPath/test/features/auth/domain/values/email_address_test.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist
import 'package:flutter_test/flutter_test.dart';

void main() {}
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

  Future<void> test_reportsDartIoImportFromDomain() async {
    final filePath = '$testPackageLibPath/features/files/domain/entities/stored_file.dart';
    const source = r'''
// ignore_for_file: unused_import
import 'dart:io';

final class StoredFile {}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [compatLint(source, "import 'dart:io';", ruleName)]);
  }

  Future<void> test_reportsRelativeCoreExtensionImportFromDomain() async {
    newFile('$testPackageLibPath/core/extensions/num_extensions.dart', r'''
extension NumExtensions on num {
  num get doubled => this * 2;
}
''');
    final filePath = '$testPackageLibPath/features/runs/domain/entities/run.dart';
    const source = r'''
// ignore_for_file: unused_import
import '../../../../core/extensions/num_extensions.dart';

final class Run {}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, "import '../../../../core/extensions/num_extensions.dart';", ruleName),
    ]);
  }

  Future<void> test_allowsRelativeDomainAndPureDartImports() async {
    newFile('$testPackageLibPath/features/runs/domain/values/run_id.dart', r'''
final class RunId {}
''');
    final filePath = '$testPackageLibPath/features/runs/domain/entities/run.dart';
    newFile(filePath, r'''
// ignore_for_file: unused_import
import 'dart:math' as math;

import '../values/run_id.dart';

final class Run {}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

@reflectiveTest
final class ArchStorageSdkImportTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_storage_sdk_import';
  @override
  String get needle => "import 'dart:io';";
  @override
  String get path => '$testPackageLibPath/features/notes/presentation/notifiers/note_notifier.dart';
  @override
  String get source => r'''
import 'dart:io';

final class NoteNotifier {}
''';

  Future<void> test_reportsStorageSdkImportsInScreensRepositoriesAndServices() async {
    const imports = r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
''';
    for (final filePath in [
      '$testPackageLibPath/features/notes/presentation/screens/notes_screen.dart',
      '$testPackageLibPath/features/notes/repositories/note_repository.dart',
      '$testPackageLibPath/core/services/note_sync_service.dart',
    ]) {
      newFile(filePath, imports);
      await assertDiagnosticsInFile(filePath, [
        compatLint(imports, "import 'package:hive_ce_flutter/", ruleName),
        compatLint(imports, "import 'package:shared_preferences/", ruleName),
      ]);
    }
  }

  Future<void> test_allowsStorageSdkImportsInLocalDatasourcesAndMixins() async {
    await assertAllows(r'''
// ignore_for_file: uri_does_not_exist
import 'dart:io';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';
''', path: '$testPackageLibPath/features/notes/data/datasources/note_local_datasource.dart');
    await assertAllows(r'''
import 'dart:io';
''', path: '$testPackageLibPath/core/services/appwrite_pagination_mixin.dart');
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
