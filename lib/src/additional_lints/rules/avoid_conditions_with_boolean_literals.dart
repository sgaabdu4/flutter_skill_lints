import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a control-flow condition directly contains boolean literals.
final class AvoidConditionsWithBooleanLiterals extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_conditions_with_boolean_literals',
    'Avoid boolean literals in conditions.',
    correctionMessage: 'Remove the literal branch or replace it with a named boolean.',
  );

  AvoidConditionsWithBooleanLiterals()
    : super(
        name: 'avoid_conditions_with_boolean_literals',
        description: 'Warns when conditions directly contain true or false literals.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addConditionalExpression(this, visitor);
    registry.addDoStatement(this, visitor);
    registry.addForStatement(this, visitor);
    registry.addIfElement(this, visitor);
    registry.addIfStatement(this, visitor);
    registry.addWhenClause(this, visitor);
    registry.addWhileStatement(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidConditionsWithBooleanLiterals rule;

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _check(node.condition);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _check(node.condition);
  }

  @override
  void visitForStatement(ForStatement node) {
    if (node.forLoopParts case ForPartsWithExpression(:final condition?)) {
      _check(condition);
    }
  }

  @override
  void visitIfElement(IfElement node) {
    _check(node.expression);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _check(node.expression);
  }

  @override
  void visitWhenClause(WhenClause node) {
    _check(node.expression);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _check(node.condition);
  }

  void _check(Expression condition) {
    final literal = _directBooleanLiteralInCondition(condition);
    if (literal == null) return;

    rule.reportAtNode(literal);
  }
}

BooleanLiteral? _directBooleanLiteralInCondition(Expression expression) {
  expression = _unwrapParentheses(expression);

  if (expression is BooleanLiteral) return expression;

  if (expression is PrefixExpression && expression.operator.type == TokenType.BANG) {
    return _directBooleanLiteralInCondition(expression.operand);
  }

  if (expression is BinaryExpression && _isLogicalOperator(expression.operator.type)) {
    return _directBooleanLiteralInCondition(expression.leftOperand) ??
        _directBooleanLiteralInCondition(expression.rightOperand);
  }

  return null;
}

Expression _unwrapParentheses(Expression expression) {
  while (expression is ParenthesizedExpression) {
    expression = expression.expression;
  }

  return expression;
}

bool _isLogicalOperator(TokenType type) {
  return type == TokenType.AMPERSAND_AMPERSAND || type == TokenType.BAR_BAR;
}
