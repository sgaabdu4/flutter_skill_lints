import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../ast_node_analysis.dart';

/// Warns when `Intl.message` omits a description.
final class PreferProvidingIntlDescription extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_providing_intl_description',
    'Provide an Intl.message description.',
    correctionMessage: 'Add a desc argument that explains the message context.',
    severity: DiagnosticSeverity.INFO,
  );

  PreferProvidingIntlDescription()
    : super(
        name: 'prefer_providing_intl_description',
        description: 'Warns when Intl.message calls omit desc.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferProvidingIntlDescription rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isIntlMessage(node)) return;

    final desc = _namedArgument(node, 'desc');
    if (desc != null && desc.expression is! NullLiteral) return;

    rule.reportAtNode(node.methodName);
  }
}

bool _isIntlMessage(MethodInvocation node) {
  final target = node.target;
  return target is SimpleIdentifier && target.name == 'Intl' && node.methodName.name == 'message';
}

NamedExpression? _namedArgument(MethodInvocation node, String name) {
  for (final argument in node.argumentList.arguments.whereType<NamedExpression>()) {
    if (argument.name.lexeme == name) return argument;
  }

  return null;
}
