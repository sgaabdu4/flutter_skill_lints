import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_number_format.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_providing_intl_description.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_providing_intl_examples.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<PreferNumberFormatTest>('PreferNumberFormatTest', PreferNumberFormatTest.new, {
    'test_severity_info': (t) => t._severityInfo(),
    'test_decimalPattern_lint': (t) => t._decimalPatternLint(),
    'test_percentPattern_lint': (t) => t._percentPatternLint(),
    'test_scientificPattern_lint': (t) => t._scientificPatternLint(),
    'test_customPattern_noLint': (t) => t._customPatternNoLint(),
    'test_namedConstructor_noLint': (t) => t._namedConstructorNoLint(),
  });
  analysisRuleSuite<PreferProvidingIntlDescriptionTest>(
    'PreferProvidingIntlDescriptionTest',
    PreferProvidingIntlDescriptionTest.new,
    {
      'test_severity_info': (t) => t._severityInfo(),
      'test_missingDesc_lint': (t) => t._missingDescLint(),
      'test_nullDesc_lint': (t) => t._nullDescLint(),
      'test_descProvided_noLint': (t) => t._descProvidedNoLint(),
      'test_otherIntlMethod_noLint': (t) => t._otherIntlMethodNoLint(),
    },
  );
  analysisRuleSuite<PreferProvidingIntlExamplesTest>(
    'PreferProvidingIntlExamplesTest',
    PreferProvidingIntlExamplesTest.new,
    {
      'test_severity_info': (t) => t._severityInfo(),
      'test_placeholdersWithoutExamples_lint': (t) => t._placeholdersWithoutExamplesLint(),
      'test_placeholdersWithEmptyExamples_lint': (t) => t._placeholdersWithEmptyExamplesLint(),
      'test_placeholdersWithExamples_noLint': (t) => t._placeholdersWithExamplesNoLint(),
      'test_emptyPlaceholders_noLint': (t) => t._emptyPlaceholdersNoLint(),
      'test_nonLiteralPlaceholders_noLint': (t) => t._nonLiteralPlaceholdersNoLint(),
    },
  );
}

final class PreferNumberFormatTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferNumberFormat();
    super.setUp();
  }

  Future<void> _severityInfo() async {
    expect(PreferNumberFormat.code.severity, DiagnosticSeverity.INFO);
  }

  Future<void> _decimalPatternLint() async {
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

  Future<void> _percentPatternLint() async {
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

  Future<void> _scientificPatternLint() async {
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

  Future<void> _customPatternNoLint() async {
    await assertNoDiagnostics(r'''
class NumberFormat {
  NumberFormat([String? pattern, String? locale]);
}

void f() {
  NumberFormat('###.0#', 'en_US');
}
''');
  }

  Future<void> _namedConstructorNoLint() async {
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

final class PreferProvidingIntlDescriptionTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferProvidingIntlDescription();
    super.setUp();
  }

  Future<void> _severityInfo() async {
    expect(PreferProvidingIntlDescription.code.severity, DiagnosticSeverity.INFO);
  }

  Future<void> _missingDescLint() async {
    const source = r'''
class Intl {
  static String message(String value, {String? desc}) => value;
}

String f() => Intl.message('Hello');
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('message'), 'message'.length)]);
  }

  Future<void> _nullDescLint() async {
    const source = r'''
class Intl {
  static String message(String value, {String? desc}) => value;
}

String f() => Intl.message('Hello', desc: null);
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('message'), 'message'.length)]);
  }

  Future<void> _descProvidedNoLint() async {
    await assertNoDiagnostics(r'''
class Intl {
  static String message(String value, {String? desc}) => value;
}

String f() => Intl.message('Hello', desc: 'Shown on the home page.');
''');
  }

  Future<void> _otherIntlMethodNoLint() async {
    await assertNoDiagnostics(r'''
class Intl {
  static String plural(int count, {String? desc}) => '$count';
}

String f() => Intl.plural(1);
''');
  }
}

final class PreferProvidingIntlExamplesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferProvidingIntlExamples();
    super.setUp();
  }

  Future<void> _severityInfo() async {
    expect(PreferProvidingIntlExamples.code.severity, DiagnosticSeverity.INFO);
  }

  Future<void> _placeholdersWithoutExamplesLint() async {
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

  Future<void> _placeholdersWithEmptyExamplesLint() async {
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

  Future<void> _placeholdersWithExamplesNoLint() async {
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

  Future<void> _emptyPlaceholdersNoLint() async {
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

  Future<void> _nonLiteralPlaceholdersNoLint() async {
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
