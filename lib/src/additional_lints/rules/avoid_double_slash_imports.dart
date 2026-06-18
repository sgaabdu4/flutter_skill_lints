import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when an import or export URI contains a repeated slash in its path.
class AvoidDoubleSlashImports extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_double_slash_imports',
    'Avoid double slashes in import and export URIs.',
    correctionMessage: 'Use a normalized URI path.',
  );

  AvoidDoubleSlashImports()
    : super(
        name: 'avoid_double_slash_imports',
        description: 'Warns when import or export directives contain double slashes.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addImportDirective(this, visitor);
    registry.addExportDirective(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidDoubleSlashImports rule;

  @override
  void visitExportDirective(ExportDirective node) {
    _checkUri(node.uri);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _checkUri(node.uri);
  }

  void _checkUri(StringLiteral uri) {
    final value = uri.stringValue;
    if (value == null) return;
    if (_hasRepeatedPathSlash(value)) {
      rule.reportAtNode(uri);
    }
  }
}

bool _hasRepeatedPathSlash(String value) {
  final schemeEnd = value.indexOf('://');
  final path = schemeEnd == -1 ? value : value.substring(schemeEnd + 3);
  return path.contains('//');
}
