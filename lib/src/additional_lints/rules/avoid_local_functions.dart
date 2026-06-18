import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a function is declared inside another function body.
class AvoidLocalFunctions extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_local_functions',
    'Avoid local function declarations.',
    correctionMessage: 'Move the function to a method or top-level helper.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidLocalFunctions()
    : super(
        name: 'avoid_local_functions',
        description: 'Warns when a local function declaration is used.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addFunctionDeclarationStatement(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidLocalFunctions rule;

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    rule.reportAtToken(node.functionDeclaration.name);
  }
}
