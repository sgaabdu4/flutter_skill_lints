import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Reports when a record contains another record field.
class AvoidNestedRecords extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_nested_records',
    'Avoid nested records.',
    correctionMessage: 'Use a named type for the nested value shape.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidNestedRecords()
    : super(
        name: 'avoid_nested_records',
        description: 'Reports when a record contains another record field.',
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

  final AvoidNestedRecords rule;

  @override
  void visitRecordLiteral(RecordLiteral node) {
    for (final field in node.fields) {
      final expression = field is NamedExpression ? field.expression : field;
      if (expression is RecordLiteral) {
        rule.reportAtNode(expression);
      }
    }
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    for (final field in node.positionalFields) {
      if (field.type is RecordTypeAnnotation) {
        rule.reportAtNode(field.type);
      }
    }

    final namedFields = node.namedFields;
    if (namedFields == null) return;

    for (final field in namedFields.fields) {
      if (field.type is RecordTypeAnnotation) {
        rule.reportAtNode(field.type);
      }
    }
  }
}
