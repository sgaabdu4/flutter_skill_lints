import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/unassigned_field_analysis.dart';

/// Warns when a `late` instance field is not assigned by each local
/// generative constructor or synchronously by Flutter State.initState.
final class AvoidUnassignedLateFields extends ClassDeclarationRule {
  static const LintCode code = LintCode(
    'avoid_unassigned_late_fields',
    'Late field has no guaranteed constructor or Flutter initialization.',
    correctionMessage:
        'Assign the field in every constructor, in State.initState, or give it an initializer.',
  );

  AvoidUnassignedLateFields()
    : super(
        name: 'avoid_unassigned_late_fields',
        description:
            'Warns when late fields have no guaranteed construction or Flutter initialization.',
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
    final initialized = initializedFlutterStateFields(node);
    for (final entry in unassigned.entries) {
      if (!initialized.contains(entry.key)) rule.reportAtToken(entry.value);
    }
  }
}
