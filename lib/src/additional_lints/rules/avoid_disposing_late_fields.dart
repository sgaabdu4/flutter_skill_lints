import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/disposal_utils.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/unassigned_field_analysis.dart';

/// Warns when a late field is disposed without guaranteed initialization.
class AvoidDisposingLateFields extends ClassDeclarationCheckRule {
  static const LintCode code = LintCode(
    'avoid_disposing_late_fields',
    'Late field may be uninitialized when dispose() calls its cleanup.',
    correctionMessage: 'Initialize the field in State.initState or eagerly before calling cleanup.',
  );

  AvoidDisposingLateFields()
    : super(
        name: 'avoid_disposing_late_fields',
        description:
            'Warns when dispose() cleans up a late field without guaranteed initialization.',
        code: code,
      );

  @override
  void checkClassDeclaration(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return;

    final lateFields = <String>{
      for (final field in body.members.whereType<FieldDeclaration>())
        if (!field.isStatic && field.fields.isLate)
          for (final variable in field.fields.variables)
            if (variable.initializer == null) variable.name.lexeme,
    }..removeAll(initializedFlutterStateFields(node));
    if (lateFields.isEmpty) return;

    for (final method in body.members.whereType<MethodDeclaration>()) {
      if (method.name.lexeme != 'dispose') continue;

      final collector = _DisposedLateFieldCollector(lateFields);
      method.body.visitChildren(collector);
      for (final invocation in collector.invocations) {
        reportAtNode(invocation);
      }
    }
  }
}

final class _DisposedLateFieldCollector extends RecursiveAstVisitor<void> {
  _DisposedLateFieldCollector(this.lateFields);

  final Set<String> lateFields;
  final List<MethodInvocation> invocations = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!cleanupMethods.contains(node.methodName.name)) {
      super.visitMethodInvocation(node);
      return;
    }

    final target = node.realTarget;
    final fieldName = switch (target) {
      SimpleIdentifier(:final name) => name,
      PropertyAccess(target: ThisExpression(), :final propertyName) => propertyName.name,
      _ => null,
    };

    if (fieldName != null && lateFields.contains(fieldName)) {
      invocations.add(node);
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
