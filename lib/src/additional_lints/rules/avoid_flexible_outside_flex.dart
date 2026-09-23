import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when a Flexible or Expanded widget is used outside a Flex widget.
///
/// Stateless and stateful widgets may compose the path to the Flex parent.
/// Report only a proven incompatible render-object parent; a constructor's
/// source nesting alone cannot establish an extracted widget's runtime parent.
class AvoidFlexibleOutsideFlex extends AnalysisRule {
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
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addInstanceCreationExpression(this, _Visitor(this, context.typeSystem));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidFlexibleOutsideFlex rule;

  _Visitor(this.rule, this.typeSystem);

  final TypeSystem typeSystem;

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
  static const _containerChecker = TypeChecker.fromName('Container', packageName: 'flutter');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorType = node.constructorName.type;
    final element = constructorType.element;
    if (element == null) return;

    // Only interested in Flexible / Expanded
    if (!_flexibleChecker.isSuperOf(element)) return;

    if (!_hasIncompatibleParent(node)) return;

    final widgetName = constructorType.name.lexeme;
    rule.reportAtNode(node.constructorName, arguments: [widgetName]);
  }

  bool _hasIncompatibleParent(InstanceCreationExpression node) {
    AstNode? parent = _directWidgetArgumentList(node)?.parent;
    while (parent is InstanceCreationExpression) {
      final element = parent.constructorName.type.element;
      if (element == null || _flexChecker.isSuperOf(element)) return false;
      if (_renderObjectChecker.isSuperOf(element) || _containerAddsRenderParent(parent)) {
        return true;
      }
      final type = parent.staticType;
      if (type == null || !_containerChecker.isExactlyType(type)) return false;
      parent = _directWidgetArgumentList(parent)?.parent;
    }
    return false;
  }

  bool _containerAddsRenderParent(InstanceCreationExpression parent) {
    final type = parent.staticType;
    if (type == null || !_containerChecker.isExactlyType(type)) return false;
    const renderProperties = {
      'alignment',
      'padding',
      'color',
      'decoration',
      'foregroundDecoration',
      'width',
      'height',
      'constraints',
      'margin',
      'transform',
    };
    return parent.argumentList.arguments.whereType<NamedArgument>().any((argument) {
      final valueType = argument.argumentExpression.staticType;
      return renderProperties.contains(argument.name.lexeme) &&
          valueType != null &&
          typeSystem.isNonNullable(valueType);
    });
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
