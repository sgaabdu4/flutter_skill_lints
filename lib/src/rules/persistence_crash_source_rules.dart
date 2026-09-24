import 'dart:math' as math;

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> persistenceCrashSourceRules = [
  /// Hive generated adapters must reserve every @HiveType id.
  ///
  /// Why: @GenerateAdapters assigns ids to its specs. A @HiveType class in the same
  /// registration scope keeps its hand-written id, so every such id must appear in
  /// reservedTypeIds or a generated adapter can claim it. The check resolves the
  /// annotations and follows the analyzer's import graph, so it also sees @HiveType
  /// classes that live in another file of the registration scope.
  scannerRule(
    code: const LintCode(
      'hive_reserved_type_ids_missing',
      'Hive generated adapters must reserve every @HiveType typeId.',
      correctionMessage:
          'Add each @HiveType typeId from the same registration scope to reservedTypeIds.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags @GenerateAdapters whose reservedTypeIds omit a @HiveType typeId from the same resolved import graph.',
    scan: _reportUnreservedHiveTypeIds,
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

  /// Hive typeId values must be unique across a registration scope.
  ///
  /// Why: Hive registers one adapter per typeId. Two @HiveType classes that share an
  /// id break registration or read each other's bytes. The check resolves @HiveType
  /// ids in this library and in every library the analyzer's import graph reaches, and
  /// reports where the two ids first meet. Assign a fresh permanent typeId and retire
  /// the old id.
  scannerRule(
    code: const LintCode(
      'hive_duplicate_type_id',
      'Hive typeId values must be unique across registered types.',
      correctionMessage: 'Assign a fresh permanent typeId and retire the old id.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags @HiveType typeIds that collide within the same resolved import graph, including across files.',
    scan: _reportDuplicateHiveTypeIds,
  ),

  /// HiveField indices must be unique within one class.
  ///
  /// Why: HiveField indexes are per @HiveType class. Two fields of the same class with
  /// the same index overwrite each other on disk; separate classes may each use 0, 1.
  /// Append with a new HiveField index; never reuse a retired index.
  scannerRule(
    code: const LintCode(
      'hive_duplicate_field_id',
      'HiveField indices must be unique within a class.',
      correctionMessage: 'Append with a new HiveField index; never reuse a retired index.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags a resolved HiveField index used twice in the same class or enum.',
    scan: _reportDuplicateHiveFieldIds,
  ),

  /// Freezed classes use @GenerateAdapters, not @HiveType.
  ///
  /// Why: hive-persistence.md: "@HiveType for non-Freezed. @GenerateAdapters for
  /// Freezed." Freezed owns the constructor, so its Hive slots come from the
  /// AdapterSpec schema instead of hand-written annotations.
  scannerRule(
    code: const LintCode(
      'hive_type_on_freezed_class',
      'Freezed classes must use @GenerateAdapters, not @HiveType.',
      correctionMessage:
          'Remove @HiveType/@HiveField and add AdapterSpec<Model>() to the @GenerateAdapters list.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags a class annotated with both a resolved Freezed annotation and a hive_ce @HiveType.',
    scan: (reporter, context) {
      for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
        final metadata = declaration.metadata;
        final isFreezed = metadata.any(
          (annotation) =>
              isPackageAnnotation(annotation.elementAnnotation, 'freezed_annotation', 'Freezed'),
        );
        if (!isFreezed) continue;
        for (final annotation in metadata) {
          if (_isHiveAnnotation(annotation.elementAnnotation, 'HiveType')) {
            _reportAtOffset(reporter, context, annotation.offset);
          }
        }
      }
    },
  ),

  /// AdapterSpec names a persistence Model, never a domain type.
  ///
  /// Why: hive-persistence.md: "AdapterSpec<T>() always names a persistence-layer Model
  /// from /data/models/, never a /domain/entities/ class. Domain entities stay
  /// Hive-free." The resolved type argument's declaring library decides the layer.
  scannerRule(
    code: const LintCode(
      'hive_adapter_spec_domain_type',
      'AdapterSpec must name a /data/models/ Model, not a domain type.',
      correctionMessage: 'Point AdapterSpec at the persistence Model and map it to the domain entity in the mapper.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags AdapterSpec<T>() in @GenerateAdapters when the resolved T is declared under /domain/.',
    scan: (reporter, context) {
      for (final annotation in _unitAnnotations(context.unit)) {
        if (!_isHiveAnnotation(annotation.elementAnnotation, 'GenerateAdapters')) continue;
        final specs = annotation.arguments?.arguments.firstOrNull;
        if (specs is! ListLiteral) continue;
        for (final spec in specs.elements.whereType<InstanceCreationExpression>()) {
          final type = spec.staticType;
          if (type is! InterfaceType || type.typeArguments.isEmpty) continue;
          final model = type.typeArguments.first.element;
          final path = model?.library?.firstFragment.source.fullName.replaceAll('\\', '/');
          if (path != null && path.contains('/domain/')) {
            _reportAtOffset(reporter, context, spec.offset);
          }
        }
      }
    },
  ),

  /// Notifiers never touch Hive.
  ///
  /// Why: hive-persistence.md: "Notifier consumes IOrderRepository only — never
  /// touches Hive." Storage calls stay in local datasources behind the repository, so
  /// tests override the repository without Hive setup.
  scannerRule(
    code: const LintCode(
      'notifier_hive_access',
      'Notifiers must not touch Hive.',
      correctionMessage:
          'Move box access into a local datasource and call it through the repository interface.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags references to hive_ce APIs inside classes whose resolved supertypes include a Riverpod Notifier.',
    scan: (reporter, context) {
      for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
        final element = declaration.declaredFragment?.element;
        if (element == null || !element.allSupertypes.any(_isRiverpodNotifierType)) continue;
        final visitor = _HiveReferenceVisitor();
        declaration.body.accept(visitor);
        for (final offset in visitor.offsets) {
          _reportAtOffset(reporter, context, offset);
        }
      }
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
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags feasible unawaited fire-and-forget calls without catch handling so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final visitor = _UnawaitedVisitor();
      context.unit.accept(visitor);
      for (final invocation in visitor.invocations) {
        if (_isFireAndForgetGuarded(context, invocation)) continue;
        reporter.reportOffset(context, invocation.offset);
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
  return normalized.endsWith('/crash_service.dart') ||
      normalized.endsWith('/crash.dart') ||
      normalized.contains('/core/crash/');
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

final class _UnawaitedVisitor extends RecursiveAstVisitor<void> {
  final invocations = <MethodInvocation>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final element = node.methodName.element;
    if (node.target == null &&
        node.methodName.name == 'unawaited' &&
        (element == null || element.library?.isDartAsync == true)) {
      invocations.add(node);
    }
    super.visitMethodInvocation(node);
  }
}

/// Whether the future passed to `unawaited` handles its own errors: a `catchError`/`onError`
/// chain, an inline closure that catches, or a resolved callee whose body catches (or is
/// empty). Callees without an available body (SDK, abstract, external) keep the keyword
/// heuristic.
bool _isFireAndForgetGuarded(SourceScannerContext context, MethodInvocation invocation) {
  final arguments = invocation.argumentList.arguments;
  if (arguments.isEmpty) return true;
  final future = arguments.first.argumentExpression.unParenthesized;
  if (future is MethodInvocation &&
      const {'catchError', 'onError'}.contains(future.methodName.name)) {
    return true;
  }

  final body = switch (future) {
    FunctionExpressionInvocation(:final function)
        when function.unParenthesized is FunctionExpression =>
      (function.unParenthesized as FunctionExpression).body,
    MethodInvocation(:final methodName) => _declaredBody(context, methodName.element),
    FunctionExpressionInvocation(:final element) => _declaredBody(context, element),
    _ => null,
  };
  if (body != null) return _catchesInternally(body);

  final lineIndex = context.source.lineOffsets.lastIndexWhere(
    (start) => start <= invocation.offset,
  );
  final statement = _statementFrom(context, lineIndex);
  return !_isFeasibleFireAndForgetRisk(statement) || _hasCatchGuard(statement);
}

FunctionBody? _declaredBody(SourceScannerContext context, Element? element) {
  if (element is! ExecutableElement) return null;
  final declared = element.baseElement;
  if (declared.isAbstract || declared.isExternal) return null;
  final library = declared.library;
  if (library.isInSdk) return null;

  AstNode? node;
  if (library == context.unit.declaredFragment?.element) {
    final finder = _DeclarationFinder(declared);
    context.unit.accept(finder);
    node = finder.node;
  }
  if (node == null) {
    final parsed = library.session.getParsedLibraryByElement(library);
    if (parsed is! ParsedLibraryResult) return null;
    try {
      node = parsed.getFragmentDeclaration(declared.firstFragment)?.node;
    } on ArgumentError {
      return null;
    }
  }

  final body = switch (node) {
    MethodDeclaration(:final body) => body,
    FunctionDeclaration(:final functionExpression) => functionExpression.body,
    _ => null,
  };
  return body is EmptyFunctionBody ? null : body;
}

bool _catchesInternally(FunctionBody body) {
  if (body is BlockFunctionBody && body.block.statements.isEmpty) return true;
  final visitor = _CatchVisitor();
  body.accept(visitor);
  return visitor.catches;
}

final class _DeclarationFinder extends RecursiveAstVisitor<void> {
  _DeclarationFinder(this.element);

  final ExecutableElement element;
  AstNode? node;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.declaredFragment?.element == element) this.node = node;
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.declaredFragment?.element == element) {
      this.node = node;
      return;
    }
    super.visitFunctionDeclaration(node);
  }
}

final class _CatchVisitor extends RecursiveAstVisitor<void> {
  bool catches = false;

  @override
  void visitTryStatement(TryStatement node) {
    if (node.catchClauses.isNotEmpty) catches = true;
    super.visitTryStatement(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (const {'catchError', 'onError'}.contains(node.methodName.name)) catches = true;
    super.visitMethodInvocation(node);
  }
}

int _parenDelta(String line) => countCharacter(line, '(') - countCharacter(line, ')');

void _reportAtOffset(ScannerRuleReporter reporter, SourceScannerContext context, int offset) {
  final location = context.unit.lineInfo.getLocation(offset);
  reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
}

bool _isHiveAnnotation(ElementAnnotation? annotation, String className) =>
    isPackageAnnotation(annotation, 'hive_ce', className);

bool _isRiverpodNotifierType(InterfaceType type) {
  final uri = type.element.library.uri;
  final isRiverpod =
      uri.scheme == 'package' &&
      uri.pathSegments.isNotEmpty &&
      const {'riverpod', 'flutter_riverpod', 'hooks_riverpod'}.contains(uri.pathSegments.first);
  return isRiverpod && (type.element.name ?? '').contains('Notifier');
}

final class _HiveReferenceVisitor extends RecursiveAstVisitor<void> {
  final offsets = <int>[];

  @override
  void visitNamedType(NamedType node) {
    if (_isHiveLibrary(node.element?.library)) offsets.add(node.offset);
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final parent = node.parent;
    final isMember =
        (parent is MethodInvocation && parent.methodName == node && parent.target != null) ||
        (parent is PropertyAccess && parent.propertyName == node) ||
        (parent is PrefixedIdentifier && parent.identifier == node);
    if (!isMember && _isHiveLibrary(node.element?.library)) offsets.add(node.offset);
    super.visitSimpleIdentifier(node);
  }
}

bool _isHiveLibrary(LibraryElement? library) {
  final uri = library?.uri;
  return uri != null &&
      uri.scheme == 'package' &&
      uri.pathSegments.isNotEmpty &&
      const {'hive_ce', 'hive_ce_flutter'}.contains(uri.pathSegments.first);
}

Iterable<Annotation> _unitAnnotations(CompilationUnit unit) sync* {
  for (final declaration in unit.declarations) {
    yield* declaration.metadata;
  }
}

void _reportDuplicateHiveFieldIds(ScannerRuleReporter reporter, SourceScannerContext context) {
  for (final declaration in context.unit.declarations) {
    final memberMetadata = switch (declaration) {
      ClassDeclaration(body: BlockClassBody(:final members)) => [
        for (final member in members) member.metadata,
      ],
      EnumDeclaration(:final body) => [
        for (final constant in body.constants) constant.metadata,
        for (final member in body.members) member.metadata,
      ],
      _ => const <NodeList<Annotation>>[],
    };
    final seen = <int>{};
    for (final annotation in memberMetadata.expand((metadata) => metadata)) {
      if (!_isHiveAnnotation(annotation.elementAnnotation, 'HiveField')) continue;
      final index = annotation.elementAnnotation
          ?.computeConstantValue()
          ?.getField('index')
          ?.toIntValue();
      if (index != null && !seen.add(index)) _reportAtOffset(reporter, context, annotation.offset);
    }
  }
}

/// A resolved `@HiveType(typeId: n)` declaration.
final class _HiveTypeFact {
  const _HiveTypeFact(this.element, this.typeId);

  final Element element;
  final int typeId;
}

/// A resolved `@GenerateAdapters(..., reservedTypeIds: {...})` declaration.
final class _HiveAdapterFact {
  const _HiveAdapterFact(this.element, this.reservedTypeIds);

  final Element element;
  final Set<int> reservedTypeIds;
}

final class _HiveFacts {
  final types = <_HiveTypeFact>[];
  final adapters = <_HiveAdapterFact>[];

  void addAll(_HiveFacts other) {
    types.addAll(other.types);
    adapters.addAll(other.adapters);
  }

  bool containsAll(Iterable<Element> elements) {
    final declared = {
      for (final fact in types) fact.element,
      for (final fact in adapters) fact.element,
    };
    return elements.every(declared.contains);
  }
}

/// The Hive facts reachable through one import or export directive of the unit.
final class _HiveImportScope {
  const _HiveImportScope(this.directive, this.facts);

  final NamespaceDirective directive;
  final _HiveFacts facts;
}

final _localHiveFactsCache = Expando<_HiveFacts>('flutter_skill_lints_local_hive_facts');
final _reachableHiveFactsCache = Expando<_HiveFacts>('flutter_skill_lints_reachable_hive_facts');

/// The `typeId` of a resolved hive_ce `@HiveType`, or null for any other annotation.
int? _hiveTypeId(ElementAnnotation? annotation) => _isHiveAnnotation(annotation, 'HiveType')
    ? annotation?.computeConstantValue()?.getField('typeId')?.toIntValue()
    : null;

/// The `reservedTypeIds` of a resolved hive_ce `@GenerateAdapters`, or null for any
/// other annotation.
Set<int>? _reservedTypeIds(ElementAnnotation? annotation) {
  if (!_isHiveAnnotation(annotation, 'GenerateAdapters')) return null;
  final reserved = annotation?.computeConstantValue()?.getField('reservedTypeIds')?.toSetValue();
  return reserved?.map((value) => value.toIntValue()).whereType<int>().toSet();
}

_HiveFacts _localHiveFacts(LibraryElement library) {
  final cached = _localHiveFactsCache[library];
  if (cached != null) return cached;
  final facts = _HiveFacts();
  for (final element in library.children) {
    for (final annotation in element.metadata.annotations) {
      final typeId = _hiveTypeId(annotation);
      if (typeId != null) facts.types.add(_HiveTypeFact(element, typeId));
      final reserved = _reservedTypeIds(annotation);
      if (reserved != null) facts.adapters.add(_HiveAdapterFact(element, reserved));
    }
  }
  _localHiveFactsCache[library] = facts;
  return facts;
}

/// Walks same-package libraries depth-first from [roots], visiting each once.
/// [visit] returns whether to continue into the library's imports and exports.
void _walkPackageLibraries(
  Iterable<LibraryElement> roots,
  String packageRoot,
  bool Function(LibraryElement library) visit,
) {
  final pending = [...roots];
  final seen = <LibraryElement>{};
  while (pending.isNotEmpty) {
    final library = pending.removeLast();
    if (!seen.add(library) || !_isPackageLibrary(library, packageRoot)) continue;
    if (visit(library)) pending.addAll(_libraryDependencies(library));
  }
}

/// Facts declared in [root] and every same-package library its imports reach.
_HiveFacts _reachableHiveFacts(LibraryElement root, String packageRoot) {
  final cached = _reachableHiveFactsCache[root];
  if (cached != null) return cached;
  final facts = _HiveFacts();
  _walkPackageLibraries([root], packageRoot, (library) {
    facts.addAll(_localHiveFacts(library));
    return true;
  });
  _reachableHiveFactsCache[root] = facts;
  return facts;
}

List<LibraryElement> _libraryDependencies(LibraryElement library) => [
  for (final fragment in library.fragments) ...fragment.importedLibraries,
  ...library.exportedLibraries,
];

bool _isPackageLibrary(LibraryElement library, String packageRoot) =>
    library.firstFragment.source.fullName.replaceAll('\\', '/').startsWith(packageRoot);

String _packageRoot(SourceScannerContext context) {
  final path = context.unit.declaredFragment?.source.fullName.replaceAll('\\', '/') ?? '';
  return path.endsWith(context.path) ? path.substring(0, path.length - context.path.length) : path;
}

/// Import scopes of the defining unit. A generated library (for example the Hive
/// registrar) is not analyzed, so its own imports stand in for it.
List<_HiveImportScope> _hiveImportScopes(CompilationUnit unit, String packageRoot) {
  final scopes = <_HiveImportScope>[];
  for (final directive in unit.directives.whereType<NamespaceDirective>()) {
    final imported = switch (directive) {
      ImportDirective() => directive.libraryImport?.importedLibrary,
      ExportDirective() => directive.libraryExport?.exportedLibrary,
    };
    if (imported == null) continue;
    _walkPackageLibraries([imported], packageRoot, (library) {
      if (isGeneratedSourcePath(library.firstFragment.source.fullName)) return true;
      scopes.add(_HiveImportScope(directive, _reachableHiveFacts(library, packageRoot)));
      return false;
    });
  }
  return scopes;
}

/// A Hive fact seen through the import scope at [scope].
typedef _ScopedHiveFact = ({Object fact, Element element, int scope});

Element _hiveFactElement(Object fact) => switch (fact) {
  _HiveTypeFact(:final element) || _HiveAdapterFact(:final element) => element,
  _ => throw ArgumentError.value(fact, 'fact'),
};

/// Facts reachable through [scopes] that are not declared in [localElements].
List<_ScopedHiveFact> _nonLocalHiveFacts(
  List<_HiveImportScope> scopes,
  Set<Element> localElements,
) => [
  for (var index = 0; index < scopes.length; index++)
    for (final fact in [...scopes[index].facts.types, ...scopes[index].facts.adapters])
      if (!localElements.contains(_hiveFactElement(fact)))
        (fact: fact, element: _hiveFactElement(fact), scope: index),
];

/// Whether [first] and [second] conflict and no single scope already contains both.
bool _meetsFirstInUnit(
  List<_HiveImportScope> scopes,
  _ScopedHiveFact first,
  _ScopedHiveFact second,
  bool Function(Object first, Object second) conflicts,
) =>
    first.element != second.element &&
    conflicts(first.fact, second.fact) &&
    !scopes.any((scope) => scope.facts.containsAll([first.element, second.element]));

/// Directives where two non-local facts first meet: no single import scope already
/// contains both, so no deeper analyzed library reports the pair.
Set<NamespaceDirective> _joinDirectives(
  List<_HiveImportScope> scopes,
  Set<Element> localElements,
  bool Function(Object first, Object second) conflicts,
) {
  final facts = _nonLocalHiveFacts(scopes, localElements);
  return {
    for (var i = 0; i < facts.length; i++)
      for (var j = i + 1; j < facts.length; j++)
        if (_meetsFirstInUnit(scopes, facts[i], facts[j], conflicts))
          scopes[math.max(facts[i].scope, facts[j].scope)].directive,
  };
}

bool _isDefiningUnit(SourceScannerContext context, LibraryElement library) =>
    context.unit.declaredFragment == library.firstFragment;

void _reportDuplicateHiveTypeIds(ScannerRuleReporter reporter, SourceScannerContext context) {
  final library = context.unit.declaredFragment?.element;
  if (library == null) return;
  final packageRoot = _packageRoot(context);
  final reachable = _reachableHiveFacts(library, packageRoot);
  final seenInUnit = <int, Element>{};
  for (final declaration in context.unit.declarations) {
    final element = declaration.declaredFragment?.element;
    if (element == null) continue;
    for (final annotation in declaration.metadata) {
      final typeId = _hiveTypeId(annotation.elementAnnotation);
      if (typeId == null) continue;
      final earlier = seenInUnit.putIfAbsent(typeId, () => element);
      if (earlier != element || _collidesOutsideUnit(context, reachable, typeId, element)) {
        _reportAtOffset(reporter, context, annotation.offset);
      }
    }
  }
  if (_isDefiningUnit(context, library)) {
    _reportDuplicateHiveTypeIdJoins(reporter, context, library, packageRoot);
  }
}

/// Whether a @HiveType declared outside this unit but reachable from it reuses [typeId].
bool _collidesOutsideUnit(
  SourceScannerContext context,
  _HiveFacts reachable,
  int typeId,
  Element element,
) => reachable.types.any(
  (fact) =>
      fact.typeId == typeId &&
      fact.element != element &&
      fact.element.firstFragment.libraryFragment != context.unit.declaredFragment,
);

void _reportDuplicateHiveTypeIdJoins(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  LibraryElement library,
  String packageRoot,
) {
  final local = _localHiveFacts(library).types.map((fact) => fact.element).toSet();
  final joins = _joinDirectives(
    _hiveImportScopes(context.unit, packageRoot),
    local,
    (first, second) =>
        first is _HiveTypeFact && second is _HiveTypeFact && first.typeId == second.typeId,
  );
  for (final directive in joins) {
    _reportAtOffset(reporter, context, directive.offset);
  }
}

void _reportUnreservedHiveTypeIds(ScannerRuleReporter reporter, SourceScannerContext context) {
  final library = context.unit.declaredFragment?.element;
  if (library == null) return;
  final packageRoot = _packageRoot(context);
  final reachable = _reachableHiveFacts(library, packageRoot);
  for (final annotation in _unitAnnotations(context.unit)) {
    final ids = _reservedTypeIds(annotation.elementAnnotation);
    if (ids == null) continue;
    if (reachable.types.any((fact) => !ids.contains(fact.typeId))) {
      _reportAtOffset(reporter, context, annotation.offset);
    }
  }
  if (!_isDefiningUnit(context, library)) return;
  final localFacts = _localHiveFacts(library);
  final scopes = _hiveImportScopes(context.unit, packageRoot);
  final directives = {
    ..._joinDirectives(scopes, {
      for (final fact in localFacts.types) fact.element,
      for (final fact in localFacts.adapters) fact.element,
    }, _isUnreservedPair),
    // A local @HiveType meets an imported @GenerateAdapters here.
    for (final scope in scopes)
      if (localFacts.types.any(
        (type) => scope.facts.adapters.any((adapter) => _isUnreservedPair(adapter, type)),
      ))
        scope.directive,
  };
  for (final directive in directives) {
    _reportAtOffset(reporter, context, directive.offset);
  }
}

bool _isUnreservedPair(Object first, Object second) => switch ((first, second)) {
  (final _HiveAdapterFact adapter, final _HiveTypeFact type) ||
  (
    final _HiveTypeFact type,
    final _HiveAdapterFact adapter,
  ) => !adapter.reservedTypeIds.contains(type.typeId),
  _ => false,
};
