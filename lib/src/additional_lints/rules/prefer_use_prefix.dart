import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/hook_detection.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a function that calls hooks does not follow the `use` prefix
/// naming convention.
///
/// Custom hooks must start with `use` (or `_use` for private functions) so
/// that the hooks framework and other lint rules can identify them as hooks.
class PreferUsePrefix extends FunctionAndMethodDeclarationRule {
  static const LintCode code = LintCode(
    'prefer_use_prefix',
    "Custom hooks should start with 'use' prefix.",
    correctionMessage:
        "Rename the function to start with 'use' (or '_use' "
        'for private functions).',
  );

  PreferUsePrefix()
    : super(
        name: 'prefer_use_prefix',
        description:
            'Warns when a function that calls hooks does not '
            "follow the 'use' prefix naming convention.",
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferUsePrefix rule;

  _Visitor(this.rule);

  static final _hasUsePrefix = hookNameRegex;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _check(node.name.lexeme, node.name, node.functionExpression.body);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Skip overridden methods (e.g., build in HookWidget)
    if (hasOverrideAnnotation(node)) return;

    _check(node.name.lexeme, node.name, node.body);
  }

  void _check(String name, Token nameToken, FunctionBody body) {
    if (name == 'main') return;

    // Already has the use prefix — nothing to report
    if (_hasUsePrefix.hasMatch(name)) return;

    // Check if the function body contains hook calls
    final hookCalls = getAllInnerHookExpressions(body);
    if (hookCalls.isEmpty) return;

    rule.reportAtToken(nameToken);
  }
}
