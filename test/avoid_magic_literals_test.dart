// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_magic_literals.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidMagicLiteralsTest);
  });
}

@reflectiveTest
final class AvoidMagicLiteralsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMagicLiterals();
    super.setUp();
  }

  Future<void> test_reportsRawNumberLiteral() async {
    const source = r'''
class RecentSessions {
  void take(int count) {}
}

void recent(RecentSessions values) => values.take(60);
''';

    await assertDiagnostics(source, [lint(source.indexOf('60'), 2)]);
  }

  Future<void> test_reportsNumericComparisonBoundaries() async {
    const source = r'''
bool isKilometer(double distanceMeters) => distanceMeters >= 1000;
bool isLastCalendarRow(int row) => row < 6;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('1000'), 4),
      lint(source.indexOf('6'), 1),
    ]);
  }

  Future<void> test_allowsStatusCodeComparisonsForDedicatedRule() async {
    await assertNoDiagnostics(r'''
bool notFound(int? code) => code == 404;
bool failed(Response response) => response.statusCode >= 500;

class Response {
  Response(this.statusCode);

  final int statusCode;
}
''');
  }

  Future<void> test_reportsGeneratedLiteralAppeasementConstants() async {
    const source = r'''
const int _kInt_404 = 404;
const String _kStringActiveWorkout = 'active-workout';
const int analyticsText35 = 35;
const int calendarRows6 = 6;
final retryDelayMs250 = 250;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('_kInt_404'), '_kInt_404'.length),
      lint(source.indexOf('_kStringActiveWorkout'), '_kStringActiveWorkout'.length),
      lint(source.indexOf('analyticsText35'), 'analyticsText35'.length),
      lint(source.indexOf('calendarRows6'), 'calendarRows6'.length),
      lint(source.indexOf('retryDelayMs250'), 'retryDelayMs250'.length),
    ]);
  }

  Future<void> test_allowsVersionAndProtocolNumbersInNames() async {
    await assertNoDiagnostics(r'''
const int apiV2 = 2;
const int headingH2Level = 2;
const int utf8BitsPerByte = 8;
const int sha256Bits = 256;
''');
  }

  Future<void> test_allowsDedicatedErrorCodeOwnerClasses() async {
    await assertNoDiagnostics(r'''
abstract final class AppwriteErrorCodes {
  static const int tooManyRequests429 = 429;
  static const int serviceUnavailable503 = 503;
  static const int notFound404 = 404;
}
''');
  }

  Future<void> test_allowsDedicatedErrorCodeOwnerFiles() async {
    final filePath = '$testPackageLibPath/core/services/appwrite_error_codes.dart';
    newFile(filePath, r'''
abstract final class AppwriteCodes {
  static const int tooManyRequests429 = 429;
  static const int serviceUnavailable503 = 503;
  static const int notFound404 = 404;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsCommonNumericSentinelComparisons() async {
    await assertNoDiagnostics(r'''
bool hasDistance(double distanceMeters) => distanceMeters > 0;
bool hasPrevious(int index) => index > -1;
bool hasSingleItem(int count) => count == 1;
''');
  }

  Future<void> test_reportsRawStringLiteral() async {
    const source = r'''
Object? read(Map<String, Object?> data) => data['active-workout'];
''';

    await assertDiagnostics(source, [lint(source.indexOf("'active-workout'"), 16)]);
  }

  Future<void> test_reportsInlineDateFormatPatternArgument() async {
    const source = r'''
class DateLike {
  String formatted({required String pattern}) => pattern;
}

String label(DateLike timestamp) => timestamp.formatted(pattern: 'MM/dd');
''';

    await assertDiagnostics(source, [lint(source.indexOf("'MM/dd'"), 7)]);
  }

  Future<void> test_reportsInlineDateFormatConstructorPattern() async {
    const source = r'''
class DateFormat {
  DateFormat(String pattern);
}

DateFormat formatter() => DateFormat('MM/dd');
''';

    await assertDiagnostics(source, [lint(source.indexOf("'MM/dd'"), 7)]);
  }

  Future<void> test_reportsNamedDateFormatPatternReference() async {
    const source = r'''
const memberHistoryDatePattern = 'MM/dd';

class DateLike {
  String formatted({required String pattern}) => pattern;
}

String label(DateLike timestamp) => timestamp.formatted(pattern: memberHistoryDatePattern);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('memberHistoryDatePattern);'), 'memberHistoryDatePattern'.length),
    ]);
  }

  Future<void> test_reportsNamedDateFormatConstructorPatternReference() async {
    const source = r'''
const memberHistoryDatePattern = 'MM/dd';

class DateFormat {
  DateFormat(String pattern);
}

DateFormat formatter() => DateFormat(memberHistoryDatePattern);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('memberHistoryDatePattern);'), 'memberHistoryDatePattern'.length),
    ]);
  }

  Future<void> test_reportsStringInterpolationWithRawText() async {
    const source = r'''
class File {
  const File(String path);
}

File makeFile(String base, String name) => File('$base/$name');
''';

    await assertDiagnostics(source, [lint(source.indexOf(r"'$base/"), 13)]);
  }

  Future<void> test_allowsNamedConstDefinitionsAndReferences() async {
    await assertNoDiagnostics(r'''
const maxRecentSessions = 60;
const activeWorkoutKey = 'active-workout';

class RecentSessions {
  void take(int count) {}
}

void recent(RecentSessions values) => values.take(maxRecentSessions);

void track(Object value) {}

void save() {
  track(activeWorkoutKey);
}
''');
  }

  Future<void> test_allowsCommonSentinelNumbers() async {
    await assertNoDiagnostics(r'''
void use(Object value) {}

void update() {
  use(-1);
  use(0);
  use(1);
}
''');
  }

  Future<void> test_allowsImportsAndAnnotations() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

Timer? timer;

class Route {
  const Route({required String path});
}

@Route(path: '/home')
class HomeRoute {}
''');
  }

  Future<void> test_allowsConstantRegistryFiles() async {
    final filePath = '$testPackageLibPath/core/constants/app_strings.dart';
    newFile(filePath, r'''
final activeWorkoutKey = 'active-workout';
final maxRecentSessions = 60;
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsTestFiles() async {
    final filePath = '$testPackageRootPath/test/widget_test.dart';
    newFile(filePath, r'''
void main() {
  final value = 'active-workout';
  final count = 60;
  value;
  count;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}
