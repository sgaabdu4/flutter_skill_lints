import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/error/error.dart';

/// Warns when nullable values are interpolated directly into strings.
class AvoidNullableInterpolation extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_nullable_interpolation',
    'Avoid interpolating nullable values directly.',
    correctionMessage: 'Handle the null case before interpolating the value.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidNullableInterpolation()
    : super(
        name: 'avoid_nullable_interpolation',
        description: 'Warns when nullable values are interpolated directly.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addInterpolationExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidNullableInterpolation rule;

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    final type = node.expression.staticType;
    if (type?.nullabilitySuffix != NullabilitySuffix.question) return;
    rule.reportAtNode(node.expression);
  }
}
