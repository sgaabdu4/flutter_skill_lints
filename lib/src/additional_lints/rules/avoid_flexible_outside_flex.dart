import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when a Flexible or Expanded widget is used outside a Flex widget.
///
/// Stateless and stateful widgets may compose the path to the Flex parent.
/// Report only a proven incompatible render-object parent; a constructor's
/// source nesting alone cannot establish an extracted widget's runtime parent.
class AvoidFlexibleOutsideFlex extends InstanceCreationExpressionRule {
  static const LintCode code = LintCode(
    'avoid_flexible_outside_flex',
    '{0} has a non-Flex render-object parent.',
    correctionMessage: 'Move {0} inside a Row, Column, or Flex, or remove the wrapper.',
  );

  AvoidFlexibleOutsideFlex()
    : super(
        name: 'avoid_flexible_outside_flex',
        description:
            'Warns when a Flexible or Expanded widget is used outside '
            'a Flex widget.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidFlexibleOutsideFlex rule;

  _Visitor(this.rule);

  static const _flexibleChecker = TypeChecker.any([
    TypeChecker.fromName('Flexible', packageName: 'flutter'),
    TypeChecker.fromName('Expanded', packageName: 'flutter'),
  ]);

  static const _flexChecker = TypeChecker.any([
    TypeChecker.fromName('Row', packageName: 'flutter'),
    TypeChecker.fromName('Column', packageName: 'flutter'),
    TypeChecker.fromName('Flex', packageName: 'flutter'),
  ]);

  static const _renderObjectChecker = TypeChecker.fromName(
    'RenderObjectWidget',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorType = node.constructorName.type;
    final element = constructorType.element;
    if (element == null) return;

    // Only interested in Flexible / Expanded
    if (!_flexibleChecker.isSuperOf(element)) return;

    final parent = _directWidgetArgumentList(node)?.parent;
    if (parent is! InstanceCreationExpression) return;
    final parentElement = parent.constructorName.type.element;
    if (parentElement == null ||
        _flexChecker.isSuperOf(parentElement) ||
        !_renderObjectChecker.isSuperOf(parentElement)) {
      return;
    }

    final widgetName = constructorType.name.lexeme;
    rule.reportAtNode(node.constructorName, arguments: [widgetName]);
  }

  static ArgumentList? _directWidgetArgumentList(InstanceCreationExpression node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ListLiteral) {
        current = current.parent;
        continue;
      }
      if (current is NamedArgument) {
        current = current.parent;
        continue;
      }
      if (current is ArgumentList) {
        return current;
      }
      if (current is FunctionExpression ||
          current is FunctionDeclaration ||
          current is MethodDeclaration) {
        return null;
      }
      current = current.parent;
    }
    return null;
  }
}
