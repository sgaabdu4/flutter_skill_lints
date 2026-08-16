import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when a `ListView` uses `shrinkWrap: true`.
///
/// Using `shrinkWrap` in lists is expensive performance-wise because the
/// list must be fully laid out to determine its size. Prefer using slivers
/// via `CustomScrollView` with `SliverList` for better performance.
class AvoidShrinkWrapInLists extends InstanceAndMethodInvocationRule {
  static const LintCode code = LintCode(
    'avoid_shrink_wrap_in_lists',
    'Avoid using shrinkWrap in ListView.',
    correctionMessage: 'Use CustomScrollView with SliverList or constrain the list height.',
  );

  AvoidShrinkWrapInLists()
    : super(
        code: code,
        name: 'avoid_shrink_wrap_in_lists',
        description:
            'Warns when a ListView uses shrinkWrap: true, which is expensive performance-wise.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends InstanceAndMethodVisitor {
  final AvoidShrinkWrapInLists rule;

  _Visitor(this.rule);

  static const _listViewChecker = TypeChecker.fromName('ListView', packageName: 'flutter');

  @override
  void checkInstanceOrMethod(DartType? staticType, ArgumentList argumentList, AstNode node) {
    if (staticType == null || !_listViewChecker.isExactlyType(staticType)) {
      return;
    }

    for (final arg in argumentList.arguments.whereType<NamedArgument>()) {
      if (arg.name.lexeme == 'shrinkWrap') {
        if (arg.argumentExpression case BooleanLiteral(value: true)) {
          rule.reportAtNode(arg);
          return;
        }
      }
    }
  }
}
