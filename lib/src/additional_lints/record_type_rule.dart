import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

abstract class RecordTypeAnnotationCheckRule extends NodeRegistrationRule {
  RecordTypeAnnotationCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  bool shouldRegister(RuleContext context) => true;

  void checkRecordTypeAnnotation(RecordTypeAnnotation node);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!shouldRegister(context)) return;
    registry.addRecordTypeAnnotation(this, _RecordTypeAnnotationCheckVisitor(this));
  }
}

abstract class GeneratedRecordTypeAnnotationCheckRule extends RecordTypeAnnotationCheckRule {
  GeneratedRecordTypeAnnotationCheckRule({
    required super.name,
    required super.description,
    required super.code,
  });

  @override
  bool shouldRegister(RuleContext context) => !isGeneratedRuleContext(context);
}

final class _RecordTypeAnnotationCheckVisitor extends SimpleAstVisitor<void> {
  const _RecordTypeAnnotationCheckVisitor(this.rule);

  final RecordTypeAnnotationCheckRule rule;

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    rule.checkRecordTypeAnnotation(node);
  }
}
