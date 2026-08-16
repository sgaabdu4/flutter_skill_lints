import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when package internals import their own public package entrypoint.
final class AvoidImportingEntrypointExports extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_importing_entrypoint_exports',
    'Avoid importing the package entrypoint from package internals.',
    correctionMessage: 'Import the needed internal library directly.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidImportingEntrypointExports()
    : super(
        name: 'avoid_importing_entrypoint_exports',
        description: 'Warns when files under lib/src import package:<name>/<name>.dart.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addCompilationUnit(this, _Visitor(this, context));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule, this.context);

  final AvoidImportingEntrypointExports rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final sourcePath = node.declaredFragment?.source.fullName;
    final packageName = _ownPackageName(sourcePath);
    if (packageName == null) return;

    final entrypointUri = 'package:$packageName/$packageName.dart';
    for (final directive in node.directives.whereType<ImportDirective>()) {
      if (directive.uri.stringValue == entrypointUri) {
        rule.reportAtNode(directive.uri);
      }
    }
  }
}

String? _ownPackageName(String? sourcePath) {
  if (sourcePath == null) return null;

  const marker = '/lib/src/';
  final markerIndex = sourcePath.lastIndexOf(marker);
  if (markerIndex == -1) return null;

  final beforeLib = sourcePath.substring(0, markerIndex);
  final packageSeparator = beforeLib.lastIndexOf('/');
  if (packageSeparator == -1 || packageSeparator == beforeLib.length - 1) {
    return null;
  }

  return beforeLib.substring(packageSeparator + 1);
}
