import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Reports positional record fields.
///
/// Records in this profile must use named fields so call sites remain readable
/// and can move to a typedef without changing field access semantics.
final class AvoidPositionalRecordFields extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_positional_record_fields',
    'Avoid positional record fields.',
    correctionMessage: 'Use a named record shape such as ({Type fieldName}).',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidPositionalRecordFields()
    : super(
        name: 'avoid_positional_record_fields',
        description: 'Reports positional fields in record literals and record type annotations.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    final visitor = _Visitor(this);
    registry
      ..addRecordLiteral(this, visitor)
      ..addRecordTypeAnnotation(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidPositionalRecordFields rule;

  @override
  void visitRecordLiteral(RecordLiteral node) {
    for (final field in node.fields) {
      if (field is NamedExpression) continue;
      rule.reportAtNode(field);
    }
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    for (final field in node.positionalFields) {
      rule.reportAtNode(field);
    }
  }
}
