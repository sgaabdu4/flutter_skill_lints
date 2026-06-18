import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Reports when record fields use function types or function literals.
class AvoidFunctionTypeInRecords extends AnalysisRule {
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
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    final visitor = _Visitor(this);
    registry
      ..addRecordLiteral(this, visitor)
      ..addRecordTypeAnnotation(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidFunctionTypeInRecords rule;

  @override
  void visitRecordLiteral(RecordLiteral node) {
    for (final field in node.fields) {
      final expression = field is NamedExpression ? field.expression : field;
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
