import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a short numeric literal uses digit separators.
class AvoidUnnecessaryDigitSeparators extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_digit_separators',
    'Avoid digit separators in short numeric literals.',
    correctionMessage: 'Remove the separator or use it only for larger grouped values.',
  );

  AvoidUnnecessaryDigitSeparators()
    : super(
        name: 'avoid_unnecessary_digit_separators',
        description: 'Warns when a short numeric literal uses digit separators.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry
      ..addIntegerLiteral(this, visitor)
      ..addDoubleLiteral(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUnnecessaryDigitSeparators rule;

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    if (_hasUnnecessarySeparator(node.literal.lexeme)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    if (_hasUnnecessarySeparator(node.literal.lexeme)) {
      rule.reportAtNode(node);
    }
  }
}

bool _hasUnnecessarySeparator(String lexeme) {
  if (!lexeme.contains('_')) return false;

  final normalized = lexeme.toLowerCase();
  final exponentIndex = normalized.indexOf('e');
  final mantissa = exponentIndex == -1 ? normalized : normalized.substring(0, exponentIndex);
  final exponent = exponentIndex == -1 ? '' : normalized.substring(exponentIndex + 1);

  return _underscoredDigitCount(mantissa) <= 3 || _underscoredDigitCount(exponent) <= 3;
}

int _underscoredDigitCount(String part) {
  if (!part.contains('_')) return 4;
  final withoutPrefix = part.startsWith('0x') ? part.substring(2) : part;
  return withoutPrefix.replaceAll(RegExp(r'[^0-9a-f]'), '').length;
}
