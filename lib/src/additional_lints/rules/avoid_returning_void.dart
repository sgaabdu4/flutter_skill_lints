import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a void expression is returned.
final class AvoidReturningVoid extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_returning_void',
    'Avoid returning void expressions.',
    correctionMessage: 'Call the void expression before returning, or use `return;`.',
  );

  AvoidReturningVoid()
    : super(
        name: 'avoid_returning_void',
        description: 'Warns when return statements return void expressions.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;

    registry.addReturnStatement(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidReturningVoid rule;

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (expression == null) return;
    if (expression.staticType is! VoidType) return;

    rule.reportAtNode(expression);
  }
}
