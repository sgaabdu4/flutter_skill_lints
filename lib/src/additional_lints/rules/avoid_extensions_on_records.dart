import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Reports when an extension is declared on a record type.
class AvoidExtensionsOnRecords extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_extensions_on_records',
    'Avoid extensions on record types.',
    correctionMessage: 'Use a named type when behavior belongs with a value shape.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidExtensionsOnRecords()
    : super(
        name: 'avoid_extensions_on_records',
        description: 'Reports when extension declarations target record types.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addExtensionDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidExtensionsOnRecords rule;

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    final extendedType = node.onClause?.extendedType;
    if (extendedType is RecordTypeAnnotation) {
      rule.reportAtNode(extendedType);
    }
  }
}
