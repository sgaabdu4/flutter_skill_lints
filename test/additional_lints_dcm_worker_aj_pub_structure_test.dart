// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/match_lib_folder_structure.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_caret_version_syntax.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/pubspec_ordering.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubspecOrderingTest);
    defineReflectiveTests(PreferCaretVersionSyntaxTest);
    defineReflectiveTests(MatchLibFolderStructureTest);
  });
}

@reflectiveTest
final class PubspecOrderingTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PubspecOrdering();
    super.setUp();
    newFile('$testPackageRootPath/lib/test.dart', 'library;');
  }

  Future<void> test_allowsOrderedPubspec_noLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec());

    await assertNoDiagnostics('library;');
  }

  Future<void> test_outOfOrderTopLevelSection_lint() async {
    newFile(
      '$testPackageRootPath/pubspec.yaml',
      _pubspec(
        body: '''
dependencies:
  meta: ^1.16.0
environment:
  sdk: ^3.10.0
''',
      ),
    );

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  Future<void> test_outOfOrderDependencies_lint() async {
    newFile(
      '$testPackageRootPath/pubspec.yaml',
      _pubspec(
        body: '''
environment:
  sdk: ^3.10.0
dependencies:
  meta: ^1.16.0
  analyzer: ^12.1.0
''',
      ),
    );

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  String _pubspec({
    String body = '''
environment:
  sdk: ^3.10.0
dependencies:
  analyzer: ^12.1.0
  meta: ^1.16.0
dev_dependencies:
  test: ^1.30.0
''',
  }) {
    return '''
name: test
description: Test package.
version: 1.0.0
$body
''';
  }
}

@reflectiveTest
final class PreferCaretVersionSyntaxTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferCaretVersionSyntax();
    super.setUp();
    newFile('$testPackageRootPath/lib/test.dart', 'library;');
  }

  Future<void> test_allowsCaretVersion_noLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec('^1.2.3'));

    await assertNoDiagnostics('library;');
  }

  Future<void> test_caretEquivalentRange_lint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec('">=1.2.3 <2.0.0"'));

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  Future<void> test_nonEquivalentRange_noLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec('">=1.2.3 <3.0.0"'));

    await assertNoDiagnostics('library;');
  }

  Future<void> test_zeroMajorCaretEquivalentRange_lint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec('">=0.2.3 <0.3.0"'));

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  String _pubspec(String version) {
    return '''
name: test
environment:
  sdk: ^3.10.0
dependencies:
  meta: $version
''';
  }
}

@reflectiveTest
final class MatchLibFolderStructureTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = MatchLibFolderStructure();
    super.setUp();
    newFile('$testPackageRootPath/pubspec.yaml', '''
name: test
environment:
  sdk: ^3.10.0
''');
    newFile('$testPackageRootPath/lib/src/user_profile.dart', '''
class UserProfile {}
''');
  }

  Future<void> test_matchingTestPath_noLint() async {
    const source = r'''
import 'package:test/src/user_profile.dart';

void main() {}

const profile = UserProfile;
''';
    final path = '$testPackageRootPath/test/src/user_profile_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_mismatchedTestPath_lint() async {
    const source = r'''
import 'package:test/src/user_profile.dart';

void main() {}

const profile = UserProfile;
''';
    final path = '$testPackageRootPath/test/user_profile_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(0, 'import'.length)]);
  }

  Future<void> test_nonLibTopLevelTestFolder_noLint() async {
    const source = r'''
import 'package:test/src/user_profile.dart';

void main() {}

const profile = UserProfile;
''';
    final path = '$testPackageRootPath/test/functions/user_profile_contract_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_multiplePackageImports_noLint() async {
    newFile('$testPackageRootPath/lib/src/user_avatar.dart', '''
class UserAvatar {}
''');
    const source = r'''
import 'package:test/src/user_avatar.dart';
import 'package:test/src/user_profile.dart';

void main() {}

const profile = UserProfile;
const avatar = UserAvatar;
''';
    final path = '$testPackageRootPath/test/user_profile_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }
}
