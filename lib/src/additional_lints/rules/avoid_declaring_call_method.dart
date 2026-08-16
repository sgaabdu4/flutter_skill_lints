import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Reports when a type declares a `call` method.
class AvoidDeclaringCallMethod extends GeneratedMethodDeclarationCheckRule {
  static const LintCode code = LintCode(
    'avoid_declaring_call_method',
    'Avoid declaring call methods.',
    correctionMessage: 'Use an explicitly named method instead.',
  );

  AvoidDeclaringCallMethod()
    : super(
        name: 'avoid_declaring_call_method',
        description: 'Reports when classes, mixins, or extension types declare call methods.',
        code: code,
      );

  @override
  @override
  void checkMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'call') return;

    if (node.thisOrAncestorOfType<ClassDeclaration>() != null ||
        node.thisOrAncestorOfType<MixinDeclaration>() != null ||
        node.thisOrAncestorOfType<ExtensionTypeDeclaration>() != null) {
      reportAtToken(node.name);
    }
  }
}
