import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a library imports the same URI under multiple namespaces.
final class AvoidDuplicateNamedImports extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_duplicate_named_imports',
    'Avoid duplicate named imports.',
    correctionMessage: 'Keep one namespace for each imported URI.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidDuplicateNamedImports()
    : super(
        name: 'avoid_duplicate_named_imports',
        description: 'Warns when a library imports the same URI with different prefixes.',
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

  final AvoidDuplicateNamedImports rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final namespacesByUri = <String, Set<String>>{};

    for (final directive in node.directives.whereType<ImportDirective>()) {
      final uri = directive.uri.stringValue;
      if (uri == null) continue;

      final namespace = directive.prefix?.name ?? '';
      final namespaces = namespacesByUri.putIfAbsent(uri, () => <String>{});
      if (namespaces.isNotEmpty && !namespaces.contains(namespace)) {
        rule.reportAtNode(directive.uri);
      }
      namespaces.add(namespace);
    }
  }
}
