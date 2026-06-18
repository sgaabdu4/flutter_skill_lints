import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Reports when a constructor has executable code in its body.
class AvoidNonEmptyConstructorBodies extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_non_empty_constructor_bodies',
    'Avoid non-empty constructor bodies.',
    correctionMessage: 'Move work to field initializers, initializer lists, or a named method.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidNonEmptyConstructorBodies()
    : super(
        name: 'avoid_non_empty_constructor_bodies',
        description: 'Reports when constructors contain executable bodies.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addConstructorDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidNonEmptyConstructorBodies rule;

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (_isFreezedFactoryConstructor(node)) return;

    final body = node.body;
    if (body is BlockFunctionBody && body.block.statements.isNotEmpty) {
      rule.reportAtNode(body.block);
    } else if (body is ExpressionFunctionBody) {
      rule.reportAtNode(body.expression);
    }
  }
}

bool _isFreezedFactoryConstructor(ConstructorDeclaration node) {
  if (node.factoryKeyword == null) return false;
  return _isInFreezedClass(node);
}

bool _isInFreezedClass(AstNode node) {
  final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
  return declaration?.metadata.any(_isFreezedAnnotation) ?? false;
}

bool _isFreezedAnnotation(Annotation annotation) {
  final name = annotation.name.name;
  return name == 'freezed' || name == 'Freezed';
}
