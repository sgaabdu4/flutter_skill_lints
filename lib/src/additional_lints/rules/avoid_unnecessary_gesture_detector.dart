import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when a `GestureDetector` widget is created without any event handler
/// callbacks, making it functionally useless.
class AvoidUnnecessaryGestureDetector extends InstanceAndMethodInvocationRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_gesture_detector',
    "This 'GestureDetector' has no event handlers.",
    correctionMessage: 'Add a gesture callback such as onTap, or remove the inert GestureDetector.',
  );

  AvoidUnnecessaryGestureDetector()
    : super(
        code: code,
        name: 'avoid_unnecessary_gesture_detector',
        description: 'Warns when a GestureDetector has no event handler callbacks.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryGestureDetector rule;

  _Visitor(this.rule);

  static const _gestureDetectorChecker = TypeChecker.fromName(
    'GestureDetector',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.constructorName.type.element;
    if (element == null || !_gestureDetectorChecker.isExactly(element)) return;

    if (!_hasEventHandler(node.argumentList)) {
      rule.reportAtNode(node.constructorName);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final type = node.staticType;
    if (type == null || !_gestureDetectorChecker.isExactlyType(type)) return;

    if (!_hasEventHandler(node.argumentList)) {
      rule.reportAtNode(node.methodName);
    }
  }

  static bool _hasEventHandler(ArgumentList argumentList) {
    return argumentList.arguments.whereType<NamedArgument>().any(
      (arg) => arg.name.lexeme.startsWith('on'),
    );
  }
}
