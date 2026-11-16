import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/incorrect_firebase_event_name.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/incorrect_firebase_parameter_name.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_date_format.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<IncorrectFirebaseEventNameTest>(
    'IncorrectFirebaseEventNameTest',
    IncorrectFirebaseEventNameTest.new,
    {
      'test_invalidLiteralName_lint': (t) => t._invalidLiteralNameLint(),
      'test_positionalInvalidLiteralName_lint': (t) => t._positionalInvalidLiteralNameLint(),
      'test_reservedLiteralName_lint': (t) => t._reservedLiteralNameLint(),
      'test_validLiteralName_noLint': (t) => t._validLiteralNameNoLint(),
      'test_nonLiteralName_noLint': (t) => t._nonLiteralNameNoLint(),
    },
  );
  analysisRuleSuite<IncorrectFirebaseParameterNameTest>(
    'IncorrectFirebaseParameterNameTest',
    IncorrectFirebaseParameterNameTest.new,
    {
      'test_invalidLiteralParameterName_lint': (t) => t._invalidLiteralParameterNameLint(),
      'test_reservedLiteralParameterName_lint': (t) => t._reservedLiteralParameterNameLint(),
      'test_validLiteralParameterNames_noLint': (t) => t._validLiteralParameterNamesNoLint(),
      'test_nonLiteralParameters_noLint': (t) => t._nonLiteralParametersNoLint(),
    },
  );
  analysisRuleSuite<PreferDateFormatTest>('PreferDateFormatTest', PreferDateFormatTest.new, {
    'test_textDateTimeToString_lint': (t) => t._textDateTimeToStringLint(),
    'test_textInterpolationDateTimeToString_lint': (t) =>
        t._textInterpolationDateTimeToStringLint(),
    'test_textSpanDateTimeToString_lint': (t) => t._textSpanDateTimeToStringLint(),
    'test_logDateTimeToString_noLint': (t) => t._logDateTimeToStringNoLint(),
    'test_textNonDateTimeToString_noLint': (t) => t._textNonDateTimeToStringNoLint(),
  });
}

final class IncorrectFirebaseEventNameTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = IncorrectFirebaseEventName();
    super.setUp();
  }

  Future<void> _invalidLiteralNameLint() async {
    const source = r'''
class Analytics {
  void logEvent({required String name, Map<String, Object?>? parameters}) {}
}

void f(Analytics analytics) {
  analytics.logEvent(name: 'checkout-started');
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'checkout-started'"), "'checkout-started'".length),
    ]);
  }

  Future<void> _positionalInvalidLiteralNameLint() async {
    const source = r'''
class Analytics {
  void logEvent(String name) {}
}

void f(Analytics analytics) {
  analytics.logEvent('1_checkout');
}
''';

    await assertDiagnostics(source, [lint(source.indexOf("'1_checkout'"), "'1_checkout'".length)]);
  }

  Future<void> _reservedLiteralNameLint() async {
    const source = r'''
class Analytics {
  void logEvent({required String name}) {}
}

void f(Analytics analytics) {
  analytics.logEvent(name: 'firebase_checkout');
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'firebase_checkout'"), "'firebase_checkout'".length),
    ]);
  }

  Future<void> _validLiteralNameNoLint() async {
    await assertNoDiagnostics(r'''
class Analytics {
  void logEvent({required String name, Map<String, Object?>? parameters}) {}
}

void f(Analytics analytics) {
  analytics.logEvent(name: 'checkout_started_2');
}
''');
  }

  Future<void> _nonLiteralNameNoLint() async {
    await assertNoDiagnostics(r'''
class Analytics {
  void logEvent({required String name}) {}
}

void f(Analytics analytics, String eventName) {
  analytics.logEvent(name: eventName);
}
''');
  }
}

final class IncorrectFirebaseParameterNameTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = IncorrectFirebaseParameterName();
    super.setUp();
  }

  Future<void> _invalidLiteralParameterNameLint() async {
    const source = r'''
class Analytics {
  void logEvent({required String name, Map<String, Object?>? parameters}) {}
}

void f(Analytics analytics) {
  analytics.logEvent(
    name: 'checkout_started',
    parameters: {'item-id': 'sku-1'},
  );
}
''';

    await assertDiagnostics(source, [lint(source.indexOf("'item-id'"), "'item-id'".length)]);
  }

  Future<void> _reservedLiteralParameterNameLint() async {
    const source = r'''
class Analytics {
  void logEvent({required String name, Map<String, Object?>? parameters}) {}
}

void f(Analytics analytics) {
  analytics.logEvent(
    name: 'checkout_started',
    parameters: {'ga_session': 'abc'},
  );
}
''';

    await assertDiagnostics(source, [lint(source.indexOf("'ga_session'"), "'ga_session'".length)]);
  }

  Future<void> _validLiteralParameterNamesNoLint() async {
    await assertNoDiagnostics(r'''
class Analytics {
  void logEvent({required String name, Map<String, Object?>? parameters}) {}
}

void f(Analytics analytics) {
  analytics.logEvent(
    name: 'checkout_started',
    parameters: {'item_id': 'sku-1', 'quantity2': 2},
  );
}
''');
  }

  Future<void> _nonLiteralParametersNoLint() async {
    await assertNoDiagnostics(r'''
class Analytics {
  void logEvent({required String name, Map<String, Object?>? parameters}) {}
}

void f(Analytics analytics, Map<String, Object?> params) {
  analytics.logEvent(name: 'checkout_started', parameters: params);
}
''');
  }
}

final class PreferDateFormatTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferDateFormat();
    super.setUp();
  }

  Future<void> _textDateTimeToStringLint() async {
    const source = r'''
class Text {
  const Text(String value);
}

Text f(DateTime createdAt) => Text(createdAt.toString());
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> _textInterpolationDateTimeToStringLint() async {
    const source = r'''
class Text {
  const Text(String value);
}

Text f(DateTime createdAt) => Text('Created ${createdAt.toString()}');
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> _textSpanDateTimeToStringLint() async {
    const source = r'''
class TextSpan {
  const TextSpan({String? text});
}

TextSpan f(DateTime createdAt) => TextSpan(text: createdAt.toString());
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> _logDateTimeToStringNoLint() async {
    await assertNoDiagnostics(r'''
void f(DateTime createdAt) {
  print(createdAt.toString());
}
''');
  }

  Future<void> _textNonDateTimeToStringNoLint() async {
    await assertNoDiagnostics(r'''
class Text {
  const Text(String value);
}

Text f(Object value) => Text(value.toString());
''');
  }
}
