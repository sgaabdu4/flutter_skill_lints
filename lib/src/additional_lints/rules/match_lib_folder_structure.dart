import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/pubspec_rule_utils.dart';

/// Warns when a package-imported lib file's test is not in the matching folder.
final class MatchLibFolderStructure extends AnalysisRule {
  static const LintCode code = LintCode(
    'match_lib_folder_structure',
    'Match test folder structure to lib folder structure.',
    correctionMessage: 'Move this test file to the path that mirrors the imported lib file.',
  );

  MatchLibFolderStructure()
    : super(
        name: 'match_lib_folder_structure',
        description: 'Warns when test files do not mirror the imported lib file path.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final root = context.package?.root;
    if (root == null) return;

    final packageName = packageNameFromPubspec(root);
    if (packageName == null) return;

    final path = context.definingUnit.file.path.replaceAll('\\', '/');
    if (!path.contains('/test/') || !path.endsWith('_test.dart')) return;

    final testTopLevelFolder = _testTopLevelFolder(path);
    if (testTopLevelFolder != null) {
      final matchingLibFolder = root.getFolder('lib').getFolder(testTopLevelFolder);
      if (!matchingLibFolder.exists) return;
    }

    registry.addCompilationUnit(this, _Visitor(this, packageName, path));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule, this.packageName, this.path);

  final MatchLibFolderStructure rule;
  final String packageName;
  final String path;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final expectedPaths = <String>{};
    for (final directive in node.directives.whereType<ImportDirective>()) {
      final imported = directive.uri.stringValue;
      if (imported == null) continue;

      final libPath = _packageLibPath(imported, packageName);
      if (libPath == null) continue;

      final expectedTestPath = _expectedTestPath(path, libPath);
      if (expectedTestPath != null) expectedPaths.add(expectedTestPath);
    }

    if (expectedPaths.length != 1) return;
    if (path == expectedPaths.single) return;

    rule.reportAtToken(node.beginToken);
  }
}

String? _packageLibPath(String uri, String packageName) {
  final prefix = 'package:$packageName/';
  if (!uri.startsWith(prefix) || !uri.endsWith('.dart')) return null;

  final relative = uri.substring(prefix.length);
  if (relative.startsWith('src/generated/') || _isGenerated(relative)) return null;

  return relative;
}

String? _expectedTestPath(String testPath, String libPath) {
  final testRootIndex = testPath.lastIndexOf('/test/');
  if (testRootIndex == -1) return null;

  final withoutExtension = libPath.substring(0, libPath.length - '.dart'.length);
  return '${testPath.substring(0, testRootIndex)}/test/${withoutExtension}_test.dart';
}

String? _testTopLevelFolder(String testPath) {
  final testRootIndex = testPath.lastIndexOf('/test/');
  if (testRootIndex == -1) return null;

  final relative = testPath.substring(testRootIndex + '/test/'.length);
  final slashIndex = relative.indexOf('/');
  if (slashIndex == -1) return null;

  return relative.substring(0, slashIndex);
}

bool _isGenerated(String path) => generatedDartFileSuffixes.any(path.endsWith);
