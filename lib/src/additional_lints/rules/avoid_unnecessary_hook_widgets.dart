import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/hook_detection.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a HookWidget does not use any hooks in the build method.
///
/// A widget without hook calls does not need hook lifecycle wiring, so a
/// StatelessWidget is clearer.
class AvoidUnnecessaryHookWidgets extends ClassAndInstanceCreationCheckRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_hook_widgets',
    'This HookWidget does not use hooks.',
    correctionMessage: 'Convert it to a StatelessWidget because no hooks are used.',
  );

  AvoidUnnecessaryHookWidgets()
    : super(
        name: 'avoid_unnecessary_hook_widgets',
        description: 'Warns when HookWidget does not use hooks and can be a StatelessWidget.',
        code: code,
      );

  @override
  void checkClassDeclaration(ClassDeclaration node) {
    final superclass = node.extendsClause?.superclass;
    if (superclass == null) return;
    final buildMethod = hookWidgetBuildMethod(node);
    if (buildMethod == null) return;

    final hookExpressions = getAllInnerHookExpressions(buildMethod.body);
    if (hookExpressions.isEmpty) {
      reportAtNode(superclass);
    }
  }

  @override
  void checkInstanceCreationExpression(InstanceCreationExpression node) {
    final body = maybeHookBuilderBody(node);
    if (body == null) return;

    final hookExpressions = getAllInnerHookExpressions(body);
    if (hookExpressions.isEmpty) {
      reportAtNode(node.constructorName);
    }
  }
}
