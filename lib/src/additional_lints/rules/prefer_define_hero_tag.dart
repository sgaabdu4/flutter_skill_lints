import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when FloatingActionButton relies on the default hero tag.
class PreferDefineHeroTag extends InstanceAndMethodInvocationRule {
  static const LintCode code = LintCode(
    'prefer_define_hero_tag',
    'Define a heroTag for FloatingActionButton.',
    correctionMessage: 'Add a unique heroTag, or set heroTag: null to disable the Hero.',
  );

  PreferDefineHeroTag()
    : super(
        code: code,
        name: 'prefer_define_hero_tag',
        description: 'Warns when FloatingActionButton omits an explicit heroTag.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends InstanceAndMethodVisitor {
  _Visitor(this.rule);

  final PreferDefineHeroTag rule;

  static const _floatingActionButtonChecker = TypeChecker.fromName(
    'FloatingActionButton',
    packageName: 'flutter',
  );

  @override
  void checkInstanceOrMethod(DartType? staticType, ArgumentList argumentList, AstNode reportNode) {
    if (staticType == null || !_floatingActionButtonChecker.isExactlyType(staticType)) {
      return;
    }

    final heroTag = argumentList.arguments.whereType<NamedArgument>().firstWhereOrNull(
      (argument) => argument.name.lexeme == 'heroTag',
    );
    if (heroTag == null) {
      rule.reportAtNode(reportNode);
    }
  }
}
