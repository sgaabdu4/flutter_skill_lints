import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Use sealed class for Freezed declarations.
///
/// Why: Bans @freezed abstract class declarations. Replace abstract class with sealed class for
/// Freezed types.
final class UseSealedFreezedClasses extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_sealed_freezed_classes',
    'Use sealed class for Freezed declarations.',
    correctionMessage: 'Replace abstract class with sealed class for Freezed types.',
  );

  UseSealedFreezedClasses()
    : super(
        name: 'use_sealed_freezed_classes',
        description: 'Bans @freezed abstract class declarations.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final UseSealedFreezedClasses rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.abstractKeyword == null) return;
    if (!hasAnnotationNamed(node, const {'freezed', 'Freezed'})) return;
    rule.reportAtToken(node.abstractKeyword!);
  }
}
