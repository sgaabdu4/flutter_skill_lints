// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_number_format.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_providing_intl_description.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_providing_intl_examples.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferNumberFormatTest);
    defineReflectiveTests(PreferProvidingIntlDescriptionTest);
    defineReflectiveTests(PreferProvidingIntlExamplesTest);
  });
}

@reflectiveTest
final class PreferNumberFormatTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferNumberFormat();
    super.setUp();
  }

  Future<void> test_severity_info() async {
    expect(PreferNumberFormat.code.severity, DiagnosticSeverity.INFO);
  }

  Future<void> test_decimalPattern_lint() async {
    const source = r'''
class NumberFormat {
  NumberFormat([String? pattern, String? locale]);
}

void f() {
  NumberFormat('#,##0.###');
}
''';

    await assertDiagnostics(source, [lint(source.indexOf("'#,##0.###'"), "'#,##0.###'".length)]);
  }

  Future<void> test_percentPattern_lint() async {
    const source = r'''
class NumberFormat {
  NumberFormat([String? pattern, String? locale]);
}

void f() {
  NumberFormat('#,##0%', 'en_US');
}
''';

    await assertDiagnostics(source, [lint(source.indexOf("'#,##0%'"), "'#,##0%'".length)]);
  }

  Future<void> test_scientificPattern_lint() async {
    const source = r'''
class NumberFormat {
  NumberFormat([String? pattern, String? locale]);
}

void f() {
  NumberFormat('#E0');
}
''';

    await assertDiagnostics(source, [lint(source.indexOf("'#E0'"), "'#E0'".length)]);
  }

  Future<void> test_customPattern_noLint() async {
    await assertNoDiagnostics(r'''
class NumberFormat {
  NumberFormat([String? pattern, String? locale]);
}

void f() {
  NumberFormat('###.0#', 'en_US');
}
''');
  }

  Future<void> test_namedConstructor_noLint() async {
    await assertNoDiagnostics(r'''
class NumberFormat {
  NumberFormat.decimalPattern([String? locale]);
}

void f() {
  NumberFormat.decimalPattern('en_US');
}
''');
  }
}

@reflectiveTest
final class PreferProvidingIntlDescriptionTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferProvidingIntlDescription();
    super.setUp();
  }

  Future<void> test_severity_info() async {
    expect(PreferProvidingIntlDescription.code.severity, DiagnosticSeverity.INFO);
  }

  Future<void> test_missingDesc_lint() async {
    const source = r'''
class Intl {
  static String message(String value, {String? desc}) => value;
}

String f() => Intl.message('Hello');
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('message'), 'message'.length)]);
  }

  Future<void> test_nullDesc_lint() async {
    const source = r'''
class Intl {
  static String message(String value, {String? desc}) => value;
}

String f() => Intl.message('Hello', desc: null);
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('message'), 'message'.length)]);
  }

  Future<void> test_descProvided_noLint() async {
    await assertNoDiagnostics(r'''
class Intl {
  static String message(String value, {String? desc}) => value;
}

String f() => Intl.message('Hello', desc: 'Shown on the home page.');
''');
  }

  Future<void> test_otherIntlMethod_noLint() async {
    await assertNoDiagnostics(r'''
class Intl {
  static String plural(int count, {String? desc}) => '$count';
}

String f() => Intl.plural(1);
''');
  }
}

@reflectiveTest
final class PreferProvidingIntlExamplesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferProvidingIntlExamples();
    super.setUp();
  }

  Future<void> test_severity_info() async {
    expect(PreferProvidingIntlExamples.code.severity, DiagnosticSeverity.INFO);
  }

  Future<void> test_placeholdersWithoutExamples_lint() async {
    const source = r'''
class Intl {
  static String message(
    String value, {
    Map<String, Object>? placeholders,
    Map<String, Object>? examples,
  }) => value;
}

String f(String userName) {
  return Intl.message(
    'Hello $userName',
    placeholders: {'userName': userName},
  );
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("{'userName': userName}"), "{'userName': userName}".length),
    ]);
  }

  Future<void> test_placeholdersWithEmptyExamples_lint() async {
    const source = r'''
class Intl {
  static String message(
    String value, {
    Map<String, Object>? placeholders,
    Map<String, Object>? examples,
  }) => value;
}

String f(String userName) {
  return Intl.message(
    'Hello $userName',
    placeholders: {'userName': userName},
    examples: {},
  );
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("{'userName': userName}"), "{'userName': userName}".length),
    ]);
  }

  Future<void> test_placeholdersWithExamples_noLint() async {
    await assertNoDiagnostics(r'''
class Intl {
  static String message(
    String value, {
    Map<String, Object>? placeholders,
    Map<String, Object>? examples,
  }) => value;
}

String f(String userName) {
  return Intl.message(
    'Hello $userName',
    placeholders: {'userName': userName},
    examples: {'userName': 'Ada'},
  );
}
''');
  }

  Future<void> test_emptyPlaceholders_noLint() async {
    await assertNoDiagnostics(r'''
class Intl {
  static String message(
    String value, {
    Map<String, Object>? placeholders,
    Map<String, Object>? examples,
  }) => value;
}

String f() => Intl.message('Hello', placeholders: {});
''');
  }

  Future<void> test_nonLiteralPlaceholders_noLint() async {
    await assertNoDiagnostics(r'''
class Intl {
  static String message(
    String value, {
    Map<String, Object>? placeholders,
    Map<String, Object>? examples,
  }) => value;
}

String f(String userName, Map<String, Object> placeholders) {
  return Intl.message('Hello $userName', placeholders: placeholders);
}
''');
  }
}
