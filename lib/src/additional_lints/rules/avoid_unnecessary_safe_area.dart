import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when a `SafeArea` has no enabled edges or directly wraps another one.
class AvoidUnnecessarySafeArea extends InstanceAndMethodInvocationRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_safe_area',
    'Avoid unnecessary SafeArea widgets.',
    correctionMessage: 'Remove the redundant SafeArea.',
  );

  AvoidUnnecessarySafeArea()
    : super(
        code: code,
        name: 'avoid_unnecessary_safe_area',
        description: 'Warns when SafeArea has no enabled edges or directly wraps another SafeArea.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends InstanceAndMethodVisitor {
  _Visitor(this.rule);

  final AvoidUnnecessarySafeArea rule;

  static const _safeAreaChecker = TypeChecker.fromName('SafeArea', packageName: 'flutter');

  @override
  void checkInstanceOrMethod(DartType? staticType, ArgumentList argumentList, AstNode reportNode) {
    if (staticType == null || !_safeAreaChecker.isExactlyType(staticType)) {
      return;
    }

    if (_allEdgesDisabled(argumentList) || _hasSafeAreaChild(argumentList)) {
      rule.reportAtNode(reportNode);
    }
  }

  static bool _allEdgesDisabled(ArgumentList argumentList) {
    const edgeParameters = {'left', 'top', 'right', 'bottom'};
    final edges = <String, bool>{};

    for (final argument in argumentList.arguments.whereType<NamedArgument>()) {
      final name = argument.name.lexeme;
      if (!edgeParameters.contains(name)) continue;

      final expression = argument.argumentExpression;
      if (expression is! BooleanLiteral) return false;
      edges[name] = expression.value;
    }

    return edgeParameters.every((name) => edges[name] == false);
  }

  static bool _hasSafeAreaChild(ArgumentList argumentList) {
    final child = argumentList.arguments
        .whereType<NamedArgument>()
        .firstWhereOrNull((argument) => argument.name.lexeme == 'child')
        ?.argumentExpression;
    final childType = child?.staticType;
    return childType != null && _safeAreaChecker.isExactlyType(childType);
  }
}
