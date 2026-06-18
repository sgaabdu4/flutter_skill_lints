import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/error/error.dart';

/// Warns when boolean values are combined with bitwise operators.
final class AvoidBitwiseOperatorsWithBooleans extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_bitwise_operators_with_booleans',
    'Avoid bitwise operators with boolean operands.',
    correctionMessage: 'Use && or ||, or make the eager evaluation explicit.',
  );

  AvoidBitwiseOperatorsWithBooleans()
    : super(
        name: 'avoid_bitwise_operators_with_booleans',
        description: 'Warns when non-nullable bool values are combined with &, |, or ^.',
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

  final AvoidBitwiseOperatorsWithBooleans rule;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (!_isBitwiseOperator(node.operator.type)) return;
    if (!_isNonNullableBool(node.leftOperand) || !_isNonNullableBool(node.rightOperand)) {
      return;
    }

    rule.reportAtNode(node);
  }
}

bool _isBitwiseOperator(TokenType type) {
  return type == TokenType.AMPERSAND || type == TokenType.BAR || type == TokenType.CARET;
}

bool _isNonNullableBool(Expression expression) {
  final type = expression.staticType;
  return type != null &&
      type.isDartCoreBool &&
      type.nullabilitySuffix != NullabilitySuffix.question;
}
