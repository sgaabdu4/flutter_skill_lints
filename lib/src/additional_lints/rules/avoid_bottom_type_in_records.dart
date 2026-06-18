import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a record field is explicitly typed as `Never`.
class AvoidBottomTypeInRecords extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_bottom_type_in_records',
    'Avoid bottom types in records.',
    correctionMessage: 'Use a named result type or model the unreachable state outside the record.',
  );

  AvoidBottomTypeInRecords()
    : super(
        name: 'avoid_bottom_type_in_records',
        description: 'Warns when record fields are explicitly typed as Never.',
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

  final AvoidBottomTypeInRecords rule;

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    for (final field in node.positionalFields) {
      _checkType(field.type);
    }

    final namedFields = node.namedFields;
    if (namedFields == null) return;

    for (final field in namedFields.fields) {
      _checkType(field.type);
    }
  }

  void _checkType(TypeAnnotation type) {
    if (type is NamedType && type.name.lexeme == 'Never') {
      rule.reportAtNode(type);
    }
  }
}
