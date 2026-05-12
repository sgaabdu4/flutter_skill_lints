import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Rewrites `runZonedGuarded(() { ... runApp(X); }, (e, s) { reporter(e, s); })`
/// into the canonical three-hook scaffold:
///
/// ```
/// FlutterError.onError = (details) {
///   FlutterError.presentError(details);
///   reporter(details.exception, details.stack);
/// };
/// PlatformDispatcher.instance.onError = (error, stack) {
///   reporter(error, stack);
///   return true;
/// };
/// Isolate.current.addErrorListener(RawReceivePort((pair) {
///   final list = pair as List;
///   reporter(list.first as Object, StackTrace.fromString(list.last as String));
/// }).sendPort);
/// runApp(X);
/// ```
///
/// The reporter call defaults to the identifier used in the original `onError` argument
/// body (e.g. `Crash.report`, `myReporter.send`). If no call is detectable, `print` is
/// used as a TODO placeholder.
class AvoidRunZonedGuardedFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.avoidRunZonedGuarded',
    DartFixKindPriority.standard,
    'Replace runZonedGuarded with three-hook crash wiring',
  );

  AvoidRunZonedGuardedFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final invocation = node.thisOrAncestorOfType<MethodInvocation>();
    if (invocation == null) return;
    if (invocation.methodName.name != 'runZonedGuarded') return;

    final statement = invocation.thisOrAncestorOfType<ExpressionStatement>();
    if (statement == null) return;

    final args = invocation.argumentList.arguments;
    if (args.length < 2) return;

    final bodyArg = args[0];
    final onErrorArg = args[1];

    final innerBodySource = _extractFunctionBody(bodyArg);
    if (innerBodySource == null) return;

    final reporter = _extractReporterCall(onErrorArg) ?? 'print';
    final indent = _leadingIndent(statement);

    final scaffold = _scaffold(reporter: reporter, indent: indent, innerBody: innerBodySource);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(statement), scaffold);
    });
  }

  String? _extractFunctionBody(Expression expression) {
    if (expression is! FunctionExpression) return null;
    final body = expression.body;
    if (body is! BlockFunctionBody) return null;
    final statements = body.block.statements;
    return statements.map((s) => s.toSource()).join('\n');
  }

  String? _extractReporterCall(Expression expression) {
    if (expression is! FunctionExpression) return null;
    final body = expression.body;
    if (body is! BlockFunctionBody) return null;
    for (final statement in body.block.statements) {
      if (statement is ExpressionStatement) {
        final expr = statement.expression;
        if (expr is MethodInvocation) {
          final target = expr.target;
          if (target == null) {
            return expr.methodName.name;
          }
          return '${target.toSource()}.${expr.methodName.name}';
        }
      }
    }
    return null;
  }

  String _leadingIndent(ExpressionStatement statement) {
    final offset = statement.offset;
    final source = unit.lineInfo;
    final location = source.getLocation(offset);
    return ' ' * (location.columnNumber - 1);
  }

  String _scaffold({required String reporter, required String indent, required String innerBody}) {
    final indentedBody = innerBody
        .split('\n')
        .map((line) => line.isEmpty ? line : '$indent$line')
        .join('\n');
    return '''
${indent}FlutterError.onError = (details) {
$indent  FlutterError.presentError(details);
$indent  $reporter(details.exception, details.stack);
$indent};
${indent}PlatformDispatcher.instance.onError = (error, stack) {
$indent  $reporter(error, stack);
$indent  return true;
$indent};
${indent}Isolate.current.addErrorListener(RawReceivePort((pair) {
$indent  final list = pair as List;
$indent  $reporter(list.first as Object, StackTrace.fromString(list.last as String));
$indent}).sendPort);
$indentedBody'''
        .trimLeft();
  }
}
