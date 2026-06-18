import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a pattern explicitly uses the bottom type `Never`.
class AvoidBottomTypeInPatterns extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_bottom_type_in_patterns',
    'Avoid bottom types in patterns.',
    correctionMessage: 'Use a reachable pattern type or model the unreachable state explicitly.',
  );

  AvoidBottomTypeInPatterns()
    : super(
        name: 'avoid_bottom_type_in_patterns',
        description: 'Warns when patterns explicitly use Never.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidBottomTypeInPatterns rule;

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    _checkType(node.type);
    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitObjectPattern(ObjectPattern node) {
    _checkType(node.type);
    super.visitObjectPattern(node);
  }

  void _checkType(TypeAnnotation? type) {
    if (type is NamedType && type.name.lexeme == 'Never') {
      rule.reportAtNode(type);
    }
  }
}
