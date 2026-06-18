import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when code uses an explicit runtime `as` cast.
class AvoidTypeCasts extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_type_casts',
    'Avoid type casts.',
    correctionMessage: 'Use pattern matching, a typed boundary, or explicit parsing instead.',
  );

  AvoidTypeCasts()
    : super(
        name: 'avoid_type_casts',
        description: 'Warns when code uses explicit runtime as-casts.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addAsExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidTypeCasts rule;

  @override
  void visitAsExpression(AsExpression node) {
    final targetType = node.type.type;
    if (targetType == null || targetType is InvalidType) return;
    if (_isAllowedJsonMapCast(node.type)) return;
    if (_isTopType(targetType)) return;

    rule.reportAtNode(node);
  }

  bool _isAllowedJsonMapCast(TypeAnnotation type) {
    if (type is! NamedType || type.name.lexeme != 'Map') return false;
    final arguments = type.typeArguments?.arguments;
    if (arguments == null || arguments.length != 2) return false;

    final keyType = arguments.first;
    final valueType = arguments.last;
    return keyType is NamedType &&
        keyType.name.lexeme == 'String' &&
        valueType is NamedType &&
        valueType.name.lexeme == 'dynamic';
  }

  bool _isTopType(DartType type) {
    return type is DynamicType || type.isDartCoreObject;
  }
}
