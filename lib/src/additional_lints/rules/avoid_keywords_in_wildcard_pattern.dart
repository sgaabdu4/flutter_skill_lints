import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a wildcard pattern is written with a redundant `var` or `final`.
class AvoidKeywordsInWildcardPattern extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_keywords_in_wildcard_pattern',
    "Avoid 'var' and 'final' in wildcard patterns.",
    correctionMessage: 'Remove the keyword from the wildcard pattern.',
  );

  AvoidKeywordsInWildcardPattern()
    : super(
        name: 'avoid_keywords_in_wildcard_pattern',
        description: "Warns when wildcard patterns use redundant 'var' or 'final' keywords.",
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addWildcardPattern(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidKeywordsInWildcardPattern rule;

  @override
  void visitWildcardPattern(WildcardPattern node) {
    final keyword = node.keyword;
    if (keyword != null) {
      rule.reportAtToken(keyword);
    }
  }
}
