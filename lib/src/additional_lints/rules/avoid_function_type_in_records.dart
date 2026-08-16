import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Reports when record fields use function types or function literals.
class AvoidFunctionTypeInRecords extends RecordRule {
  static const LintCode code = LintCode(
    'avoid_function_type_in_records',
    'Avoid function types in records.',
    correctionMessage: 'Use a named type when a value shape includes behavior.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidFunctionTypeInRecords()
    : super(
        name: 'avoid_function_type_in_records',
        description: 'Reports when record fields use function types or function literals.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidFunctionTypeInRecords rule;

  @override
  void visitRecordLiteral(RecordLiteral node) {
    for (final field in node.fields) {
      final expression = field.fieldExpression;
      if (expression is FunctionExpression) {
        rule.reportAtNode(expression);
      }
    }
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    for (final field in node.positionalFields) {
      if (_isFunctionType(field.type)) {
        rule.reportAtNode(field.type);
      }
    }

    final namedFields = node.namedFields;
    if (namedFields == null) return;

    for (final field in namedFields.fields) {
      if (_isFunctionType(field.type)) {
        rule.reportAtNode(field.type);
      }
    }
  }

  bool _isFunctionType(TypeAnnotation type) {
    if (type is GenericFunctionType) return true;
    if (type is NamedType && type.name.lexeme == 'Function') return true;
    return false;
  }
}
