// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_identical_exception_handling_blocks.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_try_statements.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_throw.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidNestedTryStatementsTest);
    defineReflectiveTests(AvoidIdenticalExceptionHandlingBlocksTest);
    defineReflectiveTests(AvoidThrowTest);
  });
}

@reflectiveTest
final class AvoidNestedTryStatementsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedTryStatements();
    super.setUp();
  }

  Future<void> test_tryInsideTryBody_lint() async {
    const source = r'''
void f() {
  try {
    try {
      print('inner');
    } catch (_) {
      print('inner failed');
    }
  } catch (_) {
    print('outer failed');
  }
}
''';

    final offset = source.indexOf('try {', source.indexOf('try {') + 1);
    final end = source.indexOf('\n  } catch (_) {\n    print(\'outer failed\');');

    await assertDiagnostics(source, [lint(offset, end - offset)]);
  }

  Future<void> test_tryInsideCatch_lint() async {
    const source = r'''
void f() {
  try {
    print('work');
  } catch (_) {
    try {
      print('recover');
    } catch (_) {}
  }
}
''';

    final offset = source.indexOf('try {', source.indexOf('catch (_)'));
    final end = source.indexOf('\n  }\n}', offset);

    await assertDiagnostics(source, [lint(offset, end - offset)]);
  }

  Future<void> test_tryInsideLocalFunction_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    void recover() {
      try {
        print('recover');
      } catch (_) {}
    }

    recover();
  } catch (_) {}
}
''');
  }

  Future<void> test_sequentialTryStatements_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('first');
  } catch (_) {}

  try {
    print('second');
  } catch (_) {}
}
''');
  }
}

@reflectiveTest
final class AvoidIdenticalExceptionHandlingBlocksTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidIdenticalExceptionHandlingBlocks();
    super.setUp();
  }

  Future<void> test_identicalCatchBodies_lintSecondBody() async {
    const source = r'''
void f() {
  try {
    print('work');
  } on FormatFailure {
    print('failed');
  } on StateFailure {
    print('failed');
  }
}

class FormatFailure implements Exception {}

class StateFailure implements Exception {}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('{', source.indexOf('on StateFailure')),
        source.indexOf('}', source.indexOf('on StateFailure')) -
            source.indexOf('{', source.indexOf('on StateFailure')) +
            1,
      ),
    ]);
  }

  Future<void> test_identicalCatchBodiesWithDifferentWhitespace_lintSecondBody() async {
    const source = r'''
void f() {
  try {
    print('work');
  } on FormatFailure {
    print(
      'failed',
    );
  } on StateFailure {
    print('failed');
  }
}

class FormatFailure implements Exception {}

class StateFailure implements Exception {}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('{', source.indexOf('on StateFailure')),
        source.indexOf('}', source.indexOf('on StateFailure')) -
            source.indexOf('{', source.indexOf('on StateFailure')) +
            1,
      ),
    ]);
  }

  Future<void> test_differentCatchBodies_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('work');
  } on FormatFailure {
    print('format');
  } on StateFailure {
    print('state');
  }
}

class FormatFailure implements Exception {}

class StateFailure implements Exception {}
''');
  }

  Future<void> test_emptyCatchBodies_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('work');
  } on FormatFailure {
  } on StateFailure {
  }
}

class FormatFailure implements Exception {}

class StateFailure implements Exception {}
''');
  }
}

@reflectiveTest
final class AvoidThrowTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidThrow();
    _addFlutterPackage();
    _addRiverpodPackage();
    _addRiverpodAnnotationPackage();
    super.setUp();
    _patchCoreSdk();
  }

  void _patchCoreSdk() {
    final core = getFile('$dartSdkPath/lib/core/core.dart');
    final source = core
        .readAsStringSync()
        .replaceFirst(
          'class FormatException implements Exception {}',
          'class FormatException implements Exception { const FormatException([String? message]); }',
        )
        .replaceFirst(
          'ArgumentError([dynamic message, @Since("2.14") String? name]);',
          '''ArgumentError([dynamic message, @Since("2.14") String? name]);
  ArgumentError.value(Object? value, [String? name, String? message]);''',
        )
        .replaceFirst('class Error {\n  Error();', '''class Error {
  Error();
  external static Never throwWithStackTrace(Object error, StackTrace stackTrace);''')
        .replaceFirst(
          'class UnsupportedError extends Error {',
          '''class UnimplementedError extends Error {
  UnimplementedError([String? message]);
}

class UnsupportedError extends Error {''',
        )
        .replaceFirst('int codeUnitAt(int index);', 'int codeUnitAt(int index);\n  String trim();')
        .replaceFirst(
          'abstract interface class StackTrace {}',
          'abstract interface class StackTrace { external static StackTrace get current; }',
        );
    core.writeAsStringSync(source);
  }

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
abstract class Widget {}
class SizedBox extends Widget {
  const SizedBox();
}
class BuildContext {}
abstract class StatelessWidget extends Widget {
  Widget build(BuildContext context);
}
abstract class State<T> {
  Widget build(BuildContext context);
}
class TextButton extends Widget {
  const TextButton({void Function()? onPressed});
}
''');
  }

  void _addRiverpodPackage() {
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
abstract class Notifier<T> {
  late T state;
}
''');
  }

  void _addRiverpodAnnotationPackage() {
    newPackage('riverpod_annotation').addFile('lib/riverpod_annotation.dart', r'''
class Ref {}
final class Riverpod {
  const Riverpod({bool keepAlive = false, List<Object>? dependencies});
}
const riverpod = Riverpod();
''');
  }

  void test_severity_error() {
    expect(AvoidThrow.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> test_scopedProviderOverrideStub_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@Riverpod(dependencies: [])
Future<int> scopedValue(Ref ref) => throw UnimplementedError();
''');
  }

  Future<void> test_nonScopedOrNonStubProviderThrow_lint() async {
    newFile('$testPackageLibPath/local_riverpod.dart', r'''
final class Riverpod {
  const Riverpod({List<Object>? dependencies});
}
''');
    const source = r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'local_riverpod.dart' as local;

@riverpod
Future<int> unscoped(Ref ref) => throw UnimplementedError('unscoped');

@Riverpod(dependencies: [])
Future<int> scopedString(Ref ref) => throw 'scoped';

@Riverpod(dependencies: [])
Future<int> scopedOtherError(Ref ref) => throw UnsupportedError('scoped');

@Riverpod(dependencies: [])
Future<int> scopedBlock(Ref ref) {
  throw UnimplementedError('block');
}

Future<int> plain(Ref ref) => throw UnimplementedError('plain');

@local.Riverpod(dependencies: [])
Future<int> localAnnotation(Ref ref) => throw UnimplementedError('local');
''';

    await assertDiagnostics(source, [
      for (final thrown in [
        "throw UnimplementedError('unscoped')",
        "throw 'scoped'",
        "throw UnsupportedError('scoped')",
        "throw UnimplementedError('block')",
        "throw UnimplementedError('plain')",
        "throw UnimplementedError('local')",
      ])
        lint(source.indexOf(thrown), thrown.length),
    ]);
  }

  Future<void> test_throwStatement_lint() async {
    const source = r'''
void f() {
  throw 'failed';
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('throw'), "throw 'failed'".length)]);
  }

  Future<void> test_throwExpressionBody_lint() async {
    const source = r'''
Never f() => throw 'failed';
''';

    await assertDiagnostics(source, [lint(source.indexOf('throw'), "throw 'failed'".length)]);
  }

  Future<void> test_documentedParserFormatException_noLint() async {
    await assertNoDiagnostics(r'''
Map<String, dynamic> parsePayload(String body) {
  final Object? decoded = body;
  if (decoded case Map<String, dynamic> payload) return payload;
  throw const FormatException();
}
''');
  }

  Future<void> test_typedExceptionSubtypeOutsidePresentation_noLint() async {
    await assertNoDiagnostics(r'''
final class RepositoryFailure implements Exception {
  const RepositoryFailure();
}

Never fail() => throw const RepositoryFailure();
''');
  }

  Future<void> test_baseExceptionErrorsAndUntypedValues_lint() async {
    const source = r'''
void baseException() => throw Exception('base');
final class FatalFailure extends Error {}
final class HybridFailure extends Error implements Exception {}
void stateError() => throw FatalFailure();
void hybridError() => throw HybridFailure();
void untyped(dynamic value) => throw value;
void stringFailure() => throw 'failure';
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('throw Exception'), 'throw Exception(\'base\')'.length),
      lint(source.indexOf('throw FatalFailure'), 'throw FatalFailure()'.length),
      lint(source.indexOf('throw HybridFailure'), 'throw HybridFailure()'.length),
      lint(source.indexOf('throw value'), 'throw value'.length),
      lint(source.indexOf("throw 'failure'"), "throw 'failure'".length),
    ]);
  }

  Future<void> test_nonExceptionFormatExceptionLookalike_lint() async {
    const source = r'''
final class FormatException {
  const FormatException();
}

Never decode() => throw const FormatException();
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('throw const FormatException'), 'throw const FormatException()'.length),
    ]);
  }

  Future<void> test_widgetAndStateBuildStillReportTypedThrows() async {
    const source = r'''
import 'package:flutter/widgets.dart';

final class PayloadWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => throw const FormatException('invalid');
}

final class PayloadState extends State<Object> {
  @override
  Widget build(BuildContext context) => throw const FormatException('invalid');
}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('throw const FormatException'),
        'throw const FormatException(\'invalid\')'.length,
      ),
      lint(
        source.indexOf('throw const FormatException', source.indexOf('final class PayloadState')),
        'throw const FormatException(\'invalid\')'.length,
      ),
    ]);
  }

  Future<void> test_widgetHelperMethodStillReportsTypedThrow() async {
    const source = r'''
import 'package:flutter/widgets.dart';

final class PayloadWidget extends StatelessWidget {
  void parsePayload() => throw const FormatException();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('throw const FormatException'), 'throw const FormatException()'.length),
    ]);
  }

  Future<void> test_sameUnitFlutterCallbackFunctionAndGenericTearoffsStillReport() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void topLevelSubmit() => throw const FormatException();
void genericTopLevelSubmit<T>() => throw const FormatException();

final class StateController {
  void submit() => throw const FormatException();
  void submitWithType<T>() => throw const FormatException();
}

final class PayloadState extends State<Object> {
  void load() => throw const FormatException();

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void registerCallbacks(StateController controller, PayloadState state) {
  TextButton(onPressed: topLevelSubmit);
  TextButton(onPressed: genericTopLevelSubmit<int>);
  TextButton(onPressed: controller.submit);
  TextButton(onPressed: controller.submitWithType<int>);
  TextButton(onPressed: state.load);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('throw const FormatException'), 'throw const FormatException()'.length),
      lint(
        source.indexOf('throw const FormatException', source.indexOf('void genericTopLevelSubmit')),
        'throw const FormatException()'.length,
      ),
      lint(
        source.indexOf(
          'throw const FormatException',
          source.indexOf('final class StateController'),
        ),
        'throw const FormatException()'.length,
      ),
      lint(
        source.indexOf('throw const FormatException', source.indexOf('void submitWithType')),
        'throw const FormatException()'.length,
      ),
      lint(
        source.indexOf('throw const FormatException', source.indexOf('final class PayloadState')),
        'throw const FormatException()'.length,
      ),
    ]);
  }

  Future<void> test_resolvedWidgetCallbackAndDeferredThrowStillReport() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void registerAction() {
  TextButton(
    onPressed: () {
      Future<void>.delayed(
        Duration.zero,
        () => throw const FormatException('invalid'),
      );
    },
  );
}

''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('throw const FormatException'),
        'throw const FormatException(\'invalid\')'.length,
      ),
    ]);
  }

  Future<void> test_lookalikeWidgetCallbackDoesNotCreateUiBoundary() async {
    await assertNoDiagnostics(r'''
class FakeTextButton {
  const FakeTextButton({void Function()? onPressed});
}

void registerAction() {
  FakeTextButton(onPressed: () => throw const FormatException());
}
''');
  }

  Future<void> test_genericErrorCallbackDoesNotHideUntypedThrow() async {
    const source = r'''
void registerFailureHandler() {
  Future<void>.value().catchError((Object error) => throw error);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('throw error'), 'throw error'.length)]);
  }

  Future<void> test_actualRiverpodNotifierMutationStillReportsTypedThrow() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

final class CounterNotifier extends Notifier<int> {
  void increment() {
    state = 1;
    throw const FormatException('invalid');
  }
}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('throw const FormatException'),
        'throw const FormatException(\'invalid\')'.length,
      ),
    ]);
  }

  Future<void> test_validatedValueObjectArgumentGuard_noLint() async {
    final path = '$testPackageLibPath/features/items/domain/values/required_text.dart';
    newFile(path, r'''
final class RequiredText {
  RequiredText._(this.value);
  final String value;

  factory RequiredText.from(String value) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, 'value', 'must not be empty');
    }
    return RequiredText._(value);
  }
}
''');
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_unrelatedThrowInValueObject_stillReports() async {
    final path = '$testPackageLibPath/features/items/domain/values/required_text.dart';
    const source = r'''
final class RequiredText {
  RequiredText._();
  factory RequiredText.from(String value) {
    if (value.isEmpty) throw 'unexpected';
    return RequiredText._();
  }
}
''';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [
      lint(source.indexOf("throw 'unexpected'"), "throw 'unexpected'".length),
    ]);
  }

  Future<void> test_valueObjectGuardThroughFinalParameterLocal_noLint() async {
    final path = '$testPackageLibPath/features/profile/domain/values/display_name.dart';
    newFile(path, r'''
final class DisplayName {
  const DisplayName._(this.value);
  final String value;

  factory DisplayName(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(input, 'input', 'DisplayName cannot be blank');
    }
    return DisplayName._(trimmed);
  }
}
''');
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_valueObjectGuardThroughNonFinalOrUnrelatedLocal_lint() async {
    final path = '$testPackageLibPath/features/profile/domain/values/display_name.dart';
    const source = r'''
final class DisplayName {
  const DisplayName._(this.value);
  final String value;

  factory DisplayName.mutable(String input) {
    var trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(input, 'input', 'mutable');
    }
    return DisplayName._(trimmed);
  }

  factory DisplayName.reassigned(String input) {
    var trimmed = input.trim();
    trimmed = 'fallback';
    if (trimmed.isEmpty) {
      throw ArgumentError.value(input, 'input', 'reassigned');
    }
    return DisplayName._(trimmed);
  }

  factory DisplayName.unrelated(String input) {
    final other = 'fixed'.trim();
    if (other.isEmpty) {
      throw ArgumentError.value(input, 'input', 'unrelated');
    }
    return DisplayName._(input);
  }

  factory DisplayName.state(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw UnsupportedError('unrelated throw');
    }
    return DisplayName._(trimmed);
  }
}
''';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [
      for (final message in ['mutable', 'reassigned', 'unrelated'])
        lint(
          source.indexOf("throw ArgumentError.value(input, 'input', '$message')"),
          "throw ArgumentError.value(input, 'input', '$message')".length,
        ),
      lint(
        source.indexOf('throw UnsupportedError'),
        "throw UnsupportedError('unrelated throw')".length,
      ),
    ]);
  }

  Future<void> test_coreThrowWithStackTraceUntypedValue_lint() async {
    const source = r'''
void throughApi() => Error.throwWithStackTrace('invalid', StackTrace.current);

void mismatchedStack(void Function() operation) {
  try {
    operation();
  } on Object catch (error) {
    Error.throwWithStackTrace(error, StackTrace.current);
  }
}

void freshError(void Function() operation) {
  try {
    operation();
  } on Object catch (error, stack) {
    Error.throwWithStackTrace(UnsupportedError('wrapped'), stack);
  }
}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf("Error.throwWithStackTrace('invalid'"),
        "Error.throwWithStackTrace('invalid', StackTrace.current)".length,
      ),
      lint(
        source.indexOf('Error.throwWithStackTrace(error'),
        'Error.throwWithStackTrace(error, StackTrace.current)'.length,
      ),
      lint(
        source.indexOf('Error.throwWithStackTrace(UnsupportedError'),
        "Error.throwWithStackTrace(UnsupportedError('wrapped'), stack)".length,
      ),
    ]);
  }

  Future<void> test_coreThrowWithStackTracePropagationAndTypedFailure_noLint() async {
    await assertNoDiagnostics(r'''
final class RepositoryException implements Exception {
  const RepositoryException();
}

void preserveOriginal(void Function() operation) {
  try {
    operation();
  } on Object catch (error, stack) {
    Error.throwWithStackTrace(error, stack);
  }
}

void translate(void Function() operation) {
  try {
    operation();
  } on Object catch (_, stack) {
    Error.throwWithStackTrace(const RepositoryException(), stack);
  }
}
''');
  }

  Future<void> test_coreThrowWithStackTraceInPresentation_lint() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

final class RepositoryException implements Exception {
  const RepositoryException();
}

final class CounterNotifier extends Notifier<int> {
  void increment() {
    Error.throwWithStackTrace(const RepositoryException(), StackTrace.current);
  }
}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('Error.throwWithStackTrace'),
        'Error.throwWithStackTrace(const RepositoryException(), StackTrace.current)'.length,
      ),
    ]);
  }

  Future<void> test_nonCoreThrowWithStackTrace_noLint() async {
    newFile('$testPackageLibPath/other_errors.dart', r'''
class Error {
  external static void throwWithStackTrace(Object error, StackTrace stackTrace);
}
''');
    await assertNoDiagnostics(r'''
import 'other_errors.dart' as other;

void report() => other.Error.throwWithStackTrace('invalid', StackTrace.current);
''');
  }

  Future<void> test_rethrow_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('work');
  } catch (_) {
    rethrow;
  }
}
''');
  }

  Future<void> test_generatedLocalizationThrow_noLint() async {
    final filePath = '$testPackageLibPath/l10n/app_localizations.dart';
    newFile(filePath, "Never lookup() => throw 'missing';");

    await assertNoDiagnosticsInFile(filePath);
  }
}
