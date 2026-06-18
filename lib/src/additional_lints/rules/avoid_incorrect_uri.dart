import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when directive URIs are invalid or likely unintended.
final class AvoidIncorrectUri extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_incorrect_uri',
    'Avoid incorrect directive URIs.',
    correctionMessage: 'Use a valid normalized Dart URI.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidIncorrectUri()
    : super(
        name: 'avoid_incorrect_uri',
        description: 'Warns when import, export, or part URIs are invalid or suspicious.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addExportDirective(this, visitor);
    registry.addImportDirective(this, visitor);
    registry.addPartDirective(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidIncorrectUri rule;

  @override
  void visitExportDirective(ExportDirective node) {
    _check(node.uri);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _check(node.uri);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _check(node.uri);
  }

  void _check(StringLiteral uri) {
    final value = uri.stringValue;
    if (uri.toSource().contains(r'\') || value == null || _isIncorrectUri(value)) {
      rule.reportAtNode(uri);
    }
  }
}

bool _isIncorrectUri(String value) {
  if (value.trim() != value || value.isEmpty) return true;
  if (value.contains(r'\')) return true;
  if (value.contains('//') && !value.startsWith('dart:') && !value.startsWith('package:')) {
    return true;
  }
  if (value.startsWith('/') || value.startsWith('./') || value == '..') {
    return true;
  }
  if (value.contains('/./') || _containsNonLeadingParentSegment(value)) return true;
  if (value.endsWith('/.') || value.endsWith('/..')) return true;

  final parsed = Uri.tryParse(value);
  if (parsed == null || parsed.hasFragment) return true;

  if (parsed.scheme.isNotEmpty && parsed.scheme != 'dart' && parsed.scheme != 'package') {
    return true;
  }

  if (value.startsWith('package:')) {
    final path = value.substring('package:'.length);
    final slashIndex = path.indexOf('/');
    return slashIndex <= 0 || slashIndex == path.length - 1 || path.contains('//');
  }

  if (value.startsWith('dart:')) {
    return value.length == 'dart:'.length || value.contains('/');
  }

  return false;
}

bool _containsNonLeadingParentSegment(String value) {
  String remaining = value;
  while (remaining.startsWith('../')) {
    remaining = remaining.substring('../'.length);
  }
  return remaining.contains('/../');
}
