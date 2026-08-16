import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when an object pattern repeats a field name that shorthand can imply.
class AvoidExplicitPatternFieldName extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_explicit_pattern_field_name',
    'Use object-pattern field shorthand.',
    correctionMessage: "Replace 'foo: foo' with ':foo'.",
  );

  AvoidExplicitPatternFieldName()
    : super(
        name: 'avoid_explicit_pattern_field_name',
        description: 'Warns when object patterns repeat the same explicit field and variable name.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addObjectPattern(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidExplicitPatternFieldName rule;

  @override
  void visitObjectPattern(ObjectPattern node) {
    for (final field in node.fields) {
      if (_hasRedundantFieldName(field)) {
        rule.reportAtNode(field.name!);
      }
    }
  }

  bool _hasRedundantFieldName(PatternField field) {
    final explicitName = field.name?.name?.lexeme;
    if (explicitName == null) return false;

    final pattern = field.pattern;
    if (pattern is! DeclaredVariablePattern) return false;
    if (pattern.keyword != null || pattern.type != null) return false;

    return explicitName == pattern.name.lexeme;
  }
}
