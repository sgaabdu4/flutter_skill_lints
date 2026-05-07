import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

bool isGeneratedRuleContext(RuleContext context) {
  final path = context.definingUnit.file.path.replaceAll('\\', '/');
  return path.endsWith('.g.dart') ||
      path.endsWith('.freezed.dart') ||
      path.endsWith('.gr.dart') ||
      path.endsWith('.gen.dart') ||
      path.endsWith('.generated.dart') ||
      path.endsWith('.mocks.dart') ||
      path.endsWith('.mock.dart') ||
      path.contains('/generated/');
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
  var found = false;

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
  var found = false;

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
  var found = false;

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
    final parent = node.parent;
    if (parent is PrefixedIdentifier && parent.prefix == node) return;
    if (parent is PropertyAccess && parent.target == node) return;
    if (parent is MethodInvocation && parent.target == node) return;
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
  var found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name.startsWith('_ensure')) {
      found = true;
      return;
    }
    super.visitMethodInvocation(node);
  }
}
