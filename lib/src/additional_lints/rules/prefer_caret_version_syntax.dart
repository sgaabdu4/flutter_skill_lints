import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/pubspec_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/pubspec_rule_utils.dart';
import 'package:meta/meta.dart';

/// Warns when a pubspec dependency can use equivalent caret syntax.
final class PreferCaretVersionSyntax extends PubspecAnalysisRule {
  static const LintCode code = LintCode(
    'prefer_caret_version_syntax',
    'Prefer caret syntax for compatible pub dependency ranges.',
    correctionMessage: 'Replace this range with the equivalent ^version constraint.',
  );

  PreferCaretVersionSyntax()
    : super(
        name: 'prefer_caret_version_syntax',
        description: 'Warns when pubspec dependency ranges can use caret syntax.',
        code: code,
      );

  @override
  bool shouldRegisterPubspec(String text) => _hasCaretConvertibleRange(text);

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferCaretVersionSyntax rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    rule.reportAtToken(node.beginToken);
  }
}

bool _hasCaretConvertibleRange(String text) {
  const packageSections = ['dependencies', 'dev_dependencies', 'dependency_overrides'];
  for (final section in packageSections) {
    for (final value in _sectionScalarValues(text, section)) {
      if (_isCaretEquivalent(value)) return true;
    }
  }

  return false;
}

Iterable<String> _sectionScalarValues(String text, String section) sync* {
  final state = _SectionScalarState(section);
  for (final line in text.split('\n')) {
    final value = state.read(line);
    if (value != null) yield value;
  }
}

final class _SectionScalarState {
  _SectionScalarState(String section)
    : sectionPattern = RegExp('^\\s*${RegExp.escape(section)}\\s*:(.*)\$');

  final RegExp sectionPattern;
  final valuePattern = RegExp(r'''^\s*['"]?[A-Za-z_][\w-]*['"]?\s*:\s*(.+?)\s*(?:#.*)?$''');
  bool inSection = false;
  int sectionIndent = 0;

  String? read(String line) {
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) return null;
    final indent = line.length - line.trimLeft().length;
    final sectionMatch = sectionPattern.firstMatch(line);
    if (sectionMatch != null) return _enterSection(indent, sectionMatch);
    if (!inSection) return null;
    if (indent <= sectionIndent) {
      inSection = false;
      return null;
    }
    if (indent != sectionIndent + 2) return null;
    return _scalarValue(line);
  }

  String? _enterSection(int indent, RegExpMatch match) {
    sectionIndent = indent;
    inSection = (match.group(1) ?? '').trim().isEmpty;
    return null;
  }

  String? _scalarValue(String line) {
    final value = valuePattern.firstMatch(line)?.group(1)?.trim();
    if (value == null || value.isEmpty || value == '{}' || value.startsWith('{')) return null;
    return unquoteYamlScalar(value);
  }
}

bool _isCaretEquivalent(String value) {
  final match = RegExp(r'^>=\s*(\d+)\.(\d+)\.(\d+)\s+<\s*(\d+)\.(\d+)\.(\d+)$').firstMatch(value);
  if (match == null) return false;

  final lower = _Version(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
  final upper = _Version(
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.parse(match.group(6)!),
  );

  return upper == lower.caretUpperBound;
}

@immutable
final class _Version {
  const _Version(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  _Version get caretUpperBound {
    if (major > 0) return _Version(major + 1, 0, 0);
    if (minor > 0) return _Version(0, minor + 1, 0);
    return _Version(0, 0, patch + 1);
  }

  @override
  bool operator ==(Object other) =>
      other is _Version && major == other.major && minor == other.minor && patch == other.patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);
}
