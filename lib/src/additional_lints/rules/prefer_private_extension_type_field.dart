import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when an extension type exposes its representation field publicly.
class PreferPrivateExtensionTypeField extends GeneratedExtensionTypeDeclarationCheckRule {
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
        code: code,
      );

  @override
  void checkExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    final parameter = extensionTypeRepresentationParameter(node);
    if (parameter == null) return;

    final name = parameter.name;
    if (name == null || name.lexeme.startsWith('_')) return;

    reportAtToken(name);
  }
}
