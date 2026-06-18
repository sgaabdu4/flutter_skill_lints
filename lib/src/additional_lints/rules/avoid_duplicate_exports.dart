import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a library exports the same simple URI more than once.
final class AvoidDuplicateExports extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_duplicate_exports',
    'Avoid duplicate exports.',
    correctionMessage: 'Remove the repeated export directive.',
  );

  AvoidDuplicateExports()
    : super(
        name: 'avoid_duplicate_exports',
        description: 'Warns when a library repeats a simple export URI.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidDuplicateExports rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final seen = <String>{};

    for (final directive in node.directives.whereType<ExportDirective>()) {
      if (directive.combinators.isNotEmpty || directive.configurations.isNotEmpty) {
        continue;
      }

      final uri = directive.uri.stringValue;
      if (uri == null) continue;

      if (!seen.add(uri)) {
        rule.reportAtNode(directive.uri);
      }
    }
  }
}
