import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when code uses annotations that are banned by this lint pack.
class AvoidBannedAnnotations extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_banned_annotations',
    "Avoid banned annotation '@{0}'.",
    correctionMessage: 'Remove the annotation or use a project-approved replacement.',
  );

  static const bannedAnnotationNames = {'Deprecated', 'deprecated'};

  AvoidBannedAnnotations()
    : super(
        name: 'avoid_banned_annotations',
        description: 'Warns when code uses banned annotations.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addAnnotation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidBannedAnnotations rule;

  @override
  void visitAnnotation(Annotation node) {
    final name = _annotationName(node);
    if (!AvoidBannedAnnotations.bannedAnnotationNames.contains(name)) return;
    rule.reportAtNode(node, arguments: [name]);
  }

  String _annotationName(Annotation node) {
    final name = node.name;
    if (name is PrefixedIdentifier) return name.identifier.name;
    return name.name;
  }
}
