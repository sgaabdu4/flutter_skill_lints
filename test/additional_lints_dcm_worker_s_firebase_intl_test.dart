// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/incorrect_firebase_event_name.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/incorrect_firebase_parameter_name.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_date_format.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IncorrectFirebaseEventNameTest);
    defineReflectiveTests(IncorrectFirebaseParameterNameTest);
    defineReflectiveTests(PreferDateFormatTest);
  });
}

@reflectiveTest
final class IncorrectFirebaseEventNameTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = IncorrectFirebaseEventName();
    super.setUp();
  }

  Future<void> test_invalidLiteralName_lint() async {
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

  Future<void> test_positionalInvalidLiteralName_lint() async {
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

  Future<void> test_reservedLiteralName_lint() async {
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

  Future<void> test_validLiteralName_noLint() async {
    await assertNoDiagnostics(r'''
class Analytics {
  void logEvent({required String name, Map<String, Object?>? parameters}) {}
}

void f(Analytics analytics) {
  analytics.logEvent(name: 'checkout_started_2');
}
''');
  }

  Future<void> test_nonLiteralName_noLint() async {
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

@reflectiveTest
final class IncorrectFirebaseParameterNameTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = IncorrectFirebaseParameterName();
    super.setUp();
  }

  Future<void> test_invalidLiteralParameterName_lint() async {
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

  Future<void> test_reservedLiteralParameterName_lint() async {
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

  Future<void> test_validLiteralParameterNames_noLint() async {
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

  Future<void> test_nonLiteralParameters_noLint() async {
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

@reflectiveTest
final class PreferDateFormatTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferDateFormat();
    super.setUp();
  }

  Future<void> test_textDateTimeToString_lint() async {
    const source = r'''
class Text {
  const Text(String value);
}

Text f(DateTime createdAt) => Text(createdAt.toString());
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> test_textInterpolationDateTimeToString_lint() async {
    const source = r'''
class Text {
  const Text(String value);
}

Text f(DateTime createdAt) => Text('Created ${createdAt.toString()}');
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> test_textSpanDateTimeToString_lint() async {
    const source = r'''
class TextSpan {
  const TextSpan({String? text});
}

TextSpan f(DateTime createdAt) => TextSpan(text: createdAt.toString());
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> test_logDateTimeToString_noLint() async {
    await assertNoDiagnostics(r'''
void f(DateTime createdAt) {
  print(createdAt.toString());
}
''');
  }

  Future<void> test_textNonDateTimeToString_noLint() async {
    await assertNoDiagnostics(r'''
class Text {
  const Text(String value);
}

Text f(Object value) => Text(value.toString());
''');
  }
}
