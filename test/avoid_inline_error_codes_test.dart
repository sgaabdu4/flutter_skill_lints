import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_inline_error_codes.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidInlineErrorCodesTest>(
    'AvoidInlineErrorCodesTest',
    _AvoidInlineErrorCodesTest.new,
    _AvoidInlineErrorCodesTest._allCases,
  );
}

final class _AvoidInlineErrorCodesTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidInlineErrorCodesTest)> get _allCases =>
      caseSet<_AvoidInlineErrorCodesTest>(
        parent: const {},
        own: {
          'test_reportsInlineErrorAndStatusCodeComparisons': (t) =>
              t._reportsInlineErrorAndStatusCodeComparisons(),
          'test_allowsExceptionCodeRetryClassificationOnly': (t) =>
              t._allowsExceptionCodeRetryClassificationOnly(),
          'test_allowsNamedCodeOwnerComparisons': (t) => t._allowsNamedCodeOwnerComparisons(),
          'test_allowsDedicatedCodeOwnerFiles': (t) => t._allowsDedicatedCodeOwnerFiles(),
          'test_allowsNonStatusCodeNumericComparisons': (t) =>
              t._allowsNonStatusCodeNumericComparisons(),
        },
      );

  @override
  void setUp() {
    rule = AvoidInlineErrorCodes();
    super.setUp();
  }

  Future<void> _reportsInlineErrorAndStatusCodeComparisons() async {
    const source = r'''
bool notFound(AppwriteException e) => e.code == 404;
bool serverError(Response response) => response.statusCode >= 500;
bool hasErrorCode(int errorCode) => 13 == errorCode;

class AppwriteException {
  AppwriteException(this.code);

  final int? code;
}

class Response {
  Response(this.statusCode);

  final int statusCode;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('404'), 3),
      lint(source.indexOf('500'), 3),
      lint(source.indexOf('13'), 2),
    ]);
  }

  Future<void> _allowsExceptionCodeRetryClassificationOnly() async {
    const source = r'''
bool shouldRetry(Object e) {
  if (e is AppwriteException) return e.code == 429 || e.code == 503;
  return false;
}

bool notFound(Response response) => response.statusCode == 404;
bool rateLimited(Payload payload) => payload.code == 429;

class AppwriteException implements Exception {
  AppwriteException(this.code);

  final int? code;
}

class Response {
  Response(this.statusCode);

  final int statusCode;
}

class Payload {
  Payload(this.code);

  final int code;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('404'), 3),
      lint(source.lastIndexOf('429'), 3),
    ]);
  }

  Future<void> _allowsNamedCodeOwnerComparisons() async {
    await assertNoDiagnostics(r'''
bool notFound(AppwriteException e) => e.code == AppwriteErrorCodes.notFound;

abstract final class AppwriteErrorCodes {
  static const notFound = 404;
}

class AppwriteException {
  AppwriteException(this.code);

  final int? code;
}
''');
  }

  Future<void> _allowsDedicatedCodeOwnerFiles() async {
    final filePath = '$testPackageLibPath/core/errors/app_error_codes.dart';
    newFile(filePath, r'''
abstract final class AppErrorCodes {
  static const notFound = 404;
  static const rateLimited = 429;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsNonStatusCodeNumericComparisons() async {
    await assertNoDiagnostics(r'''
bool isKilometer(double distanceMeters) => distanceMeters >= 1000;
bool isLastCalendarRow(int row) => row < 6;
bool isDraft(Workflow workflow) => workflow.status == 2;

class Workflow {
  Workflow(this.status);

  final int status;
}
''');
  }
}
