import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/unassigned_field_analysis.dart';

/// Warns when an instance field is not assigned by each local generative
/// constructor.
final class AvoidUnassignedFields extends ClassDeclarationRule {
  static const LintCode code = LintCode(
    'avoid_unassigned_fields',
    'Field is not assigned in every constructor.',
    correctionMessage: 'Assign the field in every constructor or give it an initializer.',
  );

  AvoidUnassignedFields()
    : super(
        name: 'avoid_unassigned_fields',
        description: 'Warns when fields can be left with their implicit default value.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUnassignedFields rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return;

    final unassigned = findUnassignedFields(
      body,
      includeField: (fields) => !fields.isLate && !_isNullableField(fields),
    );
    for (final token in unassigned.values) {
      rule.reportAtToken(token);
    }
  }
}

bool _isNullableField(VariableDeclarationList fields) {
  return fields.type?.toSource().trim().endsWith('?') == true;
}
