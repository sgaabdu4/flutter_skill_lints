import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when `any(named:)` disagrees with the named argument it matches.
final class PreferCorrectAnyMatcher extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'prefer_correct_any_matcher',
    "Match any(named:) to the named argument's name.",
    correctionMessage: 'Use the same name as the surrounding named argument.',
  );

  PreferCorrectAnyMatcher()
    : super(
        code: code,
        name: 'prefer_correct_any_matcher',
        description: 'Warns when any(named:) has the wrong name in when()/verify() calls.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferCorrectAnyMatcher rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'any') return;
    if (!_isInsideMocktailStubOrVerify(node)) return;

    final actualName = _surroundingNamedArgument(node);
    if (actualName == null) return;

    final matcherName = _matcherNamedValue(node);
    if (matcherName == null || matcherName == actualName) return;

    rule.reportAtNode(node.methodName);
  }

  static String? _surroundingNamedArgument(AstNode node) {
    final parent = node.parent;
    if (parent is NamedArgument && parent.argumentExpression == node) {
      return parent.name.lexeme;
    }
    return null;
  }

  static String? _matcherNamedValue(MethodInvocation node) {
    for (final argument in node.argumentList.arguments.whereType<NamedArgument>()) {
      if (argument.name.lexeme != 'named') continue;
      final expression = argument.argumentExpression;
      if (expression is SimpleStringLiteral) return expression.value;
      if (expression is AdjacentStrings) return null;
    }
    return null;
  }

  static bool _isInsideMocktailStubOrVerify(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is MethodInvocation) {
        final name = current.methodName.name;
        if (name == 'when' || name == 'verify' || name == 'verifyNever') {
          return true;
        }
      }
      current = current.parent;
    }
    return false;
  }
}
