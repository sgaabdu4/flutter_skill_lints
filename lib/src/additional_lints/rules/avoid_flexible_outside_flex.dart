import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when a Flexible or Expanded widget is used outside a Flex widget.
///
/// Flexible and Expanded widgets should only be used as direct children of
/// Row, Column, or Flex widgets. Using them elsewhere has no effect and
/// indicates a structural issue in the widget tree.
class AvoidFlexibleOutsideFlex extends InstanceCreationExpressionRule {
  static const LintCode code = LintCode(
    'avoid_flexible_outside_flex',
    '{0} should only be used as a direct child of Row, Column, or Flex.',
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

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorType = node.constructorName.type;
    final element = constructorType.element;
    if (element == null) return;

    // Only interested in Flexible / Expanded
    if (!_flexibleChecker.isSuperOf(element)) return;

    // Walk up the AST to find the nearest parent InstanceCreationExpression
    // that represents a widget constructor. If it's a Flex widget, this is
    // valid. If not (or if there is no parent widget), report the lint.
    if (_isDirectChildOfFlex(node)) return;

    final widgetName = constructorType.name.lexeme;
    rule.reportAtNode(node.constructorName, arguments: [widgetName]);
  }

  /// Checks if [node] is a direct child in a Flex widget's children list
  /// or child parameter.
  static bool _isDirectChildOfFlex(InstanceCreationExpression node) {
    final argumentList = _directWidgetArgumentList(node);
    return argumentList != null && _isFlexArgumentList(argumentList);
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

  static bool _isFlexArgumentList(ArgumentList argumentList) {
    final parent = argumentList.parent;
    if (parent is! InstanceCreationExpression) return false;
    final element = parent.constructorName.type.element;
    return element != null && _flexChecker.isSuperOf(element);
  }
}
