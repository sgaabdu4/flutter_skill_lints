import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when `DateTime.toString()` is used for user-facing text.
class PreferDateFormat extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'prefer_date_format',
    'Prefer DateFormat for user-facing dates.',
    correctionMessage: 'Use DateFormat or a dedicated date formatting helper.',
  );

  PreferDateFormat()
    : super(
        code: code,
        name: 'prefer_date_format',
        description: 'Warns when DateTime.toString() is used for user-facing formatting.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  static const _dateTimeChecker = TypeChecker.fromUrl('dart:core#DateTime');

  final PreferDateFormat rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'toString') return;
    if (node.argumentList.arguments.isNotEmpty) return;

    final targetType = node.target?.staticType;
    if (targetType == null || !_dateTimeChecker.isExactlyType(targetType)) return;
    if (!_isUserFacingFormatting(node)) return;

    rule.reportAtNode(node.methodName);
  }
}

bool _isUserFacingFormatting(MethodInvocation node) {
  if (_isTextArgument(node)) return true;

  final interpolation = node.thisOrAncestorOfType<InterpolationExpression>();
  return interpolation != null && _isTextArgument(interpolation);
}

bool _isTextArgument(AstNode node) {
  final argumentList = node.thisOrAncestorOfType<ArgumentList>();
  if (argumentList == null) return false;
  if (!_containsNode(argumentList, node)) return false;

  final ownerName = _argumentOwnerName(argumentList);
  if (ownerName == 'Text') return true;
  if (ownerName == 'TextSpan' && _isNamedTextArgument(node)) return true;

  return false;
}

bool _isNamedTextArgument(AstNode node) {
  final namedExpression = node.thisOrAncestorOfType<NamedArgument>();
  return namedExpression != null &&
      namedExpression.name.lexeme == 'text' &&
      _containsNode(namedExpression.argumentExpression, node);
}

String _argumentOwnerName(ArgumentList argumentList) {
  final parent = argumentList.parent;
  return switch (parent) {
    InstanceCreationExpression(:final constructorName) => constructorName.type.name.lexeme,
    MethodInvocation(:final methodName) => methodName.name,
    _ => '',
  };
}

bool _containsNode(AstNode root, AstNode node) {
  AstNode? current = node;
  while (current != null) {
    if (identical(current, root)) return true;
    current = current.parent;
  }
  return false;
}
