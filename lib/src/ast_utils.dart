import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

bool isGeneratedRuleContext(RuleContext context) {
  final path = context.definingUnit.file.path.replaceAll('\\', '/');
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

bool isNotifierClass(ClassDeclaration node) {
  final className = node.namePart.typeName.lexeme;
  final superName = node.extendsClause?.superclass.name.lexeme ?? '';
  return className.endsWith('Notifier') ||
      superName == 'Notifier' ||
      superName == 'AsyncNotifier' ||
      superName.endsWith('Notifier') ||
      superName.startsWith(r'_$');
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

bool statementIsMountedReturnGuard(Statement statement, String targetName) {
  if (statement is! IfStatement) return false;
  final condition = statement.expression;
  if (condition is! PrefixExpression || condition.operator.lexeme != '!') {
    return false;
  }
  if (!isTargetProperty(condition.operand, targetName, 'mounted')) {
    return false;
  }
  return containsReturn(statement.thenStatement);
}

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

AstNode? firstTargetAccess(AstNode node, Set<String> targetNames) {
  final visitor = _TargetAccessFinder(targetNames);
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

final class AsyncStatementScanner {
  AsyncStatementScanner({
    required this.guardTarget,
    required this.accessTargets,
    required this.onViolation,
  });

  final String guardTarget;
  final Set<String> accessTargets;
  final void Function(AstNode node) onViolation;

  void scanBlock(Block block) {
    var afterAwait = false;

    for (final statement in block.statements) {
      if (afterAwait && statementIsMountedReturnGuard(statement, guardTarget)) {
        afterAwait = false;
        continue;
      }

      if (afterAwait) {
        final access = firstTargetAccess(statement, accessTargets);
        if (access != null) {
          onViolation(access);
          afterAwait = false;
          continue;
        }
      }

      final nested = _NestedBlockScanner(this);
      statement.accept(nested);

      if (containsAwait(statement)) {
        afterAwait = true;
      }
    }
  }
}

final class _NestedBlockScanner extends RecursiveAstVisitor<void> {
  _NestedBlockScanner(this.scanner);

  final AsyncStatementScanner scanner;

  @override
  void visitBlock(Block node) {
    scanner.scanBlock(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

final class _ReturnFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitReturnStatement(ReturnStatement node) {
    found = true;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

final class _AwaitFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    found = true;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

final class _ThrowFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitThrowExpression(ThrowExpression node) {
    found = true;
  }
}

final class _TargetAccessFinder extends RecursiveAstVisitor<void> {
  _TargetAccessFinder(this.targetNames);

  final Set<String> targetNames;
  AstNode? node;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (this.node != null) return;
    final target = node.target;
    if (target is SimpleIdentifier && targetNames.contains(target.name)) {
      if (target.name == 'ref' && node.methodName.name == 'mounted') return;
      this.node = node;
      return;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (this.node != null) return;
    if (targetNames.contains(node.prefix.name)) {
      if (node.prefix.name == 'ref' && node.identifier.name == 'mounted') {
        return;
      }
      if (node.prefix.name == 'context' && node.identifier.name == 'mounted') {
        return;
      }
      this.node = node;
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (this.node != null) return;
    final target = node.target;
    if (target is SimpleIdentifier && targetNames.contains(target.name)) {
      if (target.name == 'ref' && node.propertyName.name == 'mounted') {
        return;
      }
      if (target.name == 'context' && node.propertyName.name == 'mounted') {
        return;
      }
      this.node = node;
      return;
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (this.node != null) return;
    if (!targetNames.contains(node.name)) {
      super.visitSimpleIdentifier(node);
      return;
    }
    if (isExpressionTargetIdentifier(node)) return;
    if (classMemberNameIsDeclaration(node)) return;
    this.node = node;
  }

  @override
  void visitBlock(Block node) {}

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

final class _EnsureCallFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (name.startsWith('_ensure') || RegExp(r'^ensure[A-Z]\w*').hasMatch(name)) {
      found = true;
      return;
    }
    super.visitMethodInvocation(node);
  }
}
