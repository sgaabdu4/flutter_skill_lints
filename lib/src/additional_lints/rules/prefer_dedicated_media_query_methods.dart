import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Suggests dedicated MediaQuery accessors for common single-property reads.
final class PreferDedicatedMediaQueryMethods extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_dedicated_media_query_methods',
    'Prefer the dedicated MediaQuery method for `{0}`.',
    correctionMessage: 'Use `MediaQuery.{0}Of(context)` instead.',
    severity: DiagnosticSeverity.INFO,
  );

  PreferDedicatedMediaQueryMethods()
    : super(
        name: 'prefer_dedicated_media_query_methods',
        description: 'Flags MediaQuery.of(context).size, padding, and viewInsets reads.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addPropertyAccess(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferDedicatedMediaQueryMethods rule;

  static const _properties = {'size', 'padding', 'viewInsets'};

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final propertyName = node.propertyName.name;
    if (!_properties.contains(propertyName)) return;

    final target = node.target;
    if (target is! MethodInvocation) return;
    if (!_isMediaQueryOf(target)) return;

    rule.reportAtNode(node.propertyName, arguments: [propertyName]);
  }

  static bool _isMediaQueryOf(MethodInvocation node) {
    if (node.methodName.name != 'of') return false;
    if (node.argumentList.arguments.length != 1) return false;

    return switch (node.target) {
      SimpleIdentifier(name: 'MediaQuery') => true,
      _ => false,
    };
  }
}
