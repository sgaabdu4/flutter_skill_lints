import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../disposal_utils.dart';

/// Warns when a `late` field is disposed from `dispose()`.
class AvoidDisposingLateFields extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_disposing_late_fields',
    'Avoid disposing late field in dispose().',
    correctionMessage:
        'Initialize disposable fields eagerly or make disposal conditional before calling cleanup.',
  );

  AvoidDisposingLateFields()
    : super(
        name: 'avoid_disposing_late_fields',
        description: 'Warns when dispose() cleans up a field declared with late.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidDisposingLateFields rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return;

    final lateFields = <String>{};
    for (final field in body.members.whereType<FieldDeclaration>()) {
      if (field.isStatic || !field.fields.isLate) continue;
      for (final variable in field.fields.variables) {
        lateFields.add(variable.name.lexeme);
      }
    }
    if (lateFields.isEmpty) return;

    for (final method in body.members.whereType<MethodDeclaration>()) {
      if (method.name.lexeme != 'dispose') continue;

      final collector = _DisposedLateFieldCollector(lateFields);
      method.body.visitChildren(collector);
      for (final invocation in collector.invocations) {
        rule.reportAtNode(invocation);
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
