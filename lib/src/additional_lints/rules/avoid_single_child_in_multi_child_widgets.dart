import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when multi-child widgets have only a single child.
///
/// Dedicated single-child widgets keep the widget tree simpler and avoid a
/// misleading `children` collection when only one child is present.
class AvoidSingleChildInMultiChildWidgets extends InstanceCreationExpressionRule {
  static const LintCode code = LintCode(
    'avoid_single_child_in_multi_child_widgets',
    'Avoid using {0} with a single child.',
    correctionMessage: 'Remove the {0} and achieve the same result using dedicated widgets.',
  );

  AvoidSingleChildInMultiChildWidgets()
    : super(
        name: 'avoid_single_child_in_multi_child_widgets',
        description:
            'Warns when a multi-child widget has one child and a simpler widget can express it.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidSingleChildInMultiChildWidgets rule;

  _Visitor(this.rule);

  static const _complain = [
    ('children', TypeChecker.fromName('Column', packageName: 'flutter')),
    ('children', TypeChecker.fromName('Row', packageName: 'flutter')),
    ('children', TypeChecker.fromName('Wrap', packageName: 'flutter')),
    ('children', TypeChecker.fromName('Flex', packageName: 'flutter')),
    ('children', TypeChecker.fromName('SliverList', packageName: 'flutter')),
    ('slivers', TypeChecker.fromName('SliverMainAxisGroup', packageName: 'flutter')),
    ('slivers', TypeChecker.fromName('SliverCrossAxisGroup', packageName: 'flutter')),
    ('children', TypeChecker.fromName('MultiSliver', packageName: 'sliver_tools')),
    ('', TypeChecker.fromName('SliverChildListDelegate', packageName: 'flutter')),
  ];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName.type;
    if (constructorName.element case final typeElement?) {
      final match = _complain.firstWhereOrNull((e) => e.$2.isExactly(typeElement));
      if (match == null) return;
      final children = _childrenArgument(node.argumentList, match.$1);
      if (children == null) return;
      _checkInstanceCreation(constructorName, children);
    }
  }

  static Expression? _childrenArgument(ArgumentList arguments, String name) {
    if (name.isEmpty) {
      return arguments.arguments.firstOrNull?.argumentExpression;
    }
    for (final argument in arguments.arguments) {
      if (argument is NamedArgument && argument.name.lexeme == name) {
        return argument.argumentExpression;
      }
    }
    return null;
  }

  void _checkInstanceCreation(NamedType constructorName, Expression children) {
    if (children case final ListLiteral list) {
      if (_hasSingleElement(list)) {
        rule.reportAtNode(constructorName, arguments: [constructorName.name.lexeme]);
      }
    }
  }

  bool _hasSingleElement(ListLiteral list) {
    if (list.elements.length != 1) return false;

    bool checkExpression(CollectionElement expression) {
      return switch (expression) {
        Expression() => true,
        ForElement() || MapLiteralEntry() || SpreadElement() => false,
        IfElement(:final thenElement, :final elseElement) =>
          checkExpression(thenElement) && (elseElement == null || checkExpression(elseElement)),
        NullAwareElement(:final value) => checkExpression(value),
        _ => false,
      };
    }

    return checkExpression(list.elements.first);
  }
}
