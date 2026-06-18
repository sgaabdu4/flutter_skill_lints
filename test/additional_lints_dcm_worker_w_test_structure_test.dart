// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_missing_test_files.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_top_level_members_in_tests.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_match_file_name.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidTopLevelMembersInTestsTest);
    defineReflectiveTests(PreferMatchFileNameTest);
    defineReflectiveTests(AvoidMissingTestFilesTest);
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
}
