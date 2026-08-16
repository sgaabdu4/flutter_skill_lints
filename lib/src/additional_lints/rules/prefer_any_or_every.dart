import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Suggests using .any() or .every() instead of .where().isEmpty/.isNotEmpty.
///
/// The direct predicate methods are easier to read and avoid creating an
/// intermediate filtered iterable.
class PreferAnyOrEvery extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_any_or_every',
    'Use .{0}() instead of .where().{1}.',
    correctionMessage: 'Replace with .{0}() for better readability and performance.',
  );

  PreferAnyOrEvery()
    : super(
        name: 'prefer_any_or_every',
        description: 'Use .any() or .every() instead of .where().isEmpty/isNotEmpty.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addPropertyAccess(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferAnyOrEvery rule;

  _Visitor(this.rule);

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final property = filteredCollectionProperty(node);
    if (property == null) return;
    final isNotEmpty = property == 'isNotEmpty';
    rule.reportAtNode(node, arguments: [isNotEmpty ? 'any' : 'every', property]);
  }
}
