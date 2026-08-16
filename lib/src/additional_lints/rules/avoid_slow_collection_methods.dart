import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Reports collection chains with a cheaper direct predicate form.
class AvoidSlowCollectionMethods extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_slow_collection_methods',
    'Use .{0}() instead of .where().{1}.',
    correctionMessage: 'Use the direct predicate method to avoid a filtered iterable.',
  );

  AvoidSlowCollectionMethods()
    : super(
        name: 'avoid_slow_collection_methods',
        description: 'Reports slow collection method chains with direct alternatives.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addPropertyAccess(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidSlowCollectionMethods rule;

  _Visitor(this.rule);

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final property = filteredCollectionProperty(node);
    if (property == null) return;
    rule.reportAtNode(node, arguments: [property == 'isNotEmpty' ? 'any' : 'every', property]);
  }
}
