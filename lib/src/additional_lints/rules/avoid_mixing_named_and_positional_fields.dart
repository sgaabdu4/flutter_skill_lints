import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Reports when a record mixes positional and named fields.
class AvoidMixingNamedAndPositionalFields extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_mixing_named_and_positional_fields',
    'Avoid mixing named and positional record fields.',
    correctionMessage: 'Use either named fields or positional fields consistently.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidMixingNamedAndPositionalFields()
    : super(
        name: 'avoid_mixing_named_and_positional_fields',
        description: 'Reports when a record mixes named and positional fields.',
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

  final AvoidMixingNamedAndPositionalFields rule;

  @override
  void visitRecordLiteral(RecordLiteral node) {
    var hasNamed = false;
    var hasPositional = false;

    for (final field in node.fields) {
      if (field is NamedExpression) {
        hasNamed = true;
      } else {
        hasPositional = true;
      }
    }

    if (hasNamed && hasPositional) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    final hasNamed = node.namedFields?.fields.isNotEmpty ?? false;
    if (hasNamed && node.positionalFields.isNotEmpty) {
      rule.reportAtNode(node);
    }
  }
}
