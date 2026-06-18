import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a record contains exactly one field.
class AvoidOneFieldRecords extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_one_field_records',
    'Avoid one-field records.',
    correctionMessage: 'Use the value directly or introduce a named type.',
  );

  AvoidOneFieldRecords()
    : super(
        name: 'avoid_one_field_records',
        description: 'Warns when a record contains exactly one field.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    final visitor = _Visitor(this);
    registry
      ..addRecordLiteral(this, visitor)
      ..addRecordPattern(this, visitor)
      ..addRecordTypeAnnotation(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidOneFieldRecords rule;

  @override
  void visitRecordLiteral(RecordLiteral node) {
    if (node.fields.length == 1) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitRecordPattern(RecordPattern node) {
    if (node.fields.length == 1) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    final namedFieldCount = node.namedFields?.fields.length ?? 0;
    final fieldCount = node.positionalFields.length + namedFieldCount;
    if (fieldCount == 1) {
      rule.reportAtNode(node);
    }
  }
}
