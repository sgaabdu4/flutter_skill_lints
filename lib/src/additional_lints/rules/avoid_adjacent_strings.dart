import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when adjacent string literals are elements of a list or set literal.
class AvoidAdjacentStrings extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_adjacent_strings',
    'Adjacent string literals in a collection can hide a missing comma.',
    correctionMessage: 'Add the missing comma, or join the strings into one literal.',
  );

  AvoidAdjacentStrings()
    : super(
        name: 'avoid_adjacent_strings',
        description: 'Warns when adjacent string literals are elements of a list or set literal.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addAdjacentStrings(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidAdjacentStrings rule;

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    if (_isCollectionElement(node)) rule.reportAtNode(node);
  }

  static bool _isCollectionElement(AstNode node) {
    var child = node;
    var parent = node.parent;
    while ((parent is IfElement && (parent.thenElement == child || parent.elseElement == child)) ||
        (parent is ForElement && parent.body == child)) {
      child = parent!;
      parent = parent.parent;
    }
    return parent is ListLiteral || (parent is SetOrMapLiteral && parent.isSet);
  }
}
