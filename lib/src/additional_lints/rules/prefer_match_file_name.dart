import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a file's single public type does not match the file name.
final class PreferMatchFileName extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_match_file_name',
    'Match the file name to the public type it contains.',
    correctionMessage: 'Rename the file or the public type so they match.',
  );

  PreferMatchFileName()
    : super(
        name: 'prefer_match_file_name',
        description: 'Warns when the file name does not match its public type.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final path = context.definingUnit.file.path.replaceAll('\\', '/');
    if (_isGenerated(path) || path.endsWith('_test.dart')) return;

    registry.addCompilationUnit(this, _Visitor(this, path));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule, this.path);

  final PreferMatchFileName rule;
  final String path;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (node.directives.any((directive) => directive is PartOfDirective)) return;
    if (node.directives.any(_hasManualPartDirective)) return;

    final declarations = <_NamedDeclaration>[];

    for (final declaration in node.declarations) {
      final named = _NamedDeclaration.from(declaration);
      if (named == null || named.name.startsWith('_')) continue;

      declarations.add(named);
    }

    if (declarations.length != 1) return;

    final declaration = declarations.single;
    final expected = _expectedFileNameForType(declaration.name);
    final actual = _fileNameWithoutExtension(path);
    if (actual != expected) {
      rule.reportAtToken(declaration.token);
    }
  }
}

final class _NamedDeclaration {
  const _NamedDeclaration(this.name, this.token);

  final String name;
  final Token token;

  static _NamedDeclaration? from(CompilationUnitMember declaration) {
    switch (declaration) {
      case ClassDeclaration(:final namePart):
        return _NamedDeclaration(namePart.typeName.lexeme, namePart.typeName);
      case EnumDeclaration(:final namePart):
        return _NamedDeclaration(namePart.typeName.lexeme, namePart.typeName);
      case MixinDeclaration(:final name):
        return _NamedDeclaration(name.lexeme, name);
      case ExtensionTypeDeclaration(:final primaryConstructor):
        return _NamedDeclaration(primaryConstructor.typeName.lexeme, primaryConstructor.typeName);
    }

    return null;
  }
}

String _expectedFileNameForType(String typeName) =>
    _toSnakeCase(_normalizeMixedCaseWords(typeName));

String _fileNameWithoutExtension(String path) {
  final fileName = path.substring(path.lastIndexOf('/') + 1);
  return fileName.endsWith('.dart') ? fileName.substring(0, fileName.length - 5) : fileName;
}

bool _isGenerated(String path) {
  const generatedSuffixes = ['.config.dart', '.freezed.dart', '.g.dart', '.gen.dart', '.gr.dart'];

  return generatedSuffixes.any(path.endsWith);
}

bool _hasManualPartDirective(Directive directive) {
  if (directive is! PartDirective) return false;
  final partPath = directive.uri.stringValue;
  return partPath != null && !_isGenerated(partPath);
}

const Map<String, String> _mixedCaseWordReplacements = {'YouTube': 'Youtube'};

String _normalizeMixedCaseWords(String value) {
  String result = value;
  for (final entry in _mixedCaseWordReplacements.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }

  return result;
}

String _toSnakeCase(String value) {
  final buffer = StringBuffer();

  for (int i = 0; i < value.length; i++) {
    final char = value[i];
    final previous = i == 0 ? null : value[i - 1];
    final next = i + 1 == value.length ? null : value[i + 1];

    if (_isUppercase(char)) {
      final shouldSeparate =
          i > 0 &&
          ((previous != null && !_isUppercase(previous)) ||
              (i > 1 && next != null && _isLowercase(next)));
      if (shouldSeparate) buffer.write('_');
      buffer.write(char.toLowerCase());
    } else {
      buffer.write(char);
    }
  }

  return buffer.toString();
}

bool _isLowercase(String char) => char.codeUnitAt(0) >= 0x61 && char.codeUnitAt(0) <= 0x7a;

bool _isUppercase(String char) => char.codeUnitAt(0) >= 0x41 && char.codeUnitAt(0) <= 0x5a;
