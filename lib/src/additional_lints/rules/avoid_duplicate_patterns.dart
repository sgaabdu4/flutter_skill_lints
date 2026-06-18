import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports duplicate literal or identifier alternatives in logical-or patterns.
final class AvoidDuplicatePatterns extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_duplicate_patterns',
    'Avoid duplicate pattern alternatives.',
    correctionMessage: 'Remove the repeated pattern alternative.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidDuplicatePatterns()
    : super(
        name: 'avoid_duplicate_patterns',
        description: 'Reports duplicate literal or identifier alternatives in logical-or patterns.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addLogicalOrPattern(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidDuplicatePatterns rule;

  @override
  void visitLogicalOrPattern(LogicalOrPattern node) {
    if (_hasLogicalOrPatternAncestor(node)) return;

    final seen = <String>{};
    for (final pattern in _flattenLogicalOrPattern(node)) {
      final key = _patternKey(pattern);
      if (key == null) continue;

      if (!seen.add(key)) {
        rule.reportAtNode(pattern);
      }
    }
  }
}

bool _hasLogicalOrPatternAncestor(LogicalOrPattern node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is LogicalOrPattern) return true;
    if (current is! ParenthesizedPattern) return false;
    current = current.parent;
  }
  return false;
}

Iterable<DartPattern> _flattenLogicalOrPattern(DartPattern pattern) sync* {
  final unwrapped = _unwrapPattern(pattern);
  if (unwrapped is LogicalOrPattern) {
    yield* _flattenLogicalOrPattern(unwrapped.leftOperand);
    yield* _flattenLogicalOrPattern(unwrapped.rightOperand);
    return;
  }

  yield unwrapped;
}

String? _patternKey(DartPattern pattern) {
  final unwrapped = _unwrapPattern(pattern);
  if (unwrapped is! ConstantPattern) return null;

  return _constantExpressionKey(unwrapped.expression);
}

String? _constantExpressionKey(Expression expression) {
  final unwrapped = _unwrapExpression(expression);

  return switch (unwrapped) {
    BooleanLiteral(:final value) => 'bool:$value',
    DoubleLiteral(:final value) => 'double:$value',
    IntegerLiteral(:final value?) => 'int:$value',
    NullLiteral() => 'null',
    PrefixedIdentifier() => 'identifier:${unwrapped.toSource()}',
    PropertyAccess() => 'identifier:${unwrapped.toSource()}',
    SimpleIdentifier(:final name) => 'identifier:$name',
    SimpleStringLiteral(:final value) => 'string:$value',
    _ => null,
  };
}

DartPattern _unwrapPattern(DartPattern pattern) {
  var current = pattern;
  while (current is ParenthesizedPattern) {
    current = current.pattern;
  }
  return current;
}

Expression _unwrapExpression(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }
  return current;
}
