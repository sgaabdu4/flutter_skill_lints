import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/match_lib_folder_structure.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_caret_version_syntax.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/pubspec_ordering.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_PubspecOrderingTest>(
    'PubspecOrderingTest',
    _PubspecOrderingTest.new,
    _PubspecOrderingTest._allCases,
  );
  analysisRuleSuite<_PreferCaretVersionSyntaxTest>(
    'PreferCaretVersionSyntaxTest',
    _PreferCaretVersionSyntaxTest.new,
    _PreferCaretVersionSyntaxTest._allCases,
  );
  analysisRuleSuite<_MatchLibFolderStructureTest>(
    'MatchLibFolderStructureTest',
    _MatchLibFolderStructureTest.new,
    _MatchLibFolderStructureTest._allCases,
  );
}

final class _PubspecOrderingTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_PubspecOrderingTest)> get _allCases =>
      caseSet<_PubspecOrderingTest>(
        parent: const {},
        own: {
          'test_allowsOrderedPubspec_noLint': (t) => t._allowsOrderedPubspecNoLint(),
          'test_outOfOrderTopLevelSection_lint': (t) => t._outOfOrderTopLevelSectionLint(),
          'test_outOfOrderDependencies_lint': (t) => t._outOfOrderDependenciesLint(),
        },
      );

  @override
  void setUp() {
    rule = PubspecOrdering();
    super.setUp();
    newFile('$testPackageRootPath/lib/test.dart', 'library;');
  }

  Future<void> _allowsOrderedPubspecNoLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec());

    await assertNoDiagnostics('library;');
  }

  Future<void> _outOfOrderTopLevelSectionLint() async {
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

  Future<void> _outOfOrderDependenciesLint() async {
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

final class _PreferCaretVersionSyntaxTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_PreferCaretVersionSyntaxTest)> get _allCases =>
      caseSet<_PreferCaretVersionSyntaxTest>(
        parent: const {},
        own: {
          'test_allowsCaretVersion_noLint': (t) => t._allowsCaretVersionNoLint(),
          'test_caretEquivalentRange_lint': (t) => t._caretEquivalentRangeLint(),
          'test_nonEquivalentRange_noLint': (t) => t._nonEquivalentRangeNoLint(),
          'test_zeroMajorCaretEquivalentRange_lint': (t) => t._zeroMajorCaretEquivalentRangeLint(),
        },
      );

  @override
  void setUp() {
    rule = PreferCaretVersionSyntax();
    super.setUp();
    newFile('$testPackageRootPath/lib/test.dart', 'library;');
  }

  Future<void> _allowsCaretVersionNoLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec('^1.2.3'));

    await assertNoDiagnostics('library;');
  }

  Future<void> _caretEquivalentRangeLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec('">=1.2.3 <2.0.0"'));

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  Future<void> _nonEquivalentRangeNoLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec('">=1.2.3 <3.0.0"'));

    await assertNoDiagnostics('library;');
  }

  Future<void> _zeroMajorCaretEquivalentRangeLint() async {
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

final class _MatchLibFolderStructureTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_MatchLibFolderStructureTest)> get _allCases =>
      caseSet<_MatchLibFolderStructureTest>(
        parent: const {},
        own: {
          'test_matchingTestPath_noLint': (t) => t._matchingTestPathNoLint(),
          'test_mismatchedTestPath_lint': (t) => t._mismatchedTestPathLint(),
          'test_nonLibTopLevelTestFolder_noLint': (t) => t._nonLibTopLevelTestFolderNoLint(),
          'test_multiplePackageImports_noLint': (t) => t._multiplePackageImportsNoLint(),
        },
      );

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

  Future<void> _matchingTestPathNoLint() async {
    const source = r'''
import 'package:test/src/user_profile.dart';

void main() {}

const profile = UserProfile;
''';
    final path = '$testPackageRootPath/test/src/user_profile_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> _mismatchedTestPathLint() async {
    const source = r'''
import 'package:test/src/user_profile.dart';

void main() {}

const profile = UserProfile;
''';
    final path = '$testPackageRootPath/test/user_profile_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(0, 'import'.length)]);
  }

  Future<void> _nonLibTopLevelTestFolderNoLint() async {
    const source = r'''
import 'package:test/src/user_profile.dart';

void main() {}

const profile = UserProfile;
''';
    final path = '$testPackageRootPath/test/functions/user_profile_contract_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> _multiplePackageImportsNoLint() async {
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
