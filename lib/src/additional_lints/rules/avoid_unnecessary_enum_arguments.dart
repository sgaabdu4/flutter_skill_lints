import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a named enum argument repeats the parameter's default value.
class AvoidUnnecessaryEnumArguments extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_enum_arguments',
    'Avoid passing an enum value that matches the parameter default.',
    correctionMessage: 'Remove the redundant argument.',
  );

  AvoidUnnecessaryEnumArguments()
    : super(
        name: 'avoid_unnecessary_enum_arguments',
        description: 'Warns when a named enum argument repeats its default value.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addNamedArgument(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUnnecessaryEnumArguments rule;

  @override
  void visitNamedArgument(NamedArgument node) {
    final parameter = node.correspondingParameter;
    if (parameter == null || !parameter.isOptionalNamed) return;

    final defaultValueCode = parameter.defaultValueCode;
    if (defaultValueCode == null) return;
    if (!_isEnumExpression(node.argumentExpression)) return;
    if (node.argumentExpression.toSource() != defaultValueCode) return;

    rule.reportAtNode(node);
  }
}

bool _isEnumExpression(Expression expression) {
  final typeElement = expression.staticType?.element;
  return typeElement is EnumElement;
}
