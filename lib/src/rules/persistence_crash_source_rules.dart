import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> persistenceCrashSourceRules = [
  /// Hive generated adapters should reserve @HiveType ids.
  ///
  /// Why: Flags @GenerateAdapters without reservedTypeIds when @HiveType exists. Add
  /// reservedTypeIds when @HiveType classes share a file with adapters.
  scannerRule(
    code: const LintCode(
      'hive_reserved_type_ids_missing',
      'Hive generated adapters should reserve @HiveType ids.',
      correctionMessage: 'Add reservedTypeIds when @HiveType classes share a file with adapters.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags @GenerateAdapters without reservedTypeIds when @HiveType exists so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (_annotationSpans(context, 'HiveType').isEmpty) return;
      final adapterSpans = _annotationSpans(context, 'GenerateAdapters');
      for (final span in adapterSpans) {
        if (!RegExp(r'\breservedTypeIds\s*:').hasMatch(span.text)) {
          reporter.report(context, span.start, 0);
        }
      }
    },
  ),

  /// Hive tests should close boxes.
  ///
  /// Why: Flags test files that use Hive without Hive.close(). Call Hive.close() from
  /// tearDown or cleanup.
  scannerRule(
    code: const LintCode(
      'hive_test_close_missing',
      'Hive tests should close boxes.',
      correctionMessage: 'Call Hive.close() from tearDown or cleanup.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags test files that use Hive without Hive.close() so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.isTestFile) return;
      final hiveUseLine = _firstLineMatching(context, RegExp(r'\bHive\s*\.'));
      if (hiveUseLine == null) return;
      if (_containsMatch(context, RegExp(r'\bHive\s*\.\s*close\s*\('))) return;
      reporter.report(context, hiveUseLine, context.source.masked[hiveUseLine].indexOf('Hive'));
    },
  ),

  /// Hive typeId values must be unique in a file.
  ///
  /// Why: Flags duplicate Hive typeId values in the same file. Assign a fresh permanent
  /// typeId and retire the old id.
  scannerRule(
    code: const LintCode(
      'hive_duplicate_type_id',
      'Hive typeId values must be unique in a file.',
      correctionMessage: 'Assign a fresh permanent typeId and retire the old id.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags duplicate Hive typeId values in the same file so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      _reportDuplicateAnnotationIds(
        reporter: reporter,
        context: context,
        annotationName: 'HiveType',
        idPattern: RegExp(r'\btypeId\s*:\s*(\d+)\b'),
      );
    },
  ),

  /// HiveField indices must be unique in a file.
  ///
  /// Why: Flags duplicate HiveField indices in the same file. Append with a new HiveField
  /// index; never reuse a retired index.
  scannerRule(
    code: const LintCode(
      'hive_duplicate_field_id',
      'HiveField indices must be unique in a file.',
      correctionMessage: 'Append with a new HiveField index; never reuse a retired index.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags duplicate HiveField indices in the same file so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      _reportDuplicateAnnotationIds(
        reporter: reporter,
        context: context,
        annotationName: 'HiveField',
        idPattern: RegExp(r'@HiveField\s*\(\s*(\d+)\b'),
      );
    },
  ),

  /// Avoid direct FirebaseCrashlytics calls outside crash_service.dart.
  ///
  /// Why: Flags FirebaseCrashlytics.instance usage outside the Crash facade. Route feature
  /// code through Crash.init/error/log.
  scannerRule(
    code: const LintCode(
      'crash_direct_firebase_call',
      'Avoid direct FirebaseCrashlytics calls outside crash_service.dart.',
      correctionMessage: 'Route feature code through Crash.init/error/log.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags FirebaseCrashlytics.instance usage outside crash_service.dart so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (_isCrashServiceContext(context)) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final column = line.indexOf('FirebaseCrashlytics.instance');
        if (column >= 0) {
          reporter.report(context, i, column);
        }
      }
    },
  ),

  /// Initialize Crash before runApp.
  ///
  /// Why: Flags main entrypoints that call runApp before Crash.init(). Call and await
  /// Crash.init() before runApp in the app entrypoint.
  scannerRule(
    code: const LintCode(
      'crash_init_before_run_app',
      'Initialize Crash before runApp.',
      correctionMessage: 'Call and await Crash.init() before runApp in the app entrypoint.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags main entrypoints that call runApp before Crash.init() so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!_isMainEntrypoint(context)) return;
      final runApp = _firstRunAppInvocation(context);
      if (runApp == null) return;
      if (!_awaitsResolvedCrashInitializer(context, runApp.offset)) {
        reporter.report(context, runApp.line, runApp.column);
      }
    },
  ),

  /// Fire-and-forget futures need local error handling.
  ///
  /// Why: Flags feasible unawaited fire-and-forget calls without catch handling. Catch inside
  /// the fire-and-forget future or attach catchError.
  scannerRule(
    code: const LintCode(
      'fire_and_forget_missing_catch',
      'Fire-and-forget futures need local error handling.',
      correctionMessage: 'Catch inside the fire-and-forget future or attach catchError.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Flags feasible unawaited fire-and-forget calls without catch handling so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final column = line.indexOf('unawaited(');
        if (column < 0) continue;
        final statement = _statementFrom(context, i);
        if (!_isFeasibleFireAndForgetRisk(statement)) continue;
        if (_hasCatchGuard(statement) || _usesKnownGuardedFireAndForgetHelper(statement)) continue;
        reporter.report(context, i, column);
      }
    },
  ),
];

bool _awaitsResolvedCrashInitializer(SourceScannerContext context, int runAppOffset) {
  for (final main in context.unit.declarations.whereType<FunctionDeclaration>()) {
    if (main.name.lexeme != 'main' || main.functionExpression.body is! BlockFunctionBody) {
      continue;
    }
    final body = main.functionExpression.body as BlockFunctionBody;
    if (body.block.statements
        .where((statement) => statement.offset < runAppOffset)
        .any(_statementAwaitsCrashInitializer)) {
      return true;
    }
  }
  return _awaitsTopLevelCrashAppRunner(context, runAppOffset);
}

bool _awaitsTopLevelCrashAppRunner(SourceScannerContext context, int runAppOffset) {
  final runAppInvocations = _RunAppInvocationVisitor();
  context.unit.accept(runAppInvocations);
  if (runAppInvocations.count != 1) return false;
  final functions = context.unit.declarations.whereType<FunctionDeclaration>().toList();
  final main = functions.where((function) => function.name.lexeme == 'main').firstOrNull;
  final runner = functions
      .where(
        (function) =>
            function.name.lexeme != 'main' &&
            function.offset <= runAppOffset &&
            runAppOffset < function.end,
      )
      .firstOrNull;
  if (main == null || runner == null || !_hasAwaitedCrashAppRunner(runner, runAppOffset)) {
    return false;
  }

  final byElement = <Element, FunctionDeclaration>{};
  for (final function in functions) {
    final element = function.declaredFragment?.element;
    if (element != null) byElement[element] = function;
  }
  return _reachesStartupRunner(main, runner, byElement, <Element>{});
}

bool _hasAwaitedCrashAppRunner(FunctionDeclaration runner, int runAppOffset) {
  final body = runner.functionExpression.body;
  if (body is! BlockFunctionBody) return false;
  for (final statement in body.block.statements) {
    if (_mayExitBeforeInitializer(statement)) return false;
    final initializer = _awaitedCrashInit(statement);
    if (initializer != null && _appRunnerContainsRunApp(initializer, runAppOffset)) return true;
  }
  return false;
}

MethodInvocation? _awaitedCrashInit(Statement statement) {
  if (statement is! ExpressionStatement || statement.expression is! AwaitExpression) return null;
  final awaited = (statement.expression as AwaitExpression).expression;
  return awaited is MethodInvocation && _isResolvedCrashInitCall(awaited) ? awaited : null;
}

bool _appRunnerContainsRunApp(MethodInvocation initializer, int runAppOffset) {
  final method = initializer.methodName.element;
  return initializer.argumentList.arguments.whereType<NamedArgument>().any((argument) {
    final callback = argument.argumentExpression;
    final parameter = argument.correspondingParameter;
    return parameter?.name == 'appRunner' &&
        parameter?.enclosingElement == method &&
        callback is FunctionExpression &&
        callback.offset <= runAppOffset &&
        runAppOffset < callback.end;
  });
}

bool _reachesStartupRunner(
  FunctionDeclaration current,
  FunctionDeclaration runner,
  Map<Element, FunctionDeclaration> byElement,
  Set<Element> visited,
) {
  if (identical(current, runner)) return true;
  final currentElement = current.declaredFragment?.element;
  if (currentElement == null || !visited.add(currentElement)) return false;
  final calls = _startupForwardedCalls(current);
  if (calls == null) return false;
  for (final call in calls) {
    final target = byElement[call.methodName.element];
    if (target != null && _reachesStartupRunner(target, runner, byElement, visited)) {
      return true;
    }
  }
  return false;
}

List<MethodInvocation>? _startupForwardedCalls(FunctionDeclaration current) {
  final body = current.functionExpression.body;
  if (body is ExpressionFunctionBody) {
    final call = _forwardedCall(body.expression, current);
    return call == null ? [] : [call];
  }
  if (body is! BlockFunctionBody) return [];
  final calls = <MethodInvocation>[];
  for (final statement in body.block.statements) {
    if (_blocksStartupPath(statement)) return null;
    final call = _awaitedOrReturnedCall(statement, current);
    if (call != null) calls.add(call);
    if (statement is ReturnStatement) break;
  }
  return calls;
}

bool _blocksStartupPath(Statement statement) =>
    (statement is! ReturnStatement && _mayExitBeforeInitializer(statement)) ||
    _containsRunApp(statement);

bool _abruptlyExits(Statement statement) =>
    statement is ReturnStatement ||
    (statement is ExpressionStatement && statement.expression is ThrowExpression);

bool _mayExitBeforeInitializer(Statement statement) {
  if (_abruptlyExits(statement)) return true;
  final visitor = _EarlyExitVisitor();
  statement.accept(visitor);
  return visitor.found;
}

final class _EarlyExitVisitor extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitReturnStatement(ReturnStatement node) {
    found = true;
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    found = true;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {}
}

MethodInvocation? _awaitedOrReturnedCall(Statement statement, FunctionDeclaration owner) {
  if (statement is ExpressionStatement && statement.expression is AwaitExpression) {
    final awaited = (statement.expression as AwaitExpression).expression;
    return awaited is MethodInvocation ? awaited : null;
  }
  if (statement case ReturnStatement(expression: final expression?)) {
    return _forwardedCall(expression, owner);
  }
  return null;
}

MethodInvocation? _forwardedCall(Expression expression, FunctionDeclaration owner) {
  if (expression is AwaitExpression) {
    return expression.expression is MethodInvocation
        ? expression.expression as MethodInvocation
        : null;
  }
  final returnType = owner.returnType?.type;
  if (returnType is! InterfaceType ||
      returnType.element.name != 'Future' ||
      returnType.element.library.identifier != 'dart:async') {
    return null;
  }
  return expression is MethodInvocation ? expression : null;
}

bool _containsRunApp(AstNode node) {
  final visitor = _RunAppInvocationVisitor();
  node.accept(visitor);
  return visitor.found;
}

final class _RunAppInvocationVisitor extends RecursiveAstVisitor<void> {
  int? firstOffset;
  int count = 0;

  bool get found => firstOffset != null;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final previous = firstOffset;
    if (node.methodName.name == 'runApp' &&
        (previous == null || node.methodName.offset < previous)) {
      firstOffset = node.methodName.offset;
    }
    if (node.methodName.name == 'runApp') count++;
    super.visitMethodInvocation(node);
  }
}

bool _statementAwaitsCrashInitializer(Statement statement) {
  if (statement is! ExpressionStatement || statement.expression is! AwaitExpression) return false;
  final awaited = (statement.expression as AwaitExpression).expression;
  if (awaited is! MethodInvocation) return false;
  return _isResolvedCrashInitCall(awaited) ||
      _resolvedMethodCallsCrashInit(awaited.methodName.element);
}

bool _isResolvedCrashInitCall(MethodInvocation call) {
  final method = call.methodName.element;
  return method is MethodElement &&
      method.name == 'init' &&
      method.isStatic &&
      method.enclosingElement is ClassElement &&
      (method.enclosingElement as ClassElement).name == 'Crash';
}

bool _resolvedMethodCallsCrashInit(Element? element) {
  if (element is! MethodElement) return false;
  final declaration = _methodDeclarationFor(element);
  if (declaration == null) return false;
  final shadows = _CrashShadowVisitor();
  declaration.accept(shadows);
  if (shadows.hasShadow) return false;
  final initializer = _directCrashInitializer(declaration.body);
  if (initializer == null) return false;
  final crashClass = element.firstFragment.libraryFragment.scope.lookup('Crash').getter;
  return crashClass is ClassElement &&
      crashClass.name == 'Crash' &&
      crashClass.methods.any((method) => method.name == 'init' && method.isStatic);
}

MethodDeclaration? _methodDeclarationFor(MethodElement element) {
  final fragment = element.firstFragment;
  final offset = fragment.nameOffset;
  if (offset == null) return null;
  final source = fragment.libraryFragment.source;
  final unit = parseString(content: source.contents.data, throwIfDiagnostics: false).unit;
  AstNode? declaration = unit.nodeCovering(offset: offset);
  while (declaration != null && declaration is! MethodDeclaration) {
    declaration = declaration.parent;
  }
  return declaration is MethodDeclaration ? declaration : null;
}

MethodInvocation? _directCrashInitializer(FunctionBody methodBody) {
  final expression = switch (methodBody) {
    ExpressionFunctionBody(:final expression) => expression,
    BlockFunctionBody(:final block) when block.statements.length == 1 =>
      switch (block.statements.single) {
        ReturnStatement(:final expression?) => expression,
        ExpressionStatement(:final expression) when expression is AwaitExpression => expression,
        _ => null,
      },
    _ => null,
  };
  final initializer = expression is AwaitExpression ? expression.expression : expression;
  if (initializer is! MethodInvocation ||
      initializer.target is! SimpleIdentifier ||
      (initializer.target! as SimpleIdentifier).name != 'Crash' ||
      initializer.methodName.name != 'init') {
    return null;
  }
  return initializer;
}

final class _CrashShadowVisitor extends RecursiveAstVisitor<void> {
  bool hasShadow = false;

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    if (node.name?.lexeme == 'Crash') hasShadow = true;
    super.visitRegularFormalParameter(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme == 'Crash') hasShadow = true;
    super.visitVariableDeclaration(node);
  }
}

void _reportDuplicateAnnotationIds({
  required ScannerRuleReporter reporter,
  required SourceScannerContext context,
  required String annotationName,
  required RegExp idPattern,
}) {
  final seen = <String, int>{};
  for (final span in _annotationSpans(context, annotationName)) {
    final match = idPattern.firstMatch(span.text);
    final id = match?.group(1);
    if (id == null) continue;
    if (seen.containsKey(id)) {
      reporter.report(context, span.start, span.column);
      continue;
    }
    seen[id] = span.start;
  }
}

List<_AnnotationSpan> _annotationSpans(SourceScannerContext context, String name) {
  final spans = <_AnnotationSpan>[];
  final startsAnnotation = RegExp('@$name\\b');
  for (var i = 0; i < context.source.length; i++) {
    final line = context.source.masked[i];
    final match = startsAnnotation.firstMatch(line);
    if (match == null) continue;

    final buffer = StringBuffer(line);
    var end = i;
    var depth = _parenDelta(line);
    final hasArguments = line.contains('(');
    while (hasArguments && depth > 0 && end + 1 < context.source.length) {
      end++;
      final nextLine = context.source.masked[end];
      buffer
        ..write('\n')
        ..write(nextLine);
      depth += _parenDelta(nextLine);
    }

    spans.add(_AnnotationSpan(i, match.start, buffer.toString()));
    i = end;
  }
  return spans;
}

int? _firstLineMatching(SourceScannerContext context, RegExp pattern) {
  for (var i = 0; i < context.source.length; i++) {
    if (pattern.hasMatch(context.source.masked[i])) return i;
  }
  return null;
}

bool _containsMatch(SourceScannerContext context, RegExp pattern) {
  for (final line in context.source.masked) {
    if (pattern.hasMatch(line)) return true;
  }
  return false;
}

bool _isCrashServiceContext(SourceScannerContext context) {
  final normalized = context.path.replaceAll('\\', '/').toLowerCase();
  return normalized.endsWith('/crash_service.dart');
}

bool _isMainEntrypoint(SourceScannerContext context) {
  final normalized = context.path.replaceAll('\\', '/').toLowerCase();
  return normalized == 'lib/main.dart' ||
      (normalized.startsWith('lib/main_') && normalized.endsWith('.dart'));
}

({int line, int column, int offset})? _firstRunAppInvocation(SourceScannerContext context) {
  final visitor = _RunAppInvocationVisitor();
  context.unit.accept(visitor);
  final offset = visitor.firstOffset;
  if (offset == null) return null;
  final line = context.source.lineOffsets.lastIndexWhere((start) => start <= offset);
  return (line: line, column: offset - context.source.lineOffsets[line], offset: offset);
}

String _statementFrom(SourceScannerContext context, int startLine) {
  final buffer = StringBuffer();
  var depth = 0;
  for (var i = startLine; i < context.source.length; i++) {
    final line = context.source.masked[i];
    if (buffer.isNotEmpty) buffer.write('\n');
    buffer.write(line);
    depth += _parenDelta(line);
    if (line.contains(';') && depth <= 0) break;
  }
  return buffer.toString();
}

bool _isFeasibleFireAndForgetRisk(String statement) {
  if (statement.contains('() async')) return true;
  return RegExp(
    r'\b(?:Firebase|Crashlytics|analytics|remote|sync|logEvent|recordError|setUserIdentifier|setCustomKey)\b',
    caseSensitive: false,
  ).hasMatch(statement);
}

bool _hasCatchGuard(String statement) {
  if (statement.contains('.catchError(')) return true;
  if (!RegExp(r'\btry\s*\{').hasMatch(statement)) return false;
  return RegExp(r'\b(?:catch|on\s+[A-Za-z_][A-Za-z0-9_]*)\b').hasMatch(statement);
}

bool _usesKnownGuardedFireAndForgetHelper(String statement) {
  return RegExp(r'\bunawaited\s*\(\s*_(?:send|runCrashOperation)\s*\(').hasMatch(statement);
}

int _parenDelta(String line) => countCharacter(line, '(') - countCharacter(line, ')');

final class _AnnotationSpan {
  const _AnnotationSpan(this.start, this.column, this.text);

  final int start;
  final int column;
  final String text;
}
