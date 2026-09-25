import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when an extension type exposes its representation field publicly
/// under any name other than `value`.
///
/// The skill's typed IDs expose `value` (dart-patterns-records.md,
/// collections-helpers.md, value-objects.md "`value` getter"), so a public
/// `value` field is allowed; other public names must be private.
class PreferPrivateExtensionTypeField extends GeneratedExtensionTypeDeclarationCheckRule {
  static const LintCode code = LintCode(
    'prefer_private_extension_type_field',
    'Extension type representation fields must be private or named value.',
    correctionMessage:
        'Rename the representation field to value (the typed-ID convention), or prefix it with _ '
        'and expose intentional API through members.',
  );

  PreferPrivateExtensionTypeField()
    : super(
        name: 'prefer_private_extension_type_field',
        description:
            'Warns when an extension type representation field is public and not named value.',
        code: code,
      );

  @override
  void checkExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    final parameter = extensionTypeRepresentationParameter(node);
    if (parameter == null) return;

    final name = parameter.name;
    if (name == null || name.lexeme.startsWith('_') || name.lexeme == 'value') return;

    reportAtToken(name);
  }
}
