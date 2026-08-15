import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

/// Keeps Flutter app and widget imports out of host-side Flutter Driver files.
final class AvoidFlutterHostDriverImports extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_flutter_host_driver_imports',
    'Host driver files must not import Flutter UI or app code.',
    correctionMessage:
        'Keep test_driver code on Dart and host-driver APIs. Move Flutter and app imports to the target test.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidFlutterHostDriverImports()
    : super(
        name: 'avoid_flutter_host_driver_imports',
        description: 'Reports Flutter UI and app imports in host-side test_driver files.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!_isHostDriverPath(context.definingUnit.file.path)) return;
    final visitor = _Visitor(this, _packageName(context));
    registry.addCompilationUnit(this, visitor);
    registry.addImportDirective(this, visitor);
    registry.addExportDirective(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule, this.appPackageName);

  final AvoidFlutterHostDriverImports rule;
  final String? appPackageName;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (_hasDirectForbiddenDirective(node)) return;

    final library = node.declaredFragment?.element;
    if (library == null || _findForbiddenLibrary(library) == null) return;
    rule.reportAtToken(node.beginToken);
  }

  @override
  void visitImportDirective(ImportDirective node) => _check(node.uri);

  @override
  void visitExportDirective(ExportDirective node) => _check(node.uri);

  void _check(StringLiteral uri) {
    final value = uri.stringValue;
    if (value == null || !_isForbidden(value, appPackageName)) return;
    rule.reportAtNode(uri);
  }

  bool _hasDirectForbiddenDirective(CompilationUnit node) {
    for (final directive in node.directives) {
      String? value;
      if (directive is ImportDirective) {
        value = directive.uri.stringValue;
      } else if (directive is ExportDirective) {
        value = directive.uri.stringValue;
      }
      if (value != null && _isForbidden(value, appPackageName)) return true;
    }
    return false;
  }

  LibraryElement? _findForbiddenLibrary(LibraryElement root) {
    final pending = <LibraryElement>[
      ...root.firstFragment.importedLibraries,
      ...root.exportedLibraries,
    ];
    final seen = <String>{};

    while (pending.isNotEmpty) {
      final library = pending.removeLast();
      final uri = library.uri.toString();
      if (!seen.add(uri)) continue;
      if (_isForbidden(uri, appPackageName)) return library;
      pending
        ..addAll(library.firstFragment.importedLibraries)
        ..addAll(library.exportedLibraries);
    }
    return null;
  }
}

bool _isHostDriverPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  return RegExp(r'(^|/)test_driver/').hasMatch(normalized);
}

String? _packageName(RuleContext context) {
  final root = context.package?.root;
  if (root == null) return null;
  final pubspec = root.getFile('pubspec.yaml');
  if (!pubspec.exists) return null;
  final text = pubspec.readAsStringSync();
  return RegExp(r'^name:\s*([A-Za-z0-9_]+)\s*$', multiLine: true).firstMatch(text)?.group(1);
}

bool _isForbidden(String uri, String? appPackageName) {
  if (uri == 'dart:ui' || uri.startsWith('package:flutter/')) return true;
  if (uri == 'package:flutter_driver/driver_extension.dart') return true;
  if (uri == 'package:integration_test/integration_test.dart') return true;
  if (appPackageName == null) return false;

  final appPrefix = 'package:$appPackageName';
  return uri == appPrefix || uri.startsWith('$appPrefix/');
}
