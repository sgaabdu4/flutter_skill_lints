import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a declaration uses `var` instead of an explicit type.
final class PreferTypeOverVar extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_type_over_var',
    "Prefer an explicit type annotation over 'var'.",
    correctionMessage: 'Replace var with the inferred type so the declaration stays explicit.',
    severity: DiagnosticSeverity.ERROR,
  );

  PreferTypeOverVar()
    : super(
        name: 'prefer_type_over_var',
        description: 'Warns when variables are declared with var instead of an explicit type.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry
      ..addVariableDeclarationList(this, visitor)
      ..addPatternVariableDeclaration(this, visitor)
      ..addDeclaredVariablePattern(this, visitor)
      ..addDeclaredIdentifier(this, visitor)
      ..addForEachPartsWithPattern(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferTypeOverVar rule;

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) => _report(node.keyword);

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) => _report(node.keyword);

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) => _report(node.keyword);

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) => _report(node.keyword);

  @override
  void visitForEachPartsWithPattern(ForEachPartsWithPattern node) => _report(node.keyword);

  void _report(Token? keyword) {
    if (keyword == null || keyword.lexeme != 'var') return;
    rule.reportAtToken(keyword);
  }
}
