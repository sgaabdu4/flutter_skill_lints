import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../ast_node_analysis.dart';

/// Warns when `Intl.message` placeholders omit examples.
final class PreferProvidingIntlExamples extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_providing_intl_examples',
    'Provide Intl.message examples for placeholders.',
    correctionMessage: 'Add a non-empty examples map for the placeholders.',
    severity: DiagnosticSeverity.INFO,
  );

  PreferProvidingIntlExamples()
    : super(
        name: 'prefer_providing_intl_examples',
        description: 'Warns when Intl.message placeholders omit examples.',
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

  final PreferProvidingIntlExamples rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isIntlMessage(node)) return;

    final placeholders = _namedArgument(node, 'placeholders')?.expression;
    if (placeholders is! SetOrMapLiteral || !_isNonEmptyMap(placeholders)) return;

    final examples = _namedArgument(node, 'examples')?.expression;
    if (examples is SetOrMapLiteral && _isNonEmptyMap(examples)) return;

    rule.reportAtNode(placeholders);
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

bool _isNonEmptyMap(SetOrMapLiteral expression) {
  return expression.isMap && expression.elements.whereType<MapLiteralEntry>().isNotEmpty;
}
