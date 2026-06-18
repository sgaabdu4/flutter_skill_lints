import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a record has more than three fields.
class AvoidLongRecords extends AnalysisRule {
  static const int maxFields = 3;

  static const LintCode code = LintCode(
    'avoid_long_records',
    'Avoid records with more than three fields.',
    correctionMessage: 'Use a named type for larger value shapes.',
  );

  AvoidLongRecords()
    : super(
        name: 'avoid_long_records',
        description: 'Warns when a record has more than three fields.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry
      ..addRecordLiteral(this, visitor)
      ..addRecordTypeAnnotation(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidLongRecords rule;

  @override
  void visitRecordLiteral(RecordLiteral node) {
    if (node.fields.length > AvoidLongRecords.maxFields) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    final namedFieldCount = node.namedFields?.fields.length ?? 0;
    final fieldCount = node.positionalFields.length + namedFieldCount;
    if (fieldCount > AvoidLongRecords.maxFields) {
      rule.reportAtNode(node);
    }
  }
}
