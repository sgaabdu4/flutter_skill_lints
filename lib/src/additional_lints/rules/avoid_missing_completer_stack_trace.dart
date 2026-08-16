import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Requires `Completer.completeError` calls to pass a stack trace.
class AvoidMissingCompleterStackTrace extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'avoid_missing_completer_stack_trace',
    'Pass a stack trace to Completer.completeError.',
    correctionMessage: 'Call completeError(error, stackTrace) so async errors keep their origin.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidMissingCompleterStackTrace()
    : super(
        code: code,
        name: 'avoid_missing_completer_stack_trace',
        description: 'Requires Completer.completeError calls to include a stack trace.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  static const _completerChecker = TypeChecker.fromUrl('dart:async#Completer');

  final AvoidMissingCompleterStackTrace rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'completeError') return;
    if (node.argumentList.arguments.length > 1) return;
    if (!_isCompleterTarget(node)) return;

    rule.reportAtNode(node.methodName);
  }

  bool _isCompleterTarget(MethodInvocation node) {
    final targetType = node.target?.staticType;
    if (targetType != null && _completerChecker.isAssignableFromType(targetType)) {
      return true;
    }

    final parent = node.parent;
    if (parent is CascadeExpression) {
      final cascadeType = parent.target.staticType;
      return cascadeType != null && _completerChecker.isAssignableFromType(cascadeType);
    }

    return false;
  }
}
