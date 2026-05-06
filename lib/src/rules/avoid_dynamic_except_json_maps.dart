import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

final class AvoidDynamicExceptJsonMaps extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_dynamic_except_json_maps',
    'Avoid dynamic except at JSON map boundaries.',
    correctionMessage: 'Use Object?, a precise type, or Map<String, dynamic> for JSON.',
  );

  AvoidDynamicExceptJsonMaps()
    : super(
        name: 'avoid_dynamic_except_json_maps',
        description: 'Bans dynamic except in Map<String, dynamic> JSON types.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addNamedType(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidDynamicExceptJsonMaps rule;

  @override
  void visitNamedType(NamedType node) {
    if (node.name.lexeme != 'dynamic') return;
    if (_isAllowedJsonMapDynamic(node)) return;
    rule.reportAtNode(node);
  }

  bool _isAllowedJsonMapDynamic(NamedType node) {
    final parent = node.parent;
    if (parent is! TypeArgumentList) return false;
    final mapType = parent.parent;
    if (mapType is! NamedType || mapType.name.lexeme != 'Map') return false;
    final arguments = parent.arguments;
    if (arguments.length != 2) return false;
    final keyType = arguments.first;
    return keyType is NamedType && keyType.name.lexeme == 'String' && arguments.last == node;
  }
}
