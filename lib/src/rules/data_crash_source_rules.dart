import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> dataCrashSourceRules = [
  /// Avoid log-and-rethrow in data layers.
  ///
  /// Why: A catch that only reports the error and rethrows adds nothing: the
  /// notifier catches and reports it again. Delete the try/catch, or translate,
  /// recover, roll back, or swallow + log a local-first remote mirror instead.
  scannerRule(
    code: const LintCode(
      'data_log_rethrow',
      'Avoid log-and-rethrow in data layers.',
      correctionMessage: 'Delete the try/catch and let the notifier catch and report once, or translate the error to a typed domain error.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags data-layer catch clauses that only log or report the caught error before rethrowing.',
    scan: (reporter, context) {
      if (!context.isDataPath) return;
      final finder = _LogRethrowFinder();
      context.unit.accept(finder);
      for (final statement in finder.statements) {
        final location = context.unit.lineInfo.getLocation(statement.offset);
        reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
      }
    },
  ),

  /// Crash reporting may include PII.
  ///
  /// Why: Flags possible PII values sent to crash reporting. Do not send email, name, phone,
  /// token, password, address, or user IDs.
  scannerRule(
    code: const LintCode(
      'crash_possible_pii',
      'Crash reporting may include PII.',
      correctionMessage: 'Do not send email, name, phone, token, password, address, or user IDs.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Flags possible PII values sent to crash reporting so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\b(?:Crash\.|FirebaseCrashlytics)').hasMatch(line) &&
            RegExp(
              r'\b(?:email|name|phone|token|password|ssn|address|userId)\b',
              caseSensitive: false,
            ).hasMatch(line)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),
];

/// Catch clauses whose body is only reporting calls followed by `rethrow`.
final class _LogRethrowFinder extends RecursiveAstVisitor<void> {
  final statements = <Statement>[];

  @override
  void visitCatchClause(CatchClause node) {
    final body = node.body.statements;
    if (body.length > 1 &&
        _isRethrow(body.last) &&
        body.take(body.length - 1).every((statement) => _isReportingCall(statement, node))) {
      statements.add(body.first);
    }
    super.visitCatchClause(node);
  }
}

bool _isRethrow(Statement statement) =>
    statement is ExpressionStatement && statement.expression is RethrowExpression;

bool _isReportingCall(Statement statement, CatchClause clause) {
  if (statement is! ExpressionStatement) return false;
  final expression = statement.expression;
  final call = expression is AwaitExpression ? expression.expression : expression;
  final callee = switch (call) {
    MethodInvocation(:final methodName) => methodName.element,
    // Function-typed variables such as Flutter's debugPrint resolve here.
    FunctionExpressionInvocation(:final function) =>
      function is Identifier ? function.element : null,
    _ => null,
  };
  if (call is! InvocationExpression) return false;
  return _isLogFunction(callee) || _receivesCaughtError(call, clause);
}

bool _isLogFunction(Element? element) {
  if (element == null || element.enclosingElement is! LibraryElement) return false;
  final library = element.library?.uri.toString() ?? '';
  return switch (element.name) {
    'print' => library == 'dart:core',
    'log' => library == 'dart:developer',
    'debugPrint' => library.startsWith('package:flutter/'),
    _ => false,
  };
}

/// Passing the caught error or stack trace on makes the call a report.
bool _receivesCaughtError(InvocationExpression call, CatchClause clause) {
  final caught = {
    clause.exceptionParameter?.declaredFragment?.element,
    clause.stackTraceParameter?.declaredFragment?.element,
  }..remove(null);
  if (caught.isEmpty) return false;
  final finder = _ElementReferenceFinder(caught);
  call.argumentList.accept(finder);
  return finder.found;
}

final class _ElementReferenceFinder extends RecursiveAstVisitor<void> {
  _ElementReferenceFinder(this.elements);

  final Set<Element?> elements;
  bool found = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (elements.contains(node.element)) found = true;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
