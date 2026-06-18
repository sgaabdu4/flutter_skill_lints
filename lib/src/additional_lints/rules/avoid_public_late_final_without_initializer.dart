import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Avoids public `late final` fields without initializers.
///
/// A public field is part of the API contract. If it is uninitialized, users can
/// observe a runtime initialization error. Prefer constructor initialization,
/// a private lazily initialized field, or a `late final` with an initializer.
class AvoidPublicLateFinalWithoutInitializer extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_public_late_final_without_initializer',
    'Avoid public late final fields without initializers.',
    correctionMessage:
        'Initialize the field in the constructor, make the lazy field private, or add a late final initializer.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidPublicLateFinalWithoutInitializer()
    : super(
        name: 'avoid_public_late_final_without_initializer',
        description: 'Avoids public late final fields that are left uninitialized.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addFieldDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidPublicLateFinalWithoutInitializer rule;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.externalKeyword != null) return;
    final fields = node.fields;
    if (!fields.isLate || !fields.isFinal) return;

    for (final variable in fields.variables) {
      if (variable.initializer != null) continue;
      final name = variable.name;
      if (name.lexeme.startsWith('_')) continue;
      rule.reportAtToken(name);
    }
  }
}
