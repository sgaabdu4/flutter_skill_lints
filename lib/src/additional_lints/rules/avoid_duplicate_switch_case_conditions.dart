import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Reports duplicate simple switch case conditions.
final class AvoidDuplicateSwitchCaseConditions extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_duplicate_switch_case_conditions',
    'Avoid duplicate switch case conditions.',
    correctionMessage: 'Remove the duplicate switch case or merge the branch bodies.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidDuplicateSwitchCaseConditions()
    : super(
        name: 'avoid_duplicate_switch_case_conditions',
        description: 'Reports duplicate simple switch case expressions and constant patterns.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry
      ..addSwitchExpression(this, visitor)
      ..addSwitchStatement(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidDuplicateSwitchCaseConditions rule;

  @override
  void visitSwitchExpression(SwitchExpression node) {
    final seen = <String>{};

    for (final caseNode in node.cases) {
      if (caseNode.guardedPattern.whenClause != null) continue;
      _reportDuplicatePattern(caseNode.guardedPattern.pattern, seen);
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    final seen = <String>{};

    for (final member in node.members) {
      switch (member) {
        case SwitchCase(:final expression):
          _reportDuplicateExpression(expression, seen);
        case SwitchPatternCase(:final guardedPattern):
          if (guardedPattern.whenClause != null) break;
          _reportDuplicatePattern(guardedPattern.pattern, seen);
        case SwitchDefault():
          break;
      }
    }
  }

  void _reportDuplicatePattern(DartPattern pattern, Set<String> seen) {
    final expression = switch (_unwrapPattern(pattern)) {
      ConstantPattern(:final expression) => expression,
      _ => null,
    };
    if (expression == null) return;

    _reportDuplicateExpression(expression, seen);
  }

  void _reportDuplicateExpression(Expression expression, Set<String> seen) {
    final key = _literalKey(expression);
    if (key == null) return;

    if (!seen.add(key)) {
      rule.reportAtNode(expression);
    }
  }
}

String? _literalKey(Expression expression) {
  return simpleLiteralKey(expression, includeNegative: true);
}

DartPattern _unwrapPattern(DartPattern pattern) {
  var current = pattern;
  while (current is ParenthesizedPattern) {
    current = current.pattern;
  }
  return current;
}
