import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a non-nullable boolean is compared to a boolean literal.
class NoBooleanLiteralCompare extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_boolean_literal_compare',
    'Avoid comparing a boolean value to a boolean literal.',
    correctionMessage: 'Use the boolean expression directly.',
  );

  NoBooleanLiteralCompare()
    : super(
        name: 'no_boolean_literal_compare',
        description: 'Warns when a non-nullable bool is compared to true or false.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addBinaryExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final NoBooleanLiteralCompare rule;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator.type;
    if (operator != TokenType.EQ_EQ && operator != TokenType.BANG_EQ) return;

    final leftIsLiteral = node.leftOperand is BooleanLiteral;
    final rightIsLiteral = node.rightOperand is BooleanLiteral;
    if (leftIsLiteral == rightIsLiteral) return;

    final comparedExpression = leftIsLiteral ? node.rightOperand : node.leftOperand;
    if (!_isNonNullableBool(comparedExpression)) return;

    rule.reportAtNode(node);
  }
}

bool _isNonNullableBool(Expression expression) {
  final type = expression.staticType;
  return type != null &&
      type.isDartCoreBool &&
      type.nullabilitySuffix != NullabilitySuffix.question;
}
