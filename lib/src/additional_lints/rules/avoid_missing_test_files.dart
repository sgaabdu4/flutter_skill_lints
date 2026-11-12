import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:flutter_skill_lints/src/additional_lints/pubspec_rule_utils.dart';

/// Warns when a non-generated lib file has no obvious sibling test file.
final class AvoidMissingTestFiles extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_missing_test_files',
    'Add a matching test file for this library file.',
    correctionMessage: 'Create the matching *_test.dart file under test/.',
  );

  AvoidMissingTestFiles()
    : super(
        name: 'avoid_missing_test_files',
        description: 'Warns when a lib file has no matching test file under test/.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final package = context.package;
    if (package == null || !context.isInLibDir) return;

    final currentPath = context.definingUnit.file.path;
    final normalizedPath = currentPath.replaceAll('\\', '/');
    if (_isGenerated(normalizedPath)) return;
    if (_isLowSignalLibrary(normalizedPath)) return;

    final root = package.root;
    final testFolder = root.getFolder('test');
    if (!testFolder.exists) return;

    final expectedTestPath = _expectedTestPath(root, currentPath);
    if (expectedTestPath == null) return;

    final expectedTestFile = testFolder.getFile(expectedTestPath);
    if (expectedTestFile.exists) return;
    if (_hasTestImportCoverage(context.libraryElement!.session, root, testFolder, currentPath)) {
      return;
    }

    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidMissingTestFiles rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (node.directives.any((directive) => directive is PartOfDirective)) return;
    if (node.declarations.isEmpty) return;

    rule.reportAtToken(node.beginToken);
  }
}

String? _expectedTestPath(Folder root, String filePath) {
  final separator = root.path.contains('\\') ? '\\' : '/';
  final normalizedRoot = root.path.replaceAll('\\', '/');
  final normalizedFile = filePath.replaceAll('\\', '/');
  final libPrefix = '$normalizedRoot/lib/';

  if (!normalizedFile.startsWith(libPrefix) || !normalizedFile.endsWith('.dart')) {
    return null;
  }

  final relativeLibPath = normalizedFile.substring(libPrefix.length);
  final withoutExtension = relativeLibPath.substring(0, relativeLibPath.length - 5);
  return '${withoutExtension}_test.dart'.replaceAll('/', separator);
}

bool _isGenerated(String path) {
  const generatedSuffixes = ['.config.dart', '.freezed.dart', '.g.dart', '.gen.dart', '.gr.dart'];

  return generatedSuffixes.any(path.endsWith);
}

bool _isLowSignalLibrary(String path) {
  return path.contains('/lib/core/constants/') ||
      (path.contains('/lib/core/config/') && path.endsWith('_schema.dart'));
}

final _testReachedUris = Expando<Map<String, Set<String>>>('flutter_skill_lints_test_reached_uris');

bool _hasTestImportCoverage(
  AnalysisSession session,
  Folder root,
  Folder testFolder,
  String filePath,
) {
  final packageName = packageNameFromPubspec(root);
  if (packageName == null) return false;

  final packageUri = _packageUri(root, filePath, packageName);
  if (packageUri == null) return false;

  final byRoot = _testReachedUris[session] ??= <String, Set<String>>{};
  final reached = byRoot[root.path] ??= _testReachedPackageUris(root, testFolder, packageName);
  return reached.contains(packageUri);
}

Set<String> _testReachedPackageUris(Folder root, Folder testFolder, String packageName) {
  final reached = <String>{};
  final pending = <String>[];

  void collect(String path, String text) {
    for (final uri in _importOrExportUris(text)) {
      final resolved = _resolveToPackageUri(root, path, uri, packageName);
      if (resolved != null && reached.add(resolved)) pending.add(resolved);
    }
  }

  for (final file in _dartFiles(testFolder)) {
    final text = readFileText(file);
    if (text != null) collect(file.path, text);
  }
  while (pending.isNotEmpty) {
    final sourceFile = _fileForPackageUri(root, pending.removeLast(), packageName);
    if (sourceFile == null) continue;
    final text = readFileText(sourceFile);
    if (text != null) collect(sourceFile.path, text);
  }
  return reached;
}

final _importExportPattern = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

Iterable<String> _importOrExportUris(String text) sync* {
  final directive = _importExportPattern;
  for (final match in directive.allMatches(text)) {
    yield match.group(1)!;
  }
}

Iterable<File> _dartFiles(Folder folder) sync* {
  if (!folder.exists) return;

  final children = folder.getChildren();
  for (final child in children) {
    if (child is Folder) {
      yield* _dartFiles(child);
    } else if (child is File && child.path.endsWith('.dart')) {
      yield child;
    }
  }
}

String? _packageUri(Folder root, String filePath, String packageName) {
  final normalizedRoot = root.path.replaceAll('\\', '/');
  final normalizedFile = filePath.replaceAll('\\', '/');
  final libPrefix = '$normalizedRoot/lib/';
  if (!normalizedFile.startsWith(libPrefix)) return null;

  return 'package:$packageName/${normalizedFile.substring(libPrefix.length)}';
}

String? _resolveToPackageUri(
  Folder root,
  String containingFilePath,
  String uri,
  String packageName,
) {
  final samePackagePrefix = 'package:$packageName/';
  if (uri.startsWith('package:')) {
    return uri.startsWith(samePackagePrefix) ? uri : null;
  }
  if (uri.contains(':')) return null;

  final normalizedRoot = root.path.replaceAll('\\', '/');
  final normalizedFile = containingFilePath.replaceAll('\\', '/');
  final absolutePath = _normalizePath('${_directoryPath(normalizedFile)}/$uri');
  final libPrefix = '$normalizedRoot/lib/';
  if (!absolutePath.startsWith(libPrefix) || !absolutePath.endsWith('.dart')) return null;

  return 'package:$packageName/${absolutePath.substring(libPrefix.length)}';
}

File? _fileForPackageUri(Folder root, String packageUri, String packageName) {
  final prefix = 'package:$packageName/';
  if (!packageUri.startsWith(prefix)) return null;

  final separator = root.path.contains('\\') ? '\\' : '/';
  final relativePath = 'lib/${packageUri.substring(prefix.length)}'.replaceAll('/', separator);
  return root.getFile(relativePath);
}

String _directoryPath(String path) {
  final slash = path.lastIndexOf('/');
  if (slash == -1) return '.';
  return path.substring(0, slash);
}

String _normalizePath(String path) {
  final normalized = path.replaceAll('\\', '/');
  final isAbsolute = normalized.startsWith('/');
  final parts = <String>[];

  for (final part in normalized.split('/')) {
    if (part.isEmpty || part == '.') continue;
    if (part == '..') {
      if (parts.isNotEmpty && parts.last != '..') {
        parts.removeLast();
      } else if (!isAbsolute) {
        parts.add(part);
      }
      continue;
    }
    parts.add(part);
  }

  return '${isAbsolute ? '/' : ''}${parts.join('/')}';
}
