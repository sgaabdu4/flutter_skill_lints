import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when app source re-exports packages that are not allowed by this lint pack.
final class AvoidBannedExports extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_banned_exports',
    "Avoid exporting banned package '{0}'.",
    correctionMessage: 'Remove the export or expose an app-owned API instead.',
  );

  static const bannedPackages = {
    'custom_lint',
    'custom_lint_builder',
    'custom_lint_core',
    'dart_code_metrics',
    'dart_code_metrics_presets',
    'flutter_bloc',
    'flutter_skill_lints',
    'get',
    'get_it',
    'provider',
    'riverpod_lint',
  };

  AvoidBannedExports()
    : super(
        name: 'avoid_banned_exports',
        description: 'Warns when app source exports banned architecture packages.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!context.isInLibDir) return;

    registry.addExportDirective(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidBannedExports rule;

  @override
  void visitExportDirective(ExportDirective node) {
    final packageName = _packageNameFromUri(node.uri);
    if (packageName == null || !AvoidBannedExports.bannedPackages.contains(packageName)) {
      return;
    }

    rule.reportAtNode(node.uri, arguments: [packageName]);
  }
}

String? _packageNameFromUri(StringLiteral uri) {
  final value = uri.stringValue;
  if (value == null || !value.startsWith('package:')) return null;

  final path = value.substring('package:'.length);
  final separatorIndex = path.indexOf('/');
  return separatorIndex == -1 ? path : path.substring(0, separatorIndex);
}
