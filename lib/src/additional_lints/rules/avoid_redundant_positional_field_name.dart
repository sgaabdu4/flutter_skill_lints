import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when positional record type fields include redundant names.
class AvoidRedundantPositionalFieldName extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_redundant_positional_field_name',
    'Avoid redundant positional record field names.',
    correctionMessage: 'Remove the positional field name or make the field named.',
  );

  AvoidRedundantPositionalFieldName()
    : super(
        name: 'avoid_redundant_positional_field_name',
        description: 'Warns when positional record type fields include redundant names.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addRecordTypeAnnotation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidRedundantPositionalFieldName rule;

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    for (final field in node.positionalFields) {
      final name = field.name;
      if (name != null) {
        rule.reportAtToken(name);
      }
    }
  }
}
