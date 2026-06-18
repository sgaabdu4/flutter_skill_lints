import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a condition wraps an invertible boolean check in `!`.
class AvoidInvertedBooleanChecks extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_inverted_boolean_checks',
    'Avoid wrapping an invertible boolean check in !.',
    correctionMessage: 'Use the inverse operator directly.',
  );

  AvoidInvertedBooleanChecks()
    : super(
        name: 'avoid_inverted_boolean_checks',
        description: 'Warns when conditions use ! around an invertible boolean check.',
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

  final AvoidInvertedBooleanChecks rule;

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
    final expression = _unwrap(condition);
    if (expression is! PrefixExpression || expression.operator.type != TokenType.BANG) {
      return;
    }

    if (_hasDirectInverse(_unwrap(expression.operand))) {
      rule.reportAtNode(expression);
    }
  }
}

bool _hasDirectInverse(Expression expression) {
  return switch (expression) {
    BinaryExpression(:final operator) when _invertibleOperators.contains(operator.type) => true,
    IsExpression() => true,
    _ => false,
  };
}

const _invertibleOperators = {
  TokenType.EQ_EQ,
  TokenType.BANG_EQ,
  TokenType.LT,
  TokenType.GT,
  TokenType.LT_EQ,
  TokenType.GT_EQ,
};

Expression _unwrap(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }
  return current;
}
