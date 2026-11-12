// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_missing_test_files.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_top_level_members_in_tests.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_match_file_name.dart';
import 'package:test/test.dart' show expect, lessThanOrEqualTo;
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidTopLevelMembersInTestsTest);
    defineReflectiveTests(PreferMatchFileNameTest);
    defineReflectiveTests(AvoidMissingTestFilesTest);
    defineReflectiveTests(AvoidMissingTestFilesReadsTest);
  });
}

@reflectiveTest
final class AvoidTopLevelMembersInTestsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidTopLevelMembersInTests();
    super.setUp();
  }

  Future<void> test_allowsMainOnly_noLint() async {
    await assertNoDiagnostics(r'''
void main() {
  void helper() {}

  helper();
}
''');
  }

  Future<void> test_topLevelFunctionInTest_lint() async {
    const source = r'''
void helper() {}

void main() {}
''';
    final path = '$testPackageRootPath/test/example_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(source.indexOf('helper'), 'helper'.length)]);
  }

  Future<void> test_privateTopLevelFunctionInTest_noLint() async {
    const source = r'''
void _helper() {}

void main() {
  _helper();
}
''';
    final path = '$testPackageRootPath/test/example_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_publicTopLevelVariableInTest_lint() async {
    const source = r'''
const helper = 1;

void main() {}
''';
    final path = '$testPackageRootPath/test/example_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(source.indexOf('helper'), 'helper'.length)]);
  }

  Future<void> test_privateTopLevelVariableInTest_noLint() async {
    const source = r'''
const _helper = 1;

void main() {
  print(_helper);
}
''';
    final path = '$testPackageRootPath/test/example_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_topLevelClassInTest_noLint() async {
    const source = r'''
class TestHarness {}

void main() {}
''';
    final path = '$testPackageRootPath/test/example_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_testSupportFile_noLint() async {
    const source = r'''
class TestHarness {}

void helper() {}
''';
    final path = '$testPackageRootPath/test/helpers/example.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }
}

@reflectiveTest
final class PreferMatchFileNameTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferMatchFileName();
    super.setUp();
  }

  Future<void> test_allowsDocumentedCrashFacadeFilename() async {
    final path = '$testPackageRootPath/lib/core/observability/crash_service.dart';
    newFile(path, 'class Crash {}');
    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_reportsUnrelatedPublicTypeInCrashServiceFile() async {
    final path = '$testPackageRootPath/lib/core/observability/crash_service.dart';
    newFile(path, 'class Foo {}');
    await assertDiagnosticsInFile(path, [lint(6, 3)]);
  }

  Future<void> test_allowsDocumentedDateTimeHelperFilename() async {
    final path = '$testPackageRootPath/lib/core/extensions/date_time_extensions.dart';
    newFile(path, 'abstract final class DateTimeX {}');
    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_reportsDifferentTypeInDateTimeHelperFilename() async {
    final path = '$testPackageRootPath/lib/core/extensions/date_time_extensions.dart';
    newFile(path, 'class Clock {}');
    await assertDiagnosticsInFile(path, [lint(6, 5)]);
  }

  Future<void> test_reportsDateTimeHelperOutsideCanonicalPath() async {
    final path = '$testPackageRootPath/lib/other/date_time_extensions.dart';
    newFile(path, 'abstract final class DateTimeX {}');
    await assertDiagnosticsInFile(path, [lint(21, 9)]);
  }

  Future<void> test_allowsInterfacePrefixFileName() async {
    final path =
        '$testPackageRootPath/lib/features/probe/domain/repositories/i_probe_b_items_repository.dart';
    newFile(path, '''
abstract interface class IProbeBItemsRepository {
  Future<void> save(String item);
}
''');
    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_reportsInterfacePrefixFileNameForConcreteClass() async {
    const source = '''
class IProbeBItemsRepository {}
''';
    final path = '$testPackageRootPath/lib/features/probe/data/i_probe_b_items_repository.dart';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [lint(source.indexOf('IProbe'), 22)]);
  }

  Future<void> test_matchingClassName_noLint() async {
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user_profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_matchingMixedCaseWord_noLint() async {
    const source = r'''
class WatchOnYouTubeButton {}
''';
    final path = '$testPackageRootPath/lib/watch_on_youtube_button.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_matchingInitialAcronymWord_noLint() async {
    const source = r'''
enum OAuthProvider { none }
''';
    final path = '$testPackageRootPath/lib/oauth_provider.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_mismatchedClassName_lint() async {
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/profile.dart';
    newFile(path, source);
    newFile('$testPackageRootPath/lib/profile.g.dart', r'''
part of 'profile.dart';
''');

    await assertDiagnosticsInFile(path, [
      lint(source.indexOf('UserProfile'), 'UserProfile'.length),
    ]);
  }

  Future<void> test_multiplePublicTypes_noLint() async {
    const source = r'''
class UserProfile {}
class UserAvatar {}
''';
    final path = '$testPackageRootPath/lib/profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_generatedFile_noLint() async {
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/profile.g.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_generatedPartDoesNotSkipFileNameLint() async {
    const source = r'''
part 'profile.config.dart';

class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/profile.dart';
    newFile(path, source);
    newFile('$testPackageRootPath/lib/profile.config.dart', r'''
part of 'profile.dart';
''');

    await assertDiagnosticsInFile(path, [
      lint(source.indexOf('UserProfile'), 'UserProfile'.length),
    ]);
  }

  Future<void> test_manualPartLibrary_noLint() async {
    const source = r'''
part 'reminder_days_selector.dart';
part 'workout_reminder_tile.dart';

class ReminderDaysPickerSheet {}
''';
    final path = '$testPackageRootPath/lib/notification_tiles.dart';
    newFile(path, source);
    newFile('$testPackageRootPath/lib/reminder_days_selector.dart', r'''
part of 'notification_tiles.dart';

class ReminderDaysSelector {}
''');
    newFile('$testPackageRootPath/lib/workout_reminder_tile.dart', r'''
part of 'notification_tiles.dart';

class WorkoutReminderTile {}
''');

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_partFile_noLint() async {
    const source = r'''
part of 'user_profile.dart';

class UserProfileHelper {}
''';
    final path = '$testPackageRootPath/lib/src/user_profile_helper.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_extensionDeclaration_noLint() async {
    const source = r'''
extension DateTimeX on DateTime {}
''';
    final path = '$testPackageRootPath/lib/core/extensions/date_time_extensions.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }
}

@reflectiveTest
final class AvoidMissingTestFilesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMissingTestFiles();
    super.setUp();
  }

  Future<void> test_missingSiblingTest_lint() async {
    newFolder('$testPackageRootPath/test');
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user_profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(0, 'class'.length)]);
  }

  Future<void> test_existingSiblingTest_noLint() async {
    newFolder('$testPackageRootPath/test');
    newFile('$testPackageRootPath/test/user_profile_test.dart', '''
void main() {}
''');
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user_profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_importedByNonSiblingTest_noLint() async {
    newFolder('$testPackageRootPath/test/features');
    newFile('$testPackageRootPath/test/features/profile_flow_test.dart', '''
import 'package:test/user_profile.dart';

void main() {
  UserProfile();
}
''');
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user_profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_exportedByImportedBarrel_noLint() async {
    newFolder('$testPackageRootPath/test/features');
    newFile('$testPackageRootPath/lib/profile.dart', '''
export 'user_profile.dart';
''');
    newFile('$testPackageRootPath/test/features/profile_flow_test.dart', '''
import 'package:test/profile.dart';

void main() {}
''');
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user_profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_importedByImportedOwner_noLint() async {
    newFolder('$testPackageRootPath/lib/screens');
    newFolder('$testPackageRootPath/lib/widgets');
    newFolder('$testPackageRootPath/test/features');
    newFile('$testPackageRootPath/lib/screens/profile_screen.dart', '''
import '../widgets/profile_header.dart';

class ProfileScreen {}
''');
    newFile('$testPackageRootPath/test/features/profile_screen_test.dart', '''
import 'package:test/screens/profile_screen.dart';

void main() {}
''');
    const source = r'''
class ProfileHeader {}
''';
    final path = '$testPackageRootPath/lib/widgets/profile_header.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_unrelatedImportedBarrel_lint() async {
    newFolder('$testPackageRootPath/test/features');
    newFile('$testPackageRootPath/lib/profile.dart', '''
export 'other_profile.dart';
''');
    newFile('$testPackageRootPath/lib/other_profile.dart', '''
class OtherProfile {}
''');
    newFile('$testPackageRootPath/test/features/profile_flow_test.dart', '''
import 'package:test/profile.dart';

void main() {}
''');
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user_profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(0, 'class'.length)]);
  }

  Future<void> test_noTestDirectory_noLint() async {
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user_profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_generatedFile_noLint() async {
    newFolder('$testPackageRootPath/test');
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user_profile.g.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_partOfFile_noLint() async {
    newFolder('$testPackageRootPath/test');
    const source = r'''
part of 'profile.dart';

class UserProfileHeader {}
''';
    final path = '$testPackageRootPath/lib/user_profile_header.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_exportOnlyBarrel_noLint() async {
    newFolder('$testPackageRootPath/test');
    newFile('$testPackageRootPath/lib/user_profile.dart', '''
class UserProfile {}
''');
    const source = r'''
library;

export 'user_profile.dart';
''';
    final path = '$testPackageRootPath/lib/profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_importOnlyFile_noLint() async {
    newFolder('$testPackageRootPath/test');
    newFile('$testPackageRootPath/lib/user_profile.dart', '''
class UserProfile {}
''');
    const source = r'''
// ignore: unused_import
import 'user_profile.dart';
''';
    final path = '$testPackageRootPath/lib/profile_imports.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_constantsFile_noLint() async {
    newFolder('$testPackageRootPath/test');
    const source = r'''
abstract final class UserStrings {
  static const title = 'Users';
}
''';
    final path = '$testPackageRootPath/lib/core/constants/user_strings.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_coreConfigSchemaFile_noLint() async {
    newFolder('$testPackageRootPath/test');
    const source = r'''
abstract final class UserRemoteSchema {
  static const tableId = 'users';
}
''';
    final path = '$testPackageRootPath/lib/core/config/user_remote_schema.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_nestedLibPathUsesNestedTestPath_noLint() async {
    newFolder('$testPackageRootPath/test/src');
    newFile('$testPackageRootPath/test/src/user_profile_test.dart', '''
void main() {}
''');
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/src/user_profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_relativeImportFromNestedTest_noLint() async {
    newFolder('$testPackageRootPath/test/features/profile');
    newFile('$testPackageRootPath/test/features/profile/flow_test.dart', '''
import '../../../lib/user_profile.dart';

void main() {}
''');
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user_profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_importCycleBetweenLibFiles_noLint() async {
    newFolder('$testPackageRootPath/test/features');
    newFile('$testPackageRootPath/lib/hub.dart', '''
import 'ring_a.dart';

class Hub {}
''');
    newFile('$testPackageRootPath/lib/ring_a.dart', '''
import 'ring_b.dart';

class RingA {}
''');
    newFile('$testPackageRootPath/lib/ring_b.dart', '''
import 'ring_a.dart';
import 'user_profile.dart';

class RingB {}
''');
    newFile('$testPackageRootPath/test/features/hub_test.dart', '''
import 'package:test/hub.dart';

void main() {}
''');
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user_profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_importCycleThatNeverReachesLibrary_lint() async {
    newFolder('$testPackageRootPath/test/features');
    newFile('$testPackageRootPath/lib/ring_a.dart', '''
import 'ring_b.dart';

class RingA {}
''');
    newFile('$testPackageRootPath/lib/ring_b.dart', '''
import 'ring_a.dart';

class RingB {}
''');
    newFile('$testPackageRootPath/test/features/ring_flow_test.dart', '''
import 'package:test/ring_a.dart';

void main() {}
''');
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user_profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(0, 'class'.length)]);
  }

  Future<void> test_importOfOtherPackage_lint() async {
    newFolder('$testPackageRootPath/test/features');
    newFile('$testPackageRootPath/test/features/other_flow_test.dart', '''
import 'package:other_package/user_profile.dart';

void main() {}
''');
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user_profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(0, 'class'.length)]);
  }

  Future<void> test_reachedOnlyThroughReadableLibFile_noLint() async {
    newFolder('$testPackageRootPath/test/features');
    newFile('$testPackageRootPath/lib/hub.dart', '''
import 'user_profile.dart';

class Hub {}
''');
    newFile('$testPackageRootPath/test/features/hub_test.dart', '''
import 'package:test/hub.dart';

void main() {}
''');
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user_profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_behindMissingLibFile_lint() async {
    newFolder('$testPackageRootPath/test/features');
    newFile('$testPackageRootPath/test/features/ghost_test.dart', '''
import 'package:test/ghost.dart';

void main() {}
''');
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user_profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(0, 'class'.length)]);
  }

  Future<void> test_cacheFollowsFileChanges() async {
    newFolder('$testPackageRootPath/test/features');
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user_profile.dart';
    newFile(path, source);
    final testPath = '$testPackageRootPath/test/features/profile_flow_test.dart';

    await assertDiagnosticsInFile(path, [lint(0, 'class'.length)]);

    newFile(testPath, '''
import 'package:test/user_profile.dart';

void main() {}
''');
    contextFor2(getFile(testPath)).changeFile(convertPath(testPath));
    await assertDiagnosticsInFile(path, []);

    deleteFile(testPath);
    contextFor2(getFile(testPath)).changeFile(convertPath(testPath));
    await assertDiagnosticsInFile(path, [lint(0, 'class'.length)]);
  }
}

@reflectiveTest
final class AvoidMissingTestFilesReadsTest extends AnalysisRuleTest {
  static const _chainLength = 30;
  static const _decoyLength = 20;
  static const _fillerTests = 40;

  final _reads = <String, int>{};

  late final _CountingResourceProvider _provider = _CountingResourceProvider(_reads);

  @override
  ResourceProvider get resourceProvider => _provider;

  @override
  void setUp() {
    rule = AvoidMissingTestFiles();
    super.setUp();
  }

  Future<void> test_readsEachFileFewTimes() async {
    String name(String prefix, int index) => '$prefix${index.toString().padLeft(2, '0')}';
    void writeChain(String prefix, int length) {
      for (var index = 0; index < length; index++) {
        final next = index + 1 < length ? "export '${name(prefix, index + 1)}.dart';\n" : '';
        newFile(
          '$testPackageRootPath/lib/${name(prefix, index)}.dart',
          '${next}class ${name(prefix.toUpperCase(), index)} {}\n',
        );
      }
    }

    newFolder('$testPackageRootPath/test');
    writeChain('c', _chainLength);
    writeChain('d', _decoyLength);
    for (var index = 0; index < _fillerTests; index++) {
      newFile('$testPackageRootPath/test/${name('f', index)}_test.dart', '''
import 'package:test/d00.dart';

void main() {}
''');
    }
    newFile('$testPackageRootPath/test/z_reach_test.dart', '''
import 'package:test/c00.dart';

void main() {}
''');

    _reads.clear();
    for (var index = 0; index < _chainLength; index++) {
      await assertDiagnosticsInFile('$testPackageRootPath/lib/${name('c', index)}.dart', []);
    }

    final dartReads = {
      for (final entry in _reads.entries)
        if (entry.key.startsWith('$testPackageRootPath/') && entry.key.endsWith('.dart'))
          entry.key: entry.value,
    };
    final total = dartReads.values.fold<int>(0, (sum, count) => sum + count);
    const libFiles = _chainLength + _decoyLength;
    const bound = 2 * (_fillerTests + 1 + libFiles) + 10;
    expect(total, lessThanOrEqualTo(bound), reason: 'dart file reads: $total, bound: $bound');
  }
}

final class _CountingResourceProvider extends MemoryResourceProvider {
  _CountingResourceProvider(this.reads);

  final Map<String, int> reads;

  @override
  File getFile(String path) => _counted(super.getFile(path), reads) as File;

  @override
  Folder getFolder(String path) => _counted(super.getFolder(path), reads) as Folder;
}

Resource _counted(Resource resource, Map<String, int> reads) {
  if (resource is _CountingFile || resource is _CountingFolder) return resource;
  if (resource is File) return _CountingFile(resource, reads);
  if (resource is Folder) return _CountingFolder(resource, reads);
  return resource;
}

final class _CountingFile implements File {
  _CountingFile(this._inner, this._reads);

  final File _inner;
  final Map<String, int> _reads;

  @override
  Folder get parent => _counted(_inner.parent, _reads) as Folder;

  @override
  String readAsStringSync() {
    _count();
    return _inner.readAsStringSync();
  }

  @override
  Uint8List readAsBytesSync() {
    _count();
    return _inner.readAsBytesSync();
  }

  void _count() => _reads.update(_inner.path, (count) => count + 1, ifAbsent: () => 1);

  @override
  bool get exists => _inner.exists;

  @override
  int get lengthSync => _inner.lengthSync;

  @override
  int get modificationStamp => _inner.modificationStamp;

  @override
  String get path => _inner.path;

  @override
  ResourceProvider get provider => _inner.provider;

  @override
  String get shortName => _inner.shortName;

  @override
  File copyTo(Folder parentFolder) => _inner.copyTo(parentFolder);

  @override
  void delete() => _inner.delete();

  @override
  bool isOrContains(String path) => _inner.isOrContains(path);

  @override
  File renameSync(String newPath) => _inner.renameSync(newPath);

  @override
  Resource resolveSymbolicLinksSync() => _inner.resolveSymbolicLinksSync();

  @override
  Uri toUri() => _inner.toUri();

  @override
  ResourceWatcher watch() => _inner.watch();

  @override
  void writeAsBytesSync(List<int> bytes) => _inner.writeAsBytesSync(bytes);

  @override
  void writeAsStringSync(String content) => _inner.writeAsStringSync(content);
}

final class _CountingFolder implements Folder {
  _CountingFolder(this._inner, this._reads);

  final Folder _inner;
  final Map<String, int> _reads;

  @override
  Folder get parent => _counted(_inner.parent, _reads) as Folder;

  @override
  List<Resource> getChildren() => [
    for (final child in _inner.getChildren()) _counted(child, _reads),
  ];

  @override
  File getFile(String relPath) => _counted(_inner.getFile(relPath), _reads) as File;

  @override
  Folder getFolder(String relPath) => _counted(_inner.getFolder(relPath), _reads) as Folder;

  @override
  Resource getChild(String relPath) => _counted(_inner.getChild(relPath), _reads);

  @override
  File getChildAssumingFile(String relPath) => getFile(relPath);

  @override
  Folder getChildAssumingFolder(String relPath) => getFolder(relPath);

  @override
  bool get exists => _inner.exists;

  @override
  bool get isRoot => _inner.isRoot;

  @override
  String get path => _inner.path;

  @override
  ResourceProvider get provider => _inner.provider;

  @override
  String get shortName => _inner.shortName;

  @override
  String canonicalizePath(String path) => _inner.canonicalizePath(path);

  @override
  bool contains(String path) => _inner.contains(path);

  @override
  Folder copyTo(Folder parentFolder) => _inner.copyTo(parentFolder);

  @override
  void create() => _inner.create();

  @override
  void delete() => _inner.delete();

  @override
  bool isOrContains(String path) => _inner.isOrContains(path);

  @override
  Resource resolveSymbolicLinksSync() => _inner.resolveSymbolicLinksSync();

  @override
  Uri toUri() => _inner.toUri();

  @override
  ResourceWatcher watch() => _inner.watch();
}
