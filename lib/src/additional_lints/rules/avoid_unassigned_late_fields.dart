import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/unassigned_field_analysis.dart';

/// Warns when a `late` instance field is not assigned by each local
/// generative constructor.
final class AvoidUnassignedLateFields extends ClassDeclarationRule {
  static const LintCode code = LintCode(
    'avoid_unassigned_late_fields',
    'Late field is not assigned in every constructor.',
    correctionMessage: 'Assign the field in every constructor or give it an initializer.',
  );

  AvoidUnassignedLateFields()
    : super(
        name: 'avoid_unassigned_late_fields',
        description: 'Warns when late fields can be left unassigned after construction.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUnassignedLateFields rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return;

    final unassigned = findUnassignedFields(body, includeField: (fields) => fields.isLate);
    for (final token in unassigned.values) {
      rule.reportAtToken(token);
    }
  }
}
