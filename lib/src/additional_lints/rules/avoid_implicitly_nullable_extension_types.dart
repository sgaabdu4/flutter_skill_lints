import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when an extension type uses an unconstrained representation type
/// parameter.
class AvoidImplicitlyNullableExtensionTypes extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_implicitly_nullable_extension_types',
    'Avoid implicitly nullable extension type representations.',
    correctionMessage:
        'Add a non-nullable bound such as `extends Object` or use a concrete non-nullable representation type.',
  );

  AvoidImplicitlyNullableExtensionTypes()
    : super(
        name: 'avoid_implicitly_nullable_extension_types',
        description:
            'Warns when extension type representation fields use unconstrained type parameters.',
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

  final AvoidImplicitlyNullableExtensionTypes rule;

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    final parameter = node.primaryConstructor.formalParameters.parameters.singleOrNull;
    if (parameter is! SimpleFormalParameter) return;

    final representationType = parameter.type;
    if (representationType is! NamedType) return;

    final element = representationType.element;
    if (element is! TypeParameterElement || element.bound != null) return;

    rule.reportAtNode(representationType);
  }
}
