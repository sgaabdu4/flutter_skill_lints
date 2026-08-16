import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when controller-accepting text input widgets omit `controller`.
class AvoidMissingController extends InstanceCreationExpressionRule {
  static const LintCode code = LintCode(
    'avoid_missing_controller',
    'Pass a controller to this text input widget.',
    correctionMessage: 'Create and pass an explicit controller.',
  );

  AvoidMissingController()
    : super(
        name: 'avoid_missing_controller',
        description:
            'Warns when TextField, TextFormField, or EditableText is created '
            'without an explicit controller.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidMissingController rule;

  static const _controllerWidgetChecker = TypeChecker.any([
    TypeChecker.fromName('TextField', packageName: 'flutter'),
    TypeChecker.fromName('TextFormField', packageName: 'flutter'),
    TypeChecker.fromName('EditableText', packageName: 'flutter'),
  ]);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.constructorName.type.element;
    if (element == null || !_controllerWidgetChecker.isExactly(element)) return;
    if (_hasNamedArgument(node.argumentList, 'controller')) return;

    rule.reportAtNode(node.constructorName.type);
  }

  static bool _hasNamedArgument(ArgumentList argumentList, String name) {
    for (final argument in argumentList.arguments.whereType<NamedArgument>()) {
      if (argument.name.lexeme == name) return true;
    }
    return false;
  }
}
