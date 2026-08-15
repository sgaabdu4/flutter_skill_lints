import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when a `BuildContext` is stored in a `late` variable.
class AvoidLateContext extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_late_context',
    'Avoid storing BuildContext in late variables.',
    correctionMessage: 'Pass BuildContext through the call path or read it from State.context.',
  );

  AvoidLateContext()
    : super(
        name: 'avoid_late_context',
        description: 'Warns when BuildContext is stored in late variables.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addVariableDeclarationList(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidLateContext rule;

  static const _buildContextChecker = TypeChecker.fromName('BuildContext', packageName: 'flutter');

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (!node.isLate) return;

    for (final variable in node.variables) {
      final type = variable.declaredFragment?.element.type;
      if (type == null || !_buildContextChecker.isExactlyType(type)) continue;

      rule.reportAtToken(variable.name);
    }
  }
}
