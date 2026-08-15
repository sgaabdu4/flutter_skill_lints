import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a library exports the same simple URI more than once.
final class AvoidDuplicateExports extends CompilationUnitRule {
  static const LintCode code = LintCode(
    'avoid_duplicate_exports',
    'Avoid duplicate exports.',
    correctionMessage: 'Remove the repeated export directive.',
  );

  AvoidDuplicateExports()
    : super(
        name: 'avoid_duplicate_exports',
        description: 'Warns when a library repeats a simple export URI.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
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
