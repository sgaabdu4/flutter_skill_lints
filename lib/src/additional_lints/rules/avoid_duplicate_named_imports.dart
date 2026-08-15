import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a library imports the same URI under multiple namespaces.
final class AvoidDuplicateNamedImports extends CompilationUnitRule {
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
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
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
