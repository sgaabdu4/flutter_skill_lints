import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

final _buildCheckMethodDeclarationPattern = RegExp(r'^_build[A-Z][A-Za-z0-9_]*$');

/// Avoid private _buildXxx() widget helper methods.
/// helper method.
final class AvoidWidgetBuildHelpers extends GeneratedMethodDeclarationCheckRule {
  static const LintCode code = LintCode(
    'avoid_widget_build_helpers',
    'Avoid private _buildXxx() widget helper methods.',
    correctionMessage: 'Extract a named widget class instead of a build helper method.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidWidgetBuildHelpers()
    : super(
        name: 'avoid_widget_build_helpers',
        description: 'Bans private _buildXxx helper methods.',
        code: code,
      );

  @override
  @override
  void checkMethodDeclaration(MethodDeclaration node) {
    if (_buildCheckMethodDeclarationPattern.hasMatch(node.name.lexeme)) {
      reportAtToken(node.name);
    }
  }
}
