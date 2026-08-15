import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when RenderObject setters invalidate layout or paint without an
/// equality guard.
final class CheckForEqualsInRenderObjectSetters extends ClassDeclarationRule {
  static const LintCode code = LintCode(
    'check_for_equals_in_render_object_setters',
    'Check for equality before invalidating a RenderObject setter.',
    correctionMessage: 'Return early when the new value equals the current value.',
  );

  CheckForEqualsInRenderObjectSetters()
    : super(
        name: 'check_for_equals_in_render_object_setters',
        description:
            'Warns when RenderObject setters assign backing fields and call '
            'markNeeds* without first checking equality.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final CheckForEqualsInRenderObjectSetters rule;

  static const _renderObjectChecker = TypeChecker.fromName('RenderObject', packageName: 'flutter');

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !_renderObjectChecker.isSuperOf(element)) return;

    for (final member in node.body.members.whereType<MethodDeclaration>()) {
      if (!member.isSetter) continue;
      if (_hasEqualityGuardedInvalidation(member)) continue;

      rule.reportAtToken(member.name);
    }
  }
}

bool _hasEqualityGuardedInvalidation(MethodDeclaration setter) {
  final body = setter.body;
  if (body is! BlockFunctionBody) return true;

  final parameterName = _singleParameterName(setter.parameters);
  if (parameterName == null) return true;

  final assignedField = _firstAssignedPrivateField(body.block);
  if (assignedField == null) return true;
  if (!_containsRenderInvalidation(body.block)) return true;

  return _containsEqualityReturnGuard(body.block, assignedField, parameterName);
}

String? _singleParameterName(FormalParameterList? parameters) {
  final formalParameters = parameters?.parameters;
  if (formalParameters == null || formalParameters.length != 1) return null;

  return formalParameters.single.name?.lexeme;
}

String? _firstAssignedPrivateField(Block block) {
  final visitor = _AssignmentVisitor();
  block.accept(visitor);
  return visitor.fieldName;
}

bool _containsRenderInvalidation(Block block) {
  final visitor = _RenderInvalidationVisitor();
  block.accept(visitor);
  return visitor.found;
}

bool _containsEqualityReturnGuard(Block block, String fieldName, String parameterName) {
  final visitor = _EqualityReturnGuardVisitor(fieldName, parameterName);
  block.accept(visitor);
  return visitor.found;
}

final class _AssignmentVisitor extends RecursiveAstVisitor<void> {
  String? fieldName;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (fieldName != null) return;
    if (node.operator.type != TokenType.EQ) return;

    final name = _fieldName(node.leftHandSide);
    if (name != null && name.startsWith('_')) {
      fieldName = name;
      return;
    }

    super.visitAssignmentExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

final class _RenderInvalidationVisitor extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (found) return;

    final target = node.realTarget;
    final hasLocalTarget = target == null || target is ThisExpression;
    if (hasLocalTarget && node.methodName.name.startsWith('markNeeds')) {
      found = true;
      return;
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

final class _EqualityReturnGuardVisitor extends RecursiveAstVisitor<void> {
  _EqualityReturnGuardVisitor(this.fieldName, this.parameterName);

  final String fieldName;
  final String parameterName;
  bool found = false;

  @override
  void visitIfStatement(IfStatement node) {
    if (found) return;

    if (_isEqualityCheck(node.expression, fieldName, parameterName) &&
        _containsReturn(node.thenStatement)) {
      found = true;
      return;
    }

    super.visitIfStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

bool _isEqualityCheck(Expression expression, String fieldName, String parameterName) {
  final unwrapped = _unwrapParentheses(expression);
  if (unwrapped is! BinaryExpression || unwrapped.operator.type != TokenType.EQ_EQ) {
    return false;
  }

  final left = _fieldName(unwrapped.leftOperand);
  final right = _fieldName(unwrapped.rightOperand);

  return left == fieldName && right == parameterName || left == parameterName && right == fieldName;
}

bool _containsReturn(Statement statement) {
  if (statement is ReturnStatement) return true;

  if (statement is Block) {
    return statement.statements.any(_containsReturn);
  }

  return false;
}

Expression _unwrapParentheses(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }
  return current;
}

String? _fieldName(Expression expression) {
  return switch (expression) {
    SimpleIdentifier(:final name) => name,
    PropertyAccess(target: ThisExpression(), :final propertyName) => propertyName.name,
    PrefixedIdentifier(prefix: SimpleIdentifier(name: 'this'), :final identifier) =>
      identifier.name,
    _ => null,
  };
}
