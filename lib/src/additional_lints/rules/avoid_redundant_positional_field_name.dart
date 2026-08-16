import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/record_type_rule.dart';

/// Warns when positional record type fields include redundant names.
class AvoidRedundantPositionalFieldName extends GeneratedRecordTypeAnnotationCheckRule {
  static const LintCode code = LintCode(
    'avoid_redundant_positional_field_name',
    'Avoid redundant positional record field names.',
    correctionMessage: 'Remove the positional field name or make the field named.',
  );

  AvoidRedundantPositionalFieldName()
    : super(
        name: 'avoid_redundant_positional_field_name',
        description: 'Warns when positional record type fields include redundant names.',
        code: code,
      );

  @override
  void checkRecordTypeAnnotation(RecordTypeAnnotation node) {
    for (final field in node.positionalFields) {
      final name = field.name;
      if (name != null) {
        reportAtToken(name);
      }
    }
  }
}
