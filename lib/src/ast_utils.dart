import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/mounted_guard_utils.dart';

part 'ast_utils/ast_utils_part_01.dart';

/// Whether [provider], a `ref.watch` argument, resolves through its generated
/// `@ProviderFor` variable to a `@Riverpod(keepAlive: true)` source, in any
/// file. `.select(...)`, `.notifier`/`.future` and family calls are stripped
/// down to the provider variable.
bool isKeepAliveProviderExpression(Expression provider) {
  Expression? current = provider.unParenthesized;
  while (current != null) {
    final element = switch (current) {
      SimpleIdentifier(:final element) => element,
      PrefixedIdentifier(:final identifier) => identifier.element,
      PropertyAccess(:final propertyName) => propertyName.element,
      _ => null,
    };
    final variable = element is PropertyAccessorElement ? element.variable : element;
    if (variable is TopLevelVariableElement) return _isKeepAliveProviderVariable(variable);
    current = switch (current) {
      MethodInvocation(:final target, methodName: SimpleIdentifier(name: 'select')) => target,
      PrefixedIdentifier(:final prefix) => prefix,
      PropertyAccess(:final target) => target,
      FunctionExpressionInvocation(:final function) => function,
      _ => null,
    };
  }
  return false;
}

bool _isKeepAliveProviderVariable(TopLevelVariableElement variable) {
  final source = variable.metadata.annotations
      .map((annotation) => annotation.computeConstantValue())
      .where((value) => _isRiverpodAnnotationType(value?.type, 'ProviderFor'))
      .map((value) => value?.getField('value'))
      .firstOrNull;
  final declaration = source?.toTypeValue()?.element ?? source?.toFunctionValue();
  if (declaration == null) return false;
  return declaration.metadata.annotations.any((annotation) {
    final value = annotation.computeConstantValue();
    return _isRiverpodAnnotationType(value?.type, 'Riverpod') &&
        value?.getField('keepAlive')?.toBoolValue() == true;
  });
}

bool _isRiverpodAnnotationType(DartType? type, String name) {
  final element = type?.element;
  return element?.name == name &&
      (element?.library?.uri.toString().startsWith('package:riverpod_annotation/') ?? false);
}

/// Whether [annotation] evaluates to an instance of [className] declared in [package].
bool isPackageAnnotation(ElementAnnotation? annotation, String package, String className) {
  final type = annotation?.computeConstantValue()?.type;
  if (type is! InterfaceType || type.element.name != className) return false;
  final uri = type.element.library.uri;
  return uri.scheme == 'package' &&
      uri.pathSegments.isNotEmpty &&
      uri.pathSegments.first == package;
}

/// Recognizes a value annotated by the actual Freezed annotation library,
/// either `@freezed` or a configured `@Freezed(...)` constructor call.
bool isFreezedInterfaceType(InterfaceType type) =>
    type.element.metadata.annotations.any(isFreezedAnnotation);

/// Whether [annotation] resolves to `@freezed` or `@Freezed(...)` from
/// `package:freezed_annotation`.
bool isFreezedAnnotation(ElementAnnotation annotation) {
  final owner = annotation.element;
  if (owner?.library?.uri.toString() != 'package:freezed_annotation/freezed_annotation.dart') {
    return false;
  }
  final name = owner is ConstructorElement ? owner.enclosingElement.name : owner?.name;
  return name == 'freezed' || name == 'Freezed';
}

bool isGeneratedRuleContext(RuleContext context) =>
    isGeneratedSourcePath(context.definingUnit.file.path);

/// Whether [path] names a generated Dart source that lint rules skip.
bool isGeneratedSourcePath(String sourcePath) {
  final path = sourcePath.replaceAll('\\', '/');
  return path.endsWith('.g.dart') ||
      path.endsWith('.freezed.dart') ||
      path.endsWith('.gr.dart') ||
      path.endsWith('.gen.dart') ||
      path.endsWith('.generated.dart') ||
      path.endsWith('.mocks.dart') ||
      path.endsWith('.mock.dart') ||
      path.contains('/l10n/app_localizations') ||
      path.contains('/generated/');
}

mixin SkipGeneratedSources on AnalysisRule {
  bool shouldRegister(RuleContext context) => !isGeneratedRuleContext(context);
}

String? productionLibPath(RuleContext context) {
  if (context.isInTestDirectory || isGeneratedRuleContext(context)) return null;
  final path = context.definingUnit.file.path.replaceAll('\\', '/');
  if (!path.contains('/lib/') || path.endsWith('_test.dart')) return null;
  return path;
}

bool isCommonConstantOwnerPath(String path) {
  return path.endsWith('_constants.dart') ||
      path.endsWith('_keys.dart') ||
      path.endsWith('_schema.dart') ||
      path.endsWith('_strings.dart') ||
      path.endsWith('_theme.dart') ||
      path.endsWith('_tokens.dart') ||
      path.contains('/constants/');
}

bool isTestSourceContext(RuleContext context) {
  if (context.isInTestDirectory) return true;
  return context.definingUnit.file.path.replaceAll('\\', '/').endsWith('_test.dart');
}

bool isExcludedProductionSource(RuleContext context) {
  if (context.isInTestDirectory || isGeneratedRuleContext(context)) return true;

  final path = context.definingUnit.file.path.replaceAll('\\', '/');
  return !path.contains('/lib/') || path.endsWith('_test.dart') || path.contains('/l10n/');
}

bool isClassAssignableTo(ClassDeclaration node, TypeChecker checker) {
  final element = node.declaredFragment?.element;
  return element != null && checker.isSuperOf(element);
}

String? filteredCollectionProperty(PropertyAccess node) {
  final property = node.propertyName.name;
  if (property != 'isEmpty' && property != 'isNotEmpty') return null;

  final target = node.target;
  if (target is! MethodInvocation || target.methodName.name != 'where') return null;
  if (target.argumentList.arguments.length != 1) return null;

  final sourceType = target.target?.staticType;
  if (sourceType == null ||
      !const TypeChecker.fromUrl('dart:core#Iterable').isAssignableFromType(sourceType)) {
    return null;
  }

  return property;
}

bool isEnclosedClassAssignableTo(AstNode node, TypeChecker checker) {
  final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
  return declaration != null && isClassAssignableTo(declaration, checker);
}

BlockClassBody? classBodyOf(ClassDeclaration node) {
  final body = node.body;
  return body is BlockClassBody ? body : null;
}

/// Flutter widget preview annotations: `@Preview` and `MultiPreview` subclasses.
const flutterWidgetPreviewChecker = TypeChecker.any([
  TypeChecker.fromName('Preview', packageName: 'flutter'),
  TypeChecker.fromName('MultiPreview', packageName: 'flutter'),
]);

/// Whether [node] carries a resolved Flutter widget preview annotation.
bool hasWidgetPreviewAnnotation(AnnotatedNode node) => widgetPreviewAnnotation(node) != null;

/// The resolved Flutter widget preview annotation on [node], if any.
Annotation? widgetPreviewAnnotation(AnnotatedNode node) {
  for (final annotation in node.metadata) {
    final type = switch (annotation.element) {
      ConstructorElement(:final returnType) => returnType,
      PropertyAccessorElement(:final returnType) => returnType,
      _ => null,
    };
    if (type != null && flutterWidgetPreviewChecker.isAssignableFromType(type)) return annotation;
  }
  return null;
}

/// The resolved `@Preview` function, method, or constructor enclosing [node].
AnnotatedNode? enclosingWidgetPreview(AstNode node) {
  for (AstNode? current = node; current != null; current = current.parent) {
    if (current is FunctionDeclaration ||
        current is MethodDeclaration ||
        current is ConstructorDeclaration) {
      final declaration = current as AnnotatedNode;
      if (hasWidgetPreviewAnnotation(declaration)) return declaration;
    }
  }
  return null;
}

/// Top-level functions and class members annotated with a resolved `@Preview`.
Iterable<AnnotatedNode> widgetPreviewDeclarations(CompilationUnit unit) sync* {
  for (final declaration in unit.declarations) {
    if (declaration is FunctionDeclaration && hasWidgetPreviewAnnotation(declaration)) {
      yield declaration;
    } else if (declaration is ClassDeclaration) {
      final members = classBodyOf(declaration)?.members ?? const <ClassMember>[];
      yield* members.where(hasWidgetPreviewAnnotation);
    }
  }
}

BlockClassBody? flutterStateBody(ClassDeclaration node) {
  if (!isClassAssignableTo(node, flutterStateChecker)) return null;
  return classBodyOf(node);
}

Expression? namedArgumentExpression(ArgumentList arguments, String name) {
  for (final argument in arguments.arguments.whereType<NamedArgument>()) {
    if (argument.name.lexeme == name) return argument.argumentExpression;
  }
  return null;
}

bool isInlineCreatedExpression(Expression expression) {
  final unwrapped = expression.unParenthesized;
  return unwrapped is MethodInvocation || unwrapped is InstanceCreationExpression;
}

bool isIntlMessageInvocation(MethodInvocation node) {
  final target = node.target;
  return target is SimpleIdentifier && target.name == 'Intl' && node.methodName.name == 'message';
}

NamedArgument? namedInvocationArgument(MethodInvocation node, String name) {
  for (final argument in node.argumentList.arguments.whereType<NamedArgument>()) {
    if (argument.name.lexeme == name) return argument;
  }
  return null;
}

bool isNonEmptyMapLiteral(SetOrMapLiteral expression) {
  return expression.isMap && expression.elements.whereType<MapLiteralEntry>().isNotEmpty;
}

String? simpleLiteralKey(
  Expression expression, {
  bool includeIdentifiers = false,
  bool includeNegative = false,
}) {
  final unwrapped = expression.unParenthesized;
  if (includeNegative && unwrapped is PrefixExpression && unwrapped.operator.lexeme == '-') {
    final operand = unwrapped.operand.unParenthesized;
    return switch (operand) {
      DoubleLiteral(:final value) => 'double:-$value',
      IntegerLiteral(:final value?) => 'int:-$value',
      _ => null,
    };
  }

  return switch (unwrapped) {
    BooleanLiteral(:final value) => 'bool:$value',
    DoubleLiteral(:final value) => 'double:$value',
    IntegerLiteral(:final value?) => 'int:$value',
    NullLiteral() => 'null',
    PrefixedIdentifier() when includeIdentifiers => 'identifier:${unwrapped.toSource()}',
    PropertyAccess() when includeIdentifiers => 'identifier:${unwrapped.toSource()}',
    SimpleIdentifier(:final name) when includeIdentifiers => 'identifier:$name',
    SimpleStringLiteral(:final value) => 'string:$value',
    _ => null,
  };
}

Iterable<ConstructorDeclaration> constructorsWithLogic(BlockClassBody body) sync* {
  for (final member in body.members) {
    if (member is! ConstructorDeclaration) continue;

    final hasBody =
        member.body is BlockFunctionBody &&
        (member.body as BlockFunctionBody).block.statements.isNotEmpty;
    final hasInitializers = member.initializers.any((initializer) {
      return initializer is! SuperConstructorInvocation;
    });

    if (hasBody || hasInitializers) yield member;
  }
}

Set<String> formalParameterNames(FormalParameterList? parameters) {
  if (parameters == null) return const {};

  return {
    for (final parameter in parameters.parameters)
      if (parameter.name case final name?) name.lexeme,
  };
}

ClassDeclaration? localClassDeclaration(AstNode node, String className) {
  final unit = node.root;
  if (unit is! CompilationUnit) return null;

  for (final declaration in unit.declarations) {
    if (declaration is ClassDeclaration && declaration.namePart.typeName.lexeme == className) {
      return declaration;
    }
  }
  return null;
}

bool declaresToString(ClassDeclaration declaration) {
  return declaration.body.members.any(
    (member) => member is MethodDeclaration && member.name.lexeme == 'toString',
  );
}

bool isInFreezedClass(AstNode node) {
  final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
  return declaration?.metadata.any((annotation) {
        final name = annotation.name.name;
        return name == 'freezed' || name == 'Freezed';
      }) ??
      false;
}

/// Riverpod and state_notifier notifier bases. Riverpod 3 codegen notifiers
/// (`extends _$X`) reach AnyNotifier through `$Notifier`/`$AsyncNotifier`,
/// never through the hand-written Notifier.
const riverpodNotifierChecker = TypeChecker.any([
  TypeChecker.fromName('AnyNotifier', packageName: 'riverpod'),
  TypeChecker.fromName('Notifier', packageName: 'riverpod'),
  TypeChecker.fromName('AsyncNotifier', packageName: 'riverpod'),
  TypeChecker.fromName('StreamNotifier', packageName: 'riverpod'),
  TypeChecker.fromName('StateNotifier', packageName: 'state_notifier'),
]);

bool isNotifierClass(ClassDeclaration node) {
  final className = node.namePart.typeName.lexeme;
  final superName = node.extendsClause?.superclass.name.lexeme ?? '';
  return className.endsWith('Notifier') ||
      superName == 'Notifier' ||
      superName == 'AsyncNotifier' ||
      superName.endsWith('Notifier') ||
      superName.startsWith(r'_$');
}

/// Whether [node] carries the resolved `@riverpod` / `@Riverpod(...)` codegen annotation.
bool hasRiverpodCodegenAnnotation(AnnotatedNode node) {
  return node.metadata.any((annotation) {
    final element = annotation.element;
    final isRiverpod = switch (element) {
      ConstructorElement(:final enclosingElement) => enclosingElement.name == 'Riverpod',
      PropertyAccessorElement(:final name) => name == 'riverpod',
      _ => false,
    };
    final library = element?.library?.uri.toString() ?? '';
    return isRiverpod && library.startsWith('package:riverpod_annotation/');
  });
}

bool hasAnnotationNamed(AnnotatedNode node, Set<String> names) {
  for (final annotation in node.metadata) {
    final name = annotation.name.name;
    if (names.contains(name)) return true;
  }
  return false;
}

bool isTargetProperty(Expression? expression, String targetName, String propertyName) {
  if (expression is PrefixedIdentifier) {
    return expression.prefix.name == targetName && expression.identifier.name == propertyName;
  }
  if (expression is PropertyAccess) {
    return expression.target is SimpleIdentifier &&
        (expression.target as SimpleIdentifier).name == targetName &&
        expression.propertyName.name == propertyName;
  }
  return false;
}

bool isTargetMethodInvocation(MethodInvocation node, String targetName, String methodName) {
  final target = node.target;
  return target is SimpleIdentifier &&
      target.name == targetName &&
      node.methodName.name == methodName;
}

bool statementIsMountedReturnGuard(
  Statement statement,
  String targetName, {
  bool Function(Expression)? additionalCondition,
}) {
  if (statement is! IfStatement) return false;
  return _returnsWhenUnmounted(statement.expression, targetName, additionalCondition) &&
      _alwaysExits(statement.thenStatement);
}

bool _returnsWhenUnmounted(
  Expression expression,
  String targetName,
  bool Function(Expression)? additionalCondition,
) {
  final condition = expression.unParenthesized;
  if (additionalCondition?.call(condition) ?? false) return true;
  if (condition is PrefixExpression && condition.operator.lexeme == '!') {
    final mounted = condition.operand.unParenthesized;
    return isTargetProperty(mounted, targetName, 'mounted') &&
        switch (targetName) {
          'ref' => isRiverpodRefAccess(mounted),
          'context' => isCapturedContextAccess(mounted),
          _ => true,
        };
  }
  if (condition is BinaryExpression && condition.operator.lexeme == '||') {
    return _returnsWhenUnmounted(condition.rightOperand, targetName, additionalCondition) ||
        _returnsWhenUnmounted(condition.leftOperand, targetName, additionalCondition) &&
            isPureMountedGuardSuffix(condition.rightOperand);
  }
  return false;
}

bool _alwaysExits(Statement statement) => switch (statement) {
  ReturnStatement() => true,
  Block(:final statements) when statements.isNotEmpty => _alwaysExits(statements.last),
  IfStatement(:final thenStatement, :final elseStatement?) =>
    _alwaysExits(thenStatement) && _alwaysExits(elseStatement),
  _ => false,
};

bool containsReturn(AstNode node) {
  final visitor = _ReturnFinder();
  node.accept(visitor);
  return visitor.found;
}

bool containsAwait(AstNode node) {
  final visitor = _AwaitFinder();
  node.accept(visitor);
  return visitor.found;
}

AstNode? firstTargetAccess(AstNode node, Set<String> targetNames, {bool includeBlocks = false}) {
  final visitor = _TargetAccessFinder(targetNames, includeBlocks: includeBlocks);
  node.accept(visitor);
  return visitor.node;
}

bool containsThrowExpression(AstNode node) {
  final visitor = _ThrowFinder();
  node.accept(visitor);
  return visitor.found;
}

MethodDeclaration? enclosingMethod(AstNode node) => node.thisOrAncestorOfType<MethodDeclaration>();

ClassDeclaration? enclosingClass(AstNode node) => node.thisOrAncestorOfType<ClassDeclaration>();

ClassDeclaration? findStateClass(Iterable<ClassDeclaration> classes, String widgetName) {
  for (final stateClass in classes) {
    final superclass = stateClass.extendsClause?.superclass;
    final typeArguments = superclass?.typeArguments?.arguments;
    if (typeArguments?.length != 1) continue;
    final typeArgument = typeArguments!.first;
    if (typeArgument is NamedType && typeArgument.name.lexeme == widgetName) return stateClass;
  }
  return null;
}

RegularFormalParameter? extensionTypeRepresentationParameter(ExtensionTypeDeclaration node) {
  final namePart = node.namePart;
  if (namePart is! PrimaryConstructorDeclaration) return null;
  final parameter = namePart.formalParameters.parameters.singleOrNull;
  return parameter is RegularFormalParameter ? parameter : null;
}

bool isExpressionTargetIdentifier(SimpleIdentifier node) {
  final parent = node.parent;
  return (parent is PrefixedIdentifier && parent.prefix == node) ||
      (parent is PropertyAccess && parent.target == node) ||
      (parent is MethodInvocation && parent.target == node);
}

bool isStatusCodeExpression(Expression expression) {
  final unwrapped = expression.unParenthesized;
  return switch (unwrapped) {
    SimpleIdentifier(:final name) => _statusCodePropertyNames.contains(name.toLowerCase()),
    PrefixedIdentifier(:final identifier) => _statusCodePropertyNames.contains(
      identifier.name.toLowerCase(),
    ),
    PropertyAccess(:final propertyName) => _statusCodePropertyNames.contains(
      propertyName.name.toLowerCase(),
    ),
    _ => false,
  };
}

bool isAsyncThenReturn(MethodInvocation node) {
  if (node.methodName.name != 'thenReturn') return false;

  final arguments = node.argumentList.arguments.where((argument) => argument is! NamedArgument);
  final argument = arguments.length == 1 ? arguments.single : null;
  final type = argument?.argumentExpression.staticType;
  if (type is! InterfaceType || type.element.library.isDartAsync != true) return false;

  final name = type.element.name;
  return name == 'Future' || name == 'Stream';
}

bool isNotifierSelector(Expression expression) {
  return switch (expression.unParenthesized) {
    PrefixedIdentifier(:final identifier) => identifier.name == 'notifier',
    PropertyAccess(:final propertyName) => propertyName.name == 'notifier',
    _ => false,
  };
}

String? packageNameFromUri(StringLiteral uri) {
  final value = uri.stringValue;
  if (value == null || !value.startsWith('package:')) return null;

  final path = value.substring('package:'.length);
  final separatorIndex = path.indexOf('/');
  return separatorIndex == -1 ? path : path.substring(0, separatorIndex);
}

const _statusCodePropertyNames = {
  'code',
  'errorcode',
  'httpstatuscode',
  'responsecode',
  'statuscode',
};

Object? getterReadElement(SimpleIdentifier node) {
  return node.inGetterContext() ? node.element : null;
}

abstract class GetterReadVisitor extends RecursiveAstVisitor<void> {
  const GetterReadVisitor();

  void checkGetterRead(SimpleIdentifier node, Object key);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final key = getterReadElement(node);
    if (key != null) checkGetterRead(node, key);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

void forEachSimpleBlockStatement(
  Block block, {
  required void Function(VariableDeclarationList variables) onVariableDeclaration,
  required void Function(Expression expression) onExpression,
  required void Function(Expression? expression) onReturn,
  required void Function() onOther,
}) {
  for (final statement in block.statements) {
    if (statement is VariableDeclarationStatement) {
      onVariableDeclaration(statement.variables);
      continue;
    }
    if (statement is ExpressionStatement) {
      onExpression(statement.expression);
      continue;
    }
    if (statement is ReturnStatement) {
      onReturn(statement.expression);
      continue;
    }
    onOther();
  }
}

bool isMutationMethodName(String name) =>
    RegExp(r'^(?:create|update|delete|set|reorder|save|add|remove)(?:[A-Z_]|$)').hasMatch(name);

bool containsEnsureCall(AstNode node) {
  final visitor = _EnsureCallFinder();
  node.accept(visitor);
  return visitor.found;
}

bool containsFutureMicrotaskAncestor(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is MethodInvocation &&
        current.methodName.name == 'microtask' &&
        current.target is SimpleIdentifier &&
        (current.target as SimpleIdentifier).name == 'Future') {
      return true;
    }
    if (current is MethodDeclaration || current is FunctionDeclaration) {
      return false;
    }
    current = current.parent;
  }
  return false;
}

bool classMemberNameIsDeclaration(SimpleIdentifier node) {
  final parent = node.parent;
  if (parent is VariableDeclaration && parent.name.lexeme == node.name) {
    return parent.name.offset == node.offset;
  }
  return false;
}

/// Tracks whether each statement can run after an unguarded `await`.
///
/// The state flows into nested blocks, catch/finally clauses, loop iterations
/// and inline awaits, so a guard is required wherever execution resumes.
final class AsyncStatementScanner {
  AsyncStatementScanner({
    required this.guardTarget,
    required this.accessTargets,
    required this.onViolation,
    this.additionalMountedCondition,
    this.mountedWhenTrue,
  });

  final String guardTarget;
  final Set<String> accessTargets;
  final void Function(AstNode node) onViolation;
  final bool Function(Expression)? additionalMountedCondition;

  /// Whether a condition can only be true while the guard target is mounted.
  final bool Function(Expression)? mountedWhenTrue;

  final _reported = <AstNode>{};
  var _silent = 0;

  void scanBlock(Block block) => _scanStatements(block.statements, false);

  /// Scans an expression function body such as `() async => state = await f()`.
  void scanExpression(Expression expression) => _scanInline(expression, false);

  bool _scanStatements(Iterable<Statement> statements, bool afterAwait) {
    var state = afterAwait;
    for (final statement in statements) {
      state = _scanStatement(statement, state);
    }
    return state;
  }

  bool _scanStatement(Statement statement, bool afterAwait) => switch (statement) {
    Block(:final statements) => _scanStatements(statements, afterAwait),
    IfStatement() => _scanIf(statement, afterAwait),
    TryStatement() => _scanTry(statement, afterAwait),
    WhileStatement(:final condition, :final body) => _scanLoop(
      afterAwait,
      before: [condition],
      body: body,
    ),
    DoStatement(:final body, :final condition) => _scanLoop(
      afterAwait,
      body: body,
      after: [condition],
    ),
    ForStatement(:final forLoopParts, :final body, :final awaitKeyword) => switch (forLoopParts) {
      ForParts(:final condition, :final updaters) => _scanLoop(
        _scanForInitializer(forLoopParts, afterAwait),
        before: [?condition],
        body: body,
        after: updaters,
      ),
      ForEachParts(:final iterable) => _scanLoop(
        _scanInline(iterable, afterAwait),
        body: body,
        awaitEachIteration: awaitKeyword != null,
      ),
    },
    SwitchStatement(:final expression, :final members) => _scanSwitch(
      _scanInline(expression, afterAwait),
      members,
    ),
    LabeledStatement(:final statement) => _scanStatement(statement, afterAwait),
    FunctionDeclarationStatement() => afterAwait,
    _ => _scanInline(statement, afterAwait),
  };

  bool _scanForInitializer(ForParts parts, bool afterAwait) => switch (parts) {
    ForPartsWithDeclarations(:final variables) => _scanInline(variables, afterAwait),
    ForPartsWithExpression(:final initialization?) => _scanInline(initialization, afterAwait),
    ForPartsWithPattern(:final variables) => _scanInline(variables, afterAwait),
    _ => afterAwait,
  };

  bool _scanIf(IfStatement statement, bool afterAwait) {
    if (statementIsMountedReturnGuard(
      statement,
      guardTarget,
      additionalCondition: additionalMountedCondition,
    )) {
      return _scanMountedReturnGuard(statement, afterAwait);
    }
    final condition = statement.expression;
    if (mountedWhenTrue?.call(condition) ?? false) {
      final conditionAwaits = containsAwait(condition);
      return _scanBranches(
        statement,
        thenEntry: conditionAwaits,
        elseEntry: afterAwait || conditionAwaits,
        exitWithoutElse: afterAwait,
      );
    }
    final branchEntry = _scanInline(condition, afterAwait);
    return _scanBranches(
      statement,
      thenEntry: branchEntry,
      elseEntry: branchEntry,
      exitWithoutElse: branchEntry,
    );
  }

  /// The then branch of `if (!mounted) return;` runs only while unmounted.
  bool _scanMountedReturnGuard(IfStatement statement, bool afterAwait) {
    if (afterAwait) {
      final access = firstTargetAccess(statement.thenStatement, accessTargets, includeBlocks: true);
      if (access != null) _report(access);
    }
    final elseStatement = statement.elseStatement;
    return elseStatement == null ? false : _scanStatement(elseStatement, afterAwait);
  }

  bool _scanBranches(
    IfStatement statement, {
    required bool thenEntry,
    required bool elseEntry,
    required bool exitWithoutElse,
  }) {
    final elseStatement = statement.elseStatement;
    final thenExit = _scanStatement(statement.thenStatement, thenEntry);
    final elseExit = elseStatement == null
        ? exitWithoutElse
        : _scanStatement(elseStatement, elseEntry);
    return _mayContinue(statement.thenStatement, thenExit) || _mayContinue(elseStatement, elseExit);
  }

  bool _scanTry(TryStatement statement, bool afterAwait) {
    final bodyExit = _scanStatement(statement.body, afterAwait);
    final catchEntry = afterAwait || containsAwait(statement.body);
    var normalExit = _mayContinue(statement.body, bodyExit);
    var finallyEntry = catchEntry;
    for (final clause in statement.catchClauses) {
      final catchExit = _scanStatement(clause.body, catchEntry);
      normalExit = normalExit || _mayContinue(clause.body, catchExit);
      finallyEntry = finallyEntry || containsAwait(clause.body);
    }
    final finallyBlock = statement.finallyBlock;
    if (finallyBlock == null) return normalExit;
    // Every path through finally is checked; only a normal exit continues.
    _scanStatement(finallyBlock, finallyEntry);
    return _silently(() => _scanStatement(finallyBlock, normalExit));
  }

  bool _scanLoop(
    bool afterAwait, {
    required Statement body,
    List<Expression> before = const [],
    List<Expression> after = const [],
    bool awaitEachIteration = false,
  }) {
    bool iteration({required bool entry}) {
      var state = entry;
      for (final expression in before) {
        state = _scanInline(expression, state);
      }
      state = _scanStatement(body, state || awaitEachIteration);
      for (final expression in after) {
        state = _scanInline(expression, state);
      }
      return state;
    }

    final firstExit = iteration(entry: afterAwait);
    // A later iteration resumes from where the previous one ended.
    final laterExit = firstExit && !afterAwait ? iteration(entry: true) : firstExit;
    return afterAwait || firstExit || laterExit;
  }

  bool _scanSwitch(bool afterAwait, NodeList<SwitchMember> members) {
    var exit = afterAwait;
    for (final member in members) {
      exit = _scanStatements(member.statements, afterAwait) || exit;
    }
    return exit;
  }

  bool _scanInline(AstNode node, bool afterAwait) {
    if (afterAwait) {
      final access = firstTargetAccess(node, accessTargets);
      if (access != null) {
        _report(access);
        return false;
      }
      return true;
    }
    final awaitEnd = _firstAwaitEnd(node);
    if (awaitEnd == null) return false;
    final access = _accessAfterAwait(node, awaitEnd);
    if (access != null) {
      _report(access);
      return false;
    }
    return true;
  }

  AstNode? _accessAfterAwait(AstNode node, int awaitEnd) {
    final writes = _AwaitedWriteFinder(accessTargets);
    node.accept(writes);
    if (writes.node != null) return writes.node;
    final finder = _TargetAccessFinder(accessTargets, where: (access) => access.offset >= awaitEnd);
    node.accept(finder);
    return finder.node;
  }

  bool _mayContinue(Statement? statement, bool exit) =>
      exit && (statement == null || !_alwaysExits(statement));

  T _silently<T>(T Function() scan) {
    _silent++;
    try {
      return scan();
    } finally {
      _silent--;
    }
  }

  void _report(AstNode node) {
    if (_silent == 0 && _reported.add(node)) onViolation(node);
  }
}
