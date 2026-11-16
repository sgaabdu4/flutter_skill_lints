import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_named_imports.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_importing_entrypoint_exports.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_incorrect_uri.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidDuplicateNamedImportsTest>(
    'AvoidDuplicateNamedImportsTest',
    AvoidDuplicateNamedImportsTest.new,
    {
      'test_sameUriDifferentPrefixes_lint': (t) => t._sameUriDifferentPrefixesLint(),
      'test_sameUriPrefixedAndUnprefixed_lint': (t) => t._sameUriPrefixedAndUnprefixedLint(),
      'test_sameUriSamePrefix_noLint': (t) => t._sameUriSamePrefixNoLint(),
      'test_distinctUris_noLint': (t) => t._distinctUrisNoLint(),
    },
  );
  analysisRuleSuite<AvoidImportingEntrypointExportsTest>(
    'AvoidImportingEntrypointExportsTest',
    AvoidImportingEntrypointExportsTest.new,
    {
      'test_srcImportsOwnEntrypoint_lint': (t) => t._srcImportsOwnEntrypointLint(),
      'test_srcImportsAnotherPackageEntrypoint_noLint': (t) =>
          t._srcImportsAnotherPackageEntrypointNoLint(),
    },
  );
  analysisRuleSuite<AvoidIncorrectUriTest>('AvoidIncorrectUriTest', AvoidIncorrectUriTest.new, {
    'test_backslashImportUri_lint': (t) => t._backslashImportUriLint(),
    'test_packageUriWithoutPath_lint': (t) => t._packageUriWithoutPathLint(),
    'test_partUriWithCurrentDirectorySegment_lint': (t) =>
        t._partUriWithCurrentDirectorySegmentLint(),
    'test_uriWithNonLeadingParentDirectorySegment_lint': (t) =>
        t._uriWithNonLeadingParentDirectorySegmentLint(),
    'test_uriWithLeadingParentDirectorySegments_noLint': (t) =>
        t._uriWithLeadingParentDirectorySegmentsNoLint(),
    'test_validUris_noLint': (t) => t._validUrisNoLint(),
  });
}

final class AvoidDuplicateNamedImportsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateNamedImports();
    super.setUp();
    newFile('$testPackageLibPath/src/a.dart', 'class A {}\n');
  }

  Future<void> _sameUriDifferentPrefixesLint() async {
    const source = r'''
// ignore_for_file: unused_import

import 'src/a.dart' as first;
import 'src/a.dart' as second;
''';

    await assertDiagnostics(source, [
      lint(source.lastIndexOf("'src/a.dart'"), "'src/a.dart'".length),
    ]);
  }

  Future<void> _sameUriPrefixedAndUnprefixedLint() async {
    const source = r'''
// ignore_for_file: unused_import

import 'src/a.dart';
import 'src/a.dart' as a;
''';

    await assertDiagnostics(source, [
      lint(source.lastIndexOf("'src/a.dart'"), "'src/a.dart'".length),
    ]);
  }

  Future<void> _sameUriSamePrefixNoLint() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: duplicate_import, unused_import

import 'src/a.dart' as a;
import 'src/a.dart' as a;
''');
  }

  Future<void> _distinctUrisNoLint() async {
    newFile('$testPackageLibPath/src/b.dart', 'class B {}\n');

    await assertNoDiagnostics(r'''
// ignore_for_file: unused_import

import 'src/a.dart' as a;
import 'src/b.dart' as b;
''');
  }
}

final class AvoidImportingEntrypointExportsTest extends AnalysisRuleTest {
  @override
  String get testFileName => 'src/feature.dart';

  @override
  void setUp() {
    rule = AvoidImportingEntrypointExports();
    newPackage('other').addFile('lib/other.dart', 'library;\n');
    super.setUp();
    newFile('$testPackageLibPath/test.dart', 'library;\n');
  }

  Future<void> _srcImportsOwnEntrypointLint() async {
    const source = r'''
// ignore_for_file: unused_import

import 'package:test/test.dart';
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'package:test/test.dart'"), "'package:test/test.dart'".length),
    ]);
  }

  Future<void> _srcImportsAnotherPackageEntrypointNoLint() async {
    const source = r'''
// ignore_for_file: unused_import

import 'dart:async';
''';

    await assertNoDiagnostics(source);
  }
}

final class AvoidIncorrectUriTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidIncorrectUri();
    super.setUp();
    newFile('$testPackageLibPath/src/a.dart', 'class A {}\n');
    newFile('$testPackageLibPath/src/b.dart', 'class B {}\n');
    newFile('$testPackageLibPath/src/part.dart', 'part of app;\n');
  }

  Future<void> _backslashImportUriLint() async {
    const source = r'''
// ignore_for_file: uri_does_not_exist

import 'src\a.dart';
''';

    await assertDiagnostics(source, [lint(source.indexOf("'src"), "'src\\a.dart'".length)]);
  }

  Future<void> _packageUriWithoutPathLint() async {
    const source = r'''
// ignore_for_file: uri_does_not_exist

export 'package:test';
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'package:test'"), "'package:test'".length),
    ]);
  }

  Future<void> _partUriWithCurrentDirectorySegmentLint() async {
    const source = r'''
// ignore_for_file: uri_does_not_exist

part './src/part.dart';
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'./src/part.dart'"), "'./src/part.dart'".length),
    ]);
  }

  Future<void> _uriWithNonLeadingParentDirectorySegmentLint() async {
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import

import 'src/../a.dart';
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'src/../a.dart'"), "'src/../a.dart'".length),
    ]);
  }

  Future<void> _uriWithLeadingParentDirectorySegmentsNoLint() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: uri_does_not_exist, unused_import

import '../../helpers/test_fakes.dart';
''');
  }

  Future<void> _validUrisNoLint() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: unused_import

library;

import 'dart:async';
import 'package:test/src/a.dart';
export 'src/b.dart';
part 'src/part.dart';
''');
  }
}
