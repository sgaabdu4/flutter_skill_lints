import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when one condition combines too many logical operands.
final class AvoidComplexConditions extends AnalysisRule {
  static const int maxOperands = 4;

  static const LintCode code = LintCode(
    'avoid_complex_conditions',
    'Avoid conditions with more than four logical operands.',
    correctionMessage: 'Extract the condition into named boolean values or a policy method.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidComplexConditions()
    : super(
        name: 'avoid_complex_conditions',
        description: 'Warns when a condition uses more than four && / || operands.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addAssertStatement(this, visitor);
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

  final AvoidComplexConditions rule;

  @override
  void visitAssertStatement(AssertStatement node) {
    _check(node.condition);
  }

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
    final expression = _unwrapParentheses(condition);
    if (_logicalOperandCount(expression) <= AvoidComplexConditions.maxOperands) return;

    rule.reportAtNode(expression);
  }
}

Expression _unwrapParentheses(Expression expression) {
  while (expression is ParenthesizedExpression) {
    expression = expression.expression;
  }

  return expression;
}

int _logicalOperandCount(Expression expression) {
  expression = _unwrapParentheses(expression);
  if (expression is! BinaryExpression || !_isLogicalOperator(expression.operator)) {
    return 1;
  }

  return _logicalOperandCount(expression.leftOperand) +
      _logicalOperandCount(expression.rightOperand);
}

bool _isLogicalOperator(Token token) {
  return token.type == TokenType.AMPERSAND_AMPERSAND || token.type == TokenType.BAR_BAR;
}
