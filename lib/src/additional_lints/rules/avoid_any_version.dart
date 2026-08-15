import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/pubspec_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/pubspec_rule_utils.dart';

/// Reports pubspec dependencies that use the unconstrained `any` version.
final class AvoidAnyVersion extends PubspecAnalysisRule {
  static const LintCode code = LintCode(
    'avoid_any_version',
    'Avoid `any` pub dependency versions.',
    correctionMessage: 'Replace `any` with an explicit version constraint.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidAnyVersion()
    : super(
        name: 'avoid_any_version',
        description: 'Reports pubspec dependencies that use `any` as the version constraint.',
        code: code,
      );

  @override
  bool shouldRegisterPubspec(String text) => _hasAnyVersion(text);

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidAnyVersion rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    rule.reportAtToken(node.beginToken);
  }
}

bool _hasAnyVersion(String text) {
  const dependencySections = ['dependencies', 'dev_dependencies', 'dependency_overrides'];

  for (final section in dependencySections) {
    for (final value in _sectionScalarValues(text, section)) {
      if (unquoteYamlScalar(value) == 'any') return true;
    }
  }

  return false;
}

Iterable<String> _sectionScalarValues(String text, String section) sync* {
  for (final (:line, :indent) in yamlSectionLines(text, section)) {
    if (indent != 2) continue;
    final value = _dependencyScalarValue(line);
    if (value == null) continue;
    yield value;
  }
}

String? _dependencyScalarValue(String line) {
  final match = RegExp(
    r'''^\s*['"]?[A-Za-z_][\w-]*['"]?\s*:\s*(.+?)\s*(?:#.*)?$''',
  ).firstMatch(line);
  final value = match?.group(1)?.trim();
  if (value == null || value.isEmpty || value == '{}' || value.startsWith('{')) {
    return null;
  }
  return value;
}
