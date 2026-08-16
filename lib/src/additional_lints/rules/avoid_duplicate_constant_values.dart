import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/duplicate_literal_key.dart';

/// Warns when one const declaration group repeats a simple literal value.
final class AvoidDuplicateConstantValues extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_duplicate_constant_values',
    'Avoid duplicate constant values.',
    correctionMessage: 'Use a single shared constant or change the repeated value.',
  );

  AvoidDuplicateConstantValues()
    : super(
        name: 'avoid_duplicate_constant_values',
        description: 'Warns when const declaration groups repeat simple literal values.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addVariableDeclarationList(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidDuplicateConstantValues rule;

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.keyword?.keyword != Keyword.CONST) return;

    final seen = <String>{};
    for (final variable in node.variables) {
      final initializer = variable.initializer;
      if (initializer == null) continue;

      final key = duplicateLiteralKey(initializer);
      if (key == null) continue;

      if (!seen.add(key)) {
        rule.reportAtNode(initializer);
      }
    }
  }
}
