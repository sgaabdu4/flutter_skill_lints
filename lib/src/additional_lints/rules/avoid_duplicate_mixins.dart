import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports duplicate mixin types in a `with` clause.
final class AvoidDuplicateMixins extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_duplicate_mixins',
    'Avoid duplicate mixins.',
    correctionMessage: 'Remove the repeated mixin.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidDuplicateMixins()
    : super(
        name: 'avoid_duplicate_mixins',
        description: 'Reports duplicate mixin types in a with clause.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addWithClause(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidDuplicateMixins rule;

  @override
  void visitWithClause(WithClause node) {
    final seen = <String>{};

    for (final mixinType in node.mixinTypes) {
      final key = mixinType.toSource().replaceAll(RegExp(r'\s+'), ' ').trim();
      if (!seen.add(key)) {
        rule.reportAtNode(mixinType);
      }
    }
  }
}
