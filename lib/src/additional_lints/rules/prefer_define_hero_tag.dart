import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when FloatingActionButton relies on the default hero tag.
class PreferDefineHeroTag extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_define_hero_tag',
    'Define a heroTag for FloatingActionButton.',
    correctionMessage: 'Add a unique heroTag, or set heroTag: null to disable the Hero.',
  );

  PreferDefineHeroTag()
    : super(
        name: 'prefer_define_hero_tag',
        description: 'Warns when FloatingActionButton omits an explicit heroTag.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final PreferDefineHeroTag rule;

  static const _floatingActionButtonChecker = TypeChecker.fromName(
    'FloatingActionButton',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node.staticType, node.argumentList, node.constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _check(node.staticType, node.argumentList, node.methodName);
  }

  void _check(DartType? staticType, ArgumentList argumentList, AstNode reportNode) {
    if (staticType == null || !_floatingActionButtonChecker.isExactlyType(staticType)) {
      return;
    }

    final heroTag = argumentList.arguments.whereType<NamedExpression>().firstWhereOrNull(
      (argument) => argument.name.lexeme == 'heroTag',
    );
    if (heroTag == null) {
      rule.reportAtNode(reportNode);
    }
  }
}
