import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Reports when a type declares a `call` method.
class AvoidDeclaringCallMethod extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_declaring_call_method',
    'Avoid declaring call methods.',
    correctionMessage: 'Use an explicitly named method instead.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidDeclaringCallMethod()
    : super(
        name: 'avoid_declaring_call_method',
        description: 'Reports when classes, mixins, or extension types declare call methods.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addMethodDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidDeclaringCallMethod rule;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'call') return;

    if (node.thisOrAncestorOfType<ClassDeclaration>() != null ||
        node.thisOrAncestorOfType<MixinDeclaration>() != null ||
        node.thisOrAncestorOfType<ExtensionTypeDeclaration>() != null) {
      rule.reportAtToken(node.name);
    }
  }
}
