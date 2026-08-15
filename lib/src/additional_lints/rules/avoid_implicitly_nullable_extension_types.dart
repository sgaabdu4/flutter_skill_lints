import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when an extension type uses an unconstrained representation type
/// parameter.
class AvoidImplicitlyNullableExtensionTypes extends GeneratedExtensionTypeDeclarationCheckRule {
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
        code: code,
      );

  @override
  void checkExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    final parameter = extensionTypeRepresentationParameter(node);
    if (parameter == null) return;

    final representationType = parameter.type;
    if (representationType is! NamedType) return;

    final element = representationType.element;
    if (element is! TypeParameterElement || element.bound != null) return;

    reportAtNode(representationType);
  }
}
