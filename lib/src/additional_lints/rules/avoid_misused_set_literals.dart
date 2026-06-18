import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a set literal is used where its value is ignored or non-boolean.
final class AvoidMisusedSetLiterals extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_misused_set_literals',
    'Avoid misused set literals.',
    correctionMessage:
        'Use the set literal as a value, or replace the condition with a boolean expression.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidMisusedSetLiterals()
    : super(
        name: 'avoid_misused_set_literals',
        description: 'Warns when a set literal is used as a statement or condition.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry
      ..addAssertStatement(this, visitor)
      ..addConditionalExpression(this, visitor)
      ..addDoStatement(this, visitor)
      ..addExpressionStatement(this, visitor)
      ..addForStatement(this, visitor)
      ..addIfElement(this, visitor)
      ..addIfStatement(this, visitor)
      ..addWhenClause(this, visitor)
      ..addWhileStatement(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidMisusedSetLiterals rule;

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
  void visitExpressionStatement(ExpressionStatement node) {
    _check(node.expression);
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

  void _check(Expression expression) {
    final unwrapped = _unwrap(expression);
    if (unwrapped is SetOrMapLiteral && unwrapped.isSet) {
      rule.reportAtNode(unwrapped);
    }
  }
}

Expression _unwrap(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }
  if (current is AsExpression) {
    return _unwrap(current.expression);
  }
  return current;
}
