import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when an Image widget is wrapped in an Opacity widget.
///
/// The Image widget has a dedicated `opacity` parameter that is more
/// efficient than wrapping the widget in an Opacity widget.
class AvoidIncorrectImageOpacity extends InstanceAndMethodInvocationRule {
  static const LintCode code = LintCode(
    'avoid_incorrect_image_opacity',
    "Use Image's opacity parameter instead of wrapping it in an Opacity widget.",
    correctionMessage: 'Pass opacity: AlwaysStoppedAnimation(value) to the Image widget.',
  );

  AvoidIncorrectImageOpacity()
    : super(
        code: code,
        name: 'avoid_incorrect_image_opacity',
        description: "Use Image's opacity parameter instead of wrapping it in Opacity.",
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidIncorrectImageOpacity rule;

  _Visitor(this.rule);

  static const _opacityChecker = TypeChecker.fromName('Opacity', packageName: 'flutter');

  static const _imageChecker = TypeChecker.fromName('Image', packageName: 'flutter');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.constructorName.type.element;
    if (element == null || !_opacityChecker.isExactly(element)) return;

    _checkChildArgument(node.argumentList, node.constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final type = node.staticType;
    if (type == null || !_opacityChecker.isExactlyType(type)) return;

    _checkChildArgument(node.argumentList, node.methodName);
  }

  void _checkChildArgument(ArgumentList argumentList, AstNode reportNode) {
    for (final arg in argumentList.arguments.whereType<NamedArgument>()) {
      if (arg.name.lexeme == 'child') {
        final childType = arg.argumentExpression.staticType;
        if (childType != null && _imageChecker.isAssignableFromType(childType)) {
          rule.reportAtNode(reportNode);
        }
        return;
      }
    }
  }
}
