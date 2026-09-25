import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Use sealed class for Freezed declarations.
///
/// Why: The skill requires `sealed class` for every `@freezed` declaration, so a resolved
/// Freezed annotation on an `abstract` or plain class is reported. Replace it with a sealed
/// class.
final class UseSealedFreezedClasses extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_sealed_freezed_classes',
    'Use sealed class for Freezed declarations.',
    correctionMessage: 'Declare Freezed types as sealed class, not abstract or plain class.',
    severity: DiagnosticSeverity.ERROR,
  );

  UseSealedFreezedClasses()
    : super(
        name: 'use_sealed_freezed_classes',
        description: 'Bans @freezed abstract and plain (non-sealed) class declarations.',
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
    if (node.sealedKeyword != null) return;
    final isFreezed = node.metadata.any((annotation) {
      final element = annotation.elementAnnotation;
      return element != null && isFreezedAnnotation(element);
    });
    if (!isFreezed) return;
    rule.reportAtToken(node.abstractKeyword ?? node.classKeyword);
  }
}
