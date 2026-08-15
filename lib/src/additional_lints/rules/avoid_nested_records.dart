import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Reports when a record contains another record field.
class AvoidNestedRecords extends RecordRule {
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
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidNestedRecords rule;

  @override
  void visitRecordLiteral(RecordLiteral node) {
    for (final field in node.fields) {
      final expression = field.fieldExpression;
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
