import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when parentheses wrap an expression in a simple expression context.
final class AvoidUnnecessaryParentheses extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_parentheses',
    'Avoid unnecessary parentheses.',
    correctionMessage: 'Remove the redundant parentheses.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidUnnecessaryParentheses()
    : super(
        name: 'avoid_unnecessary_parentheses',
        description: 'Warns when parentheses wrap an expression in a simple context.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;

    registry.addParenthesizedExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUnnecessaryParentheses rule;

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    if (!_isSimpleContext(node)) return;

    rule.reportAtNode(node);
  }
}

bool _isSimpleContext(ParenthesizedExpression node) {
  final parent = node.parent;

  return switch (parent) {
    ReturnStatement(:final expression) => identical(expression, node),
    VariableDeclaration(:final initializer) => identical(initializer, node),
    AssignmentExpression(:final rightHandSide) => identical(rightHandSide, node),
    ExpressionStatement(:final expression) => identical(expression, node),
    NamedExpression(:final expression) => identical(expression, node),
    ArgumentList(:final arguments) => arguments.contains(node),
    ListLiteral(:final elements) => elements.contains(node),
    SetOrMapLiteral(:final elements) => elements.contains(node),
    _ => false,
  };
}
