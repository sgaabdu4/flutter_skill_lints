import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when `toString()` is called on a nullable value.
class AvoidNullableToString extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_nullable_tostring',
    'Avoid calling toString() on nullable values.',
    correctionMessage: 'Handle the null case explicitly before converting the value to a string.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidNullableToString()
    : super(
        name: 'avoid_nullable_tostring',
        description: 'Warns when nullable values are converted with toString().',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidNullableToString rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'toString') return;
    if (node.argumentList.arguments.isNotEmpty) return;

    final targetType = node.target?.staticType ?? _cascadeTargetType(node);
    if (targetType?.nullabilitySuffix != NullabilitySuffix.question) return;

    rule.reportAtNode(node.methodName);
  }
}

DartType? _cascadeTargetType(MethodInvocation node) {
  for (AstNode? current = node.parent; current != null; current = current.parent) {
    if (current is CascadeExpression) return current.target.staticType;
  }
  return null;
}
