import 'dart:math' as math;

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

part 'persistence_crash_source_rules/persistence_crash_source_rules_part_01.dart';

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
  /// the fire-and-forget future or attach catchError. A resolved callee whose futures are
  /// all Riverpod `Mutation.run` calls, Flutter/go_router route or modal futures, or
  /// callees that catch internally already captures its failures and is not reported.
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
/// chain, an inline closure or resolved callee whose failures are captured (see
/// [_FailureCapture]). Callees without an available body (SDK, abstract, external) keep the
/// keyword heuristic.
bool _isFireAndForgetGuarded(SourceScannerContext context, MethodInvocation invocation) {
  final arguments = invocation.argumentList.arguments;
  if (arguments.isEmpty) return true;
  final future = arguments.first.argumentExpression.unParenthesized;
  if (future is MethodInvocation &&
      const {'catchError', 'onError'}.contains(future.methodName.name)) {
    return true;
  }

  final element = _invokedElement(future);
  if (_isFailureRecordingCall(element)) return true;
  final capture = _FailureCapture(context);
  final closure = future is FunctionExpressionInvocation ? future.function.unParenthesized : null;
  final handled = closure is FunctionExpression
      ? capture.handlesBody(closure.body, 0, null)
      : capture.handlesCallee(element, 0);
  if (handled != null) return handled;

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

/// Decides whether a fire-and-forget callee's failures are captured by a mechanism the
/// building-flutter-apps skill prescribes, following resolved callees a few levels deep:
///
/// - the body catches internally (services-and-singletons.md "Catch internally"), or
/// - it throws nothing and every future it awaits or returns is captured: a Riverpod
///   `Mutation.run` (failures land in the mutation's `MutationError` state), a route or
///   modal future (it completes with the popped result, not an error), or a resolved
///   callee that is itself captured (including same-class calls such as
///   lists-forms-workflows.md `loadMore` awaiting `_loadPage`), or
/// - it has no future and makes no call at all (for example `async => null`).
final class _FailureCapture {
  _FailureCapture(this.context);

  static const _maxDepth = 3;

  final SourceScannerContext context;
  final Set<ExecutableElement> _visiting = {};

  /// Whether [element]'s declared body captures its failures; null when no body is
  /// available (SDK, abstract or external callee).
  bool? handlesCallee(Element? element, int depth) {
    if (element is! ExecutableElement) return null;
    final declared = element.baseElement;
    final body = _declaredBody(context, declared);
    if (body == null) return null;
    if (!_visiting.add(declared)) return false;
    final owner = declared.enclosingElement;
    try {
      return handlesBody(
        body,
        depth,
        declared.firstFragment.libraryFragment.scope,
        owner: owner is InterfaceElement ? owner : null,
      );
    } finally {
      _visiting.remove(declared);
    }
  }

  /// [scope] and [owner] resolve top-level and same-class calls when [body] comes from
  /// another library, whose declaration is only available as a parsed (unresolved) AST.
  bool handlesBody(FunctionBody body, int depth, Scope? scope, {InterfaceElement? owner}) {
    if (_catchesInternally(body)) return true;
    final sources = _FutureSourceCollector();
    body.accept(sources);
    if (sources.throws) return false;
    if (sources.futures.isEmpty) return !sources.calls;
    return sources.futures.every((future) => _handlesFuture(future, depth, scope, owner));
  }

  bool _handlesFuture(Expression future, int depth, Scope? scope, InterfaceElement? owner) {
    final element =
        _invokedElement(future) ??
        _unresolvedTopLevelCall(future, scope) ??
        _unresolvedSameClassCall(future, owner);
    if (_isFailureRecordingCall(element)) return true;
    if (depth >= _maxDepth) return false;
    return handlesCallee(element, depth + 1) ?? false;
  }
}

Element? _invokedElement(Expression expression) => switch (expression.unParenthesized) {
  MethodInvocation(:final methodName) => methodName.element,
  FunctionExpressionInvocation(:final element) => element,
  _ => null,
};

Element? _unresolvedTopLevelCall(Expression expression, Scope? scope) => switch (expression) {
  MethodInvocation(target: null, :final methodName) when scope != null =>
    scope.lookup(methodName.name).getter,
  _ => null,
};

Element? _unresolvedSameClassCall(Expression expression, InterfaceElement? owner) =>
    switch (expression.unParenthesized) {
      MethodInvocation(target: null || ThisExpression(), :final methodName) when owner != null =>
        owner.getMethod(methodName.name),
      _ => null,
    };

/// A Riverpod `Mutation.run`, or a Flutter / go_router navigation call (including a
/// go_router_builder route's generated `push`, and `maybePop`) whose future completes with
/// the route result.
bool _isFailureRecordingCall(Element? element) {
  if (element is! ExecutableElement) return false;
  final declared = element.baseElement;
  final uri = declared.library.uri.toString();
  final owner = declared.enclosingElement;
  final ownerName = owner is InterfaceElement ? owner.name : null;
  if (uri.startsWith('package:riverpod/')) {
    return declared.name == 'run' && ownerName == 'Mutation';
  }
  if (!_routePushMethods.contains(declared.name)) {
    return uri.startsWith('package:flutter/') &&
        declared is TopLevelFunctionElement &&
        _flutterModalFunctions.contains(declared.name);
  }
  if (uri.startsWith('package:go_router/')) return true;
  if (uri.startsWith('package:flutter/')) {
    return const {'Navigator', 'NavigatorState'}.contains(ownerName);
  }
  return owner is InterfaceElement &&
      owner.allSupertypes.any(
        (type) =>
            type.element.library.uri.toString().startsWith('package:go_router/') &&
            type.element.getMethod(declared.name!) != null,
      );
}

const _flutterModalFunctions = {
  'showAdaptiveDialog',
  'showCupertinoDialog',
  'showCupertinoModalPopup',
  'showCupertinoSheet',
  'showDialog',
  'showGeneralDialog',
  'showModalBottomSheet',
};

const _routePushMethods = {
  'maybePop',
  'push',
  'pushAndRemoveUntil',
  'pushNamed',
  'pushNamedAndRemoveUntil',
  'pushReplacement',
  'pushReplacementNamed',
  'replace',
  'replaceNamed',
};

/// Collects the futures a body awaits or returns, whether it throws, and whether it calls
/// anything. Nested closures run on their own schedule and are skipped.
final class _FutureSourceCollector extends RecursiveAstVisitor<void> {
  final futures = <Expression>[];
  bool throws = false;
  bool calls = false;

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitThrowExpression(ThrowExpression node) {
    throws = true;
    super.visitThrowExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    futures.add(node.expression.unParenthesized);
    super.visitAwaitExpression(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _addReturned(node.expression);
    super.visitReturnStatement(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _addReturned(node.expression);
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    calls = true;
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    calls = true;
    super.visitFunctionExpressionInvocation(node);
  }

  void _addReturned(Expression? expression) {
    final returned = expression?.unParenthesized;
    if (returned == null || returned is AwaitExpression) return;
    final type = returned.staticType;
    // A parsed body from another library has no types: any returned call may be a future.
    final isFuture = type == null
        ? returned is MethodInvocation || returned is FunctionExpressionInvocation
        : type is InterfaceType && (type.isDartAsyncFuture || type.isDartAsyncFutureOr);
    if (isFuture) futures.add(returned);
  }
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
