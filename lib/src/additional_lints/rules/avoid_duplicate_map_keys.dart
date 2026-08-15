import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/duplicate_literal_key.dart';

/// Warns when a const map literal repeats a simple key literal.
final class AvoidDuplicateMapKeys extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_duplicate_map_keys',
    'Avoid duplicate map keys.',
    correctionMessage: 'Remove or rename the repeated map key.',
  );

  AvoidDuplicateMapKeys()
    : super(
        name: 'avoid_duplicate_map_keys',
        description: 'Warns when const map literals repeat simple key literals.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addSetOrMapLiteral(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidDuplicateMapKeys rule;

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (!node.isConst) return;

    final seen = <String>{};
    for (final entry in node.elements.whereType<MapLiteralEntry>()) {
      final key = duplicateLiteralKey(entry.key);
      if (key == null) continue;

      if (!seen.add(key)) {
        rule.reportAtNode(entry.key);
      }
    }
  }
}
