import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/record_type_rule.dart';

/// Warns when a record field is explicitly typed as `Never`.
class AvoidBottomTypeInRecords extends GeneratedRecordTypeAnnotationCheckRule {
  static const LintCode code = LintCode(
    'avoid_bottom_type_in_records',
    'Avoid bottom types in records.',
    correctionMessage: 'Use a named result type or model the unreachable state outside the record.',
  );

  AvoidBottomTypeInRecords()
    : super(
        name: 'avoid_bottom_type_in_records',
        description: 'Warns when record fields are explicitly typed as Never.',
        code: code,
      );

  @override
  void checkRecordTypeAnnotation(RecordTypeAnnotation node) {
    for (final field in node.positionalFields) {
      _checkType(field.type);
    }

    final namedFields = node.namedFields;
    if (namedFields == null) return;

    for (final field in namedFields.fields) {
      _checkType(field.type);
    }
  }

  void _checkType(TypeAnnotation type) {
    if (type is NamedType && type.name.lexeme == 'Never') {
      reportAtNode(type);
    }
  }
}
