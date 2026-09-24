import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/mounted_guard_utils.dart';

/// Warns when a function is declared inside another function body.
class AvoidLocalFunctions extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_local_functions',
    'Avoid local function declarations.',
    correctionMessage: 'Move the function to a method or top-level helper.',
  );

  AvoidLocalFunctions()
    : super(
        name: 'avoid_local_functions',
        description: 'Warns when a local function declaration is used.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addFunctionDeclarationStatement(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidLocalFunctions rule;

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    if (_isIdentityGuardedCallback(node)) return;
    rule.reportAtToken(node.functionDeclaration.name);
  }
}

bool _isIdentityGuardedCallback(FunctionDeclarationStatement declaration) {
  // A named local callback retains a unique tear-off for restoring its own slot.
  final element = declaration.functionDeclaration.declaredFragment?.element;
  final outerBody = declaration.thisOrAncestorOfType<FunctionBody>();
  if (element == null || outerBody == null) return false;

  final uses = _CallbackIdentityUses(element, declaration.functionDeclaration, outerBody);
  outerBody.accept(uses);
  return uses.hasMatchingCleanupGuard;
}

final class _CallbackIdentityUses extends RecursiveAstVisitor<void> {
  _CallbackIdentityUses(this.element, this.declaration, this.outerBody);

  final Element element;
  final FunctionDeclaration declaration;
  final FunctionBody outerBody;
  final _assignedSlots = <({Element member, String receiver})>{};
  final _comparedSlots = <({Element member, String receiver})>{};

  bool get hasMatchingCleanupGuard => _assignedSlots.any(_comparedSlots.contains);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element != element ||
        (node.offset >= declaration.offset && node.end <= declaration.end)) {
      return;
    }

    final closure = node.thisOrAncestorOfType<FunctionExpression>();
    final isNestedClosure = closure != null && !identical(closure, outerBody.parent);
    if (isNestedClosure) {
      final compared = _callbackSlot(_otherIdentityOperand(node));
      if (compared != null && _guardsCleanupWrite(node, compared, element)) {
        _comparedSlots.add(compared);
      }
      return;
    }
    final assignment = node.parent;
    if (assignment is! AssignmentExpression || !identical(assignment.rightHandSide, node)) return;
    final assigned = _callbackSlot(assignment.leftHandSide, writeElement: assignment.writeElement);
    if (assigned != null) _assignedSlots.add(assigned);
  }
}

bool _guardsCleanupWrite(
  SimpleIdentifier callback,
  ({Element member, String receiver}) slot,
  Element callbackElement,
) {
  final comparison = switch (callback.parent) {
    BinaryExpression() => callback.parent,
    ArgumentList(:final parent) when parent is MethodInvocation => parent,
    _ => null,
  };
  final condition = _requiredIdentityCondition(comparison);
  final ifStatement = condition?.parent;
  if (ifStatement is! IfStatement || !identical(ifStatement.expression, condition)) {
    return false;
  }

  final thenStatement = ifStatement.thenStatement;
  if (thenStatement is Block) {
    return thenStatement.statements.isNotEmpty &&
        _writesCallbackSlot(thenStatement.statements.first, slot, callbackElement);
  }
  return _writesCallbackSlot(thenStatement, slot, callbackElement);
}

AstNode? _requiredIdentityCondition(AstNode? comparison) {
  var condition = comparison;
  while (condition != null) {
    final parent = condition.parent;
    if (parent is ParenthesizedExpression ||
        (parent is BinaryExpression &&
            parent.operator.lexeme == '&&' &&
            (!identical(parent.leftOperand, condition) ||
                isPureMountedGuardSuffix(parent.rightOperand)))) {
      condition = parent;
      continue;
    }
    return condition;
  }
  return null;
}

bool _writesCallbackSlot(
  Statement statement,
  ({Element member, String receiver}) slot,
  Element callbackElement,
) {
  if (statement is! ExpressionStatement || statement.expression is! AssignmentExpression) {
    return false;
  }
  final assignment = statement.expression as AssignmentExpression;
  if (assignment.operator.lexeme != '=' ||
      _expressionIsElement(assignment.rightHandSide, callbackElement) ||
      _callbackSlot(assignment.rightHandSide) == slot) {
    return false;
  }
  return _callbackSlot(assignment.leftHandSide, writeElement: assignment.writeElement) == slot;
}

bool _expressionIsElement(Expression expression, Element element) => switch (expression) {
  SimpleIdentifier() => expression.element == element,
  ParenthesizedExpression(:final expression) => _expressionIsElement(expression, element),
  _ => false,
};

({Element member, String receiver})? _callbackSlot(
  Expression? expression, {
  Element? writeElement,
}) {
  if (expression is SimpleIdentifier) {
    final member = (writeElement ?? expression.element)?.nonSynthetic;
    return member == null ? null : (member: member, receiver: '');
  }
  if (expression is PropertyAccess) {
    final member = (writeElement ?? expression.propertyName.element)?.nonSynthetic;
    final receiver = _receiverKey(expression.target);
    if (member == null || receiver == null) return null;
    return (member: member, receiver: receiver);
  }
  if (expression is PrefixedIdentifier) {
    final member = (writeElement ?? expression.identifier.element)?.nonSynthetic;
    final receiver = _receiverKey(expression.prefix);
    if (member == null || receiver == null) return null;
    return (member: member, receiver: receiver);
  }
  return null;
}

String? _receiverKey(Expression? expression) {
  if (expression is ThisExpression) return '';
  if (expression is SimpleIdentifier) {
    return expression.element?.nonSynthetic.id.toString();
  }
  if (expression is PrefixedIdentifier) {
    final parent = _receiverKey(expression.prefix);
    final member = expression.identifier.element?.nonSynthetic;
    if (parent == null || member == null) return null;
    return '$parent/${member.id}';
  }
  if (expression is PropertyAccess) {
    final parent = _receiverKey(expression.target);
    final member = expression.propertyName.element?.nonSynthetic;
    if (parent == null || member == null) return null;
    return '$parent/${member.id}';
  }
  return null;
}

Expression? _otherIdentityOperand(SimpleIdentifier identifier) {
  final parent = identifier.parent;
  if (parent is BinaryExpression && parent.operator.lexeme == '==') {
    final other = identical(parent.leftOperand, identifier)
        ? parent.rightOperand
        : parent.leftOperand;
    if (other is SimpleIdentifier && other.element == identifier.element) return null;
    return other;
  }

  if (parent is! ArgumentList || parent.parent is! MethodInvocation) return null;
  final invocation = parent.parent! as MethodInvocation;
  if (!_isCoreIdentityComparison(invocation)) return null;
  final other = identical(parent.arguments.first, identifier)
      ? parent.arguments.last
      : parent.arguments.first;
  if (other is SimpleIdentifier && other.element == identifier.element) return null;
  return other is Expression ? other : null;
}

bool _isCoreIdentityComparison(MethodInvocation invocation) {
  final target = invocation.methodName.element;
  return invocation.methodName.name == 'identical' &&
      target is TopLevelFunctionElement &&
      target.library.identifier == 'dart:core' &&
      invocation.argumentList.arguments.length == 2;
}
