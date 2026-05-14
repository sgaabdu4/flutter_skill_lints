// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_inline_error_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidInlineErrorCodesTest);
  });
}

@reflectiveTest
final class AvoidInlineErrorCodesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidInlineErrorCodes();
    super.setUp();
  }

  Future<void> test_reportsInlineErrorAndStatusCodeComparisons() async {
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

  Future<void> test_allowsNamedCodeOwnerComparisons() async {
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

  Future<void> test_allowsDedicatedCodeOwnerFiles() async {
    final filePath = '$testPackageLibPath/core/errors/app_error_codes.dart';
    newFile(filePath, r'''
abstract final class AppErrorCodes {
  static const notFound = 404;
  static const rateLimited = 429;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsNonStatusCodeNumericComparisons() async {
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
