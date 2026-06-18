import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports untyped wildcard operands in logical-or patterns.
///
/// An untyped wildcard matches every value, so the other branch of the
/// logical-or pattern cannot add useful matching behavior.
class AvoidMisusedWildcardPattern extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_misused_wildcard_pattern',
    'Avoid wildcard patterns in logical-or patterns.',
    correctionMessage: "Replace the logical-or pattern with '_' or remove the redundant branch.",
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidMisusedWildcardPattern()
    : super(
        name: 'avoid_misused_wildcard_pattern',
        description: 'Reports wildcard patterns that make logical-or branches redundant.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addLogicalOrPattern(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidMisusedWildcardPattern rule;

  @override
  void visitLogicalOrPattern(LogicalOrPattern node) {
    final wildcard = _untypedWildcard(node.leftOperand) ?? _untypedWildcard(node.rightOperand);
    if (wildcard != null) {
      rule.reportAtNode(wildcard);
    }
  }

  WildcardPattern? _untypedWildcard(DartPattern pattern) {
    final unwrapped = _unwrapParentheses(pattern);
    if (unwrapped is WildcardPattern && unwrapped.type == null) {
      return unwrapped;
    }

    return null;
  }

  DartPattern _unwrapParentheses(DartPattern pattern) {
    var current = pattern;
    while (current is ParenthesizedPattern) {
      current = current.pattern;
    }

    return current;
  }
}
