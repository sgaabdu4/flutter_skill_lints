import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when an extension type exposes its representation field publicly.
class PreferPrivateExtensionTypeField extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_private_extension_type_field',
    'Prefer private extension type representation fields.',
    correctionMessage:
        'Prefix the representation field name with _ and expose intentional API through members.',
  );

  PreferPrivateExtensionTypeField()
    : super(
        name: 'prefer_private_extension_type_field',
        description: 'Warns when extension type representation fields are public.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addExtensionTypeDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferPrivateExtensionTypeField rule;

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    final parameter = node.primaryConstructor.formalParameters.parameters.singleOrNull;
    if (parameter is! SimpleFormalParameter) return;

    final name = parameter.name;
    if (name == null || name.lexeme.startsWith('_')) return;

    rule.reportAtToken(name);
  }
}
