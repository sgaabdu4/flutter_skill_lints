import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when a Future is explicitly ignored with `.ignore()`.
class AvoidFutureIgnore extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'avoid_future_ignore',
    'Avoid ignoring a Future with ignore().',
    correctionMessage: 'Handle the Future result or use unawaited() with an explicit reason.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidFutureIgnore()
    : super(
        code: code,
        name: 'avoid_future_ignore',
        description: 'Warns when Future.ignore() is used.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidFutureIgnore rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'ignore') return;
    if (node.argumentList.arguments.isNotEmpty) return;
    if (!isFutureLikeType(node.target?.staticType)) return;
    rule.reportAtNode(node.methodName);
  }
}
