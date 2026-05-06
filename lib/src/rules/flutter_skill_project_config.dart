import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

final class FlutterSkillProjectConfig extends MultiAnalysisRule {
  FlutterSkillProjectConfig()
    : super(
        name: 'flutter_skill_project_config',
        description: 'Checks Flutter skill project-level analyzer configuration.',
      );

  static const Map<String, LintCode> codes = {
    'cfg_analysis_options_canonical': LintCode(
      'cfg_analysis_options_canonical',
      'Use the canonical Flutter skill analysis_options.yaml plugin setup.',
      correctionMessage: 'Configure flutter_skill_lints and riverpod_lint under top-level plugins.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'cfg_strict_analysis': LintCode(
      'cfg_strict_analysis',
      'Enable strict analyzer language options.',
      correctionMessage: 'Set strict-casts, strict-inference, and strict-raw-types to true.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'cfg_required_lints': LintCode(
      'cfg_required_lints',
      'Enable the required Flutter skill Dart lints.',
      correctionMessage:
          'Enable avoid_dynamic_calls, unawaited_futures, discarded_futures, '
          'avoid_void_async, avoid_print, cancel_subscriptions, and close_sinks.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'cfg_generated_exclude': LintCode(
      'cfg_generated_exclude',
      'Exclude generated files from analysis.',
      correctionMessage: 'Exclude *.g.dart, *.freezed.dart, *.gr.dart, and *.arb.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'cfg_freezed_annotation_ignore': LintCode(
      'cfg_freezed_annotation_ignore',
      'Ignore invalid_annotation_target for generated Freezed annotations.',
      correctionMessage: 'Set analyzer.errors.invalid_annotation_target to ignore.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'cfg_prohibited_lint_plugins': LintCode(
      'cfg_prohibited_lint_plugins',
      'Remove old lint plugin dependencies and local plugin sources.',
      correctionMessage:
          'Use top-level plugins.flutter_skill_lints.version and '
          'plugins.riverpod_lint; do not add many_lints, freezed_lint, '
          'custom_lint, or local plugin path/git sources.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'cfg_explicit_to_json': LintCode(
      'cfg_explicit_to_json',
      'Set json_serializable explicit_to_json in build.yaml.',
      correctionMessage:
          'Add build.yaml with json_serializable options and explicit_to_json: true.',
      severity: DiagnosticSeverity.ERROR,
    ),
  };

  @override
  List<DiagnosticCode> get diagnosticCodes => codes.values.toList();

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;

    final currentUnit = context.currentUnit ?? context.definingUnit;
    final root = context.package?.root ?? _findPackageRoot(currentUnit.file.parent);
    if (root == null) return;

    final issues = _ProjectConfigScanner(root).scan();
    if (issues.isEmpty) return;

    final anchorPath = _anchorPath(root);
    registry.addCompilationUnit(this, _Visitor(this, issues, anchorPath));
  }

  Folder? _findPackageRoot(Folder start) {
    var folder = start;
    while (true) {
      if (folder.getChildAssumingFile('pubspec.yaml').exists) return folder;
      if (folder.isRoot) return null;
      folder = folder.parent;
    }
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.issues, this.anchorPath);

  final FlutterSkillProjectConfig rule;
  final List<String> issues;
  final String? anchorPath;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final sourcePath = node.declaredFragment?.source.fullName;
    if (anchorPath != null && sourcePath != null && sourcePath != anchorPath) {
      return;
    }

    for (final issue in issues) {
      final diagnosticCode = FlutterSkillProjectConfig.codes[issue];
      if (diagnosticCode == null) continue;
      rule.reportAtOffset(0, 1, diagnosticCode: diagnosticCode);
    }
  }
}

String? _anchorPath(Folder root) {
  final pubspecText = _read(root.getChildAssumingFile('pubspec.yaml'));
  final packageName = RegExp(
    r'^name:\s*([A-Za-z0-9_]+)\s*$',
    multiLine: true,
  ).firstMatch(pubspecText ?? '')?.group(1);

  if (packageName != null) {
    final entrypoint = root.getChildAssumingFile('lib/$packageName.dart');
    if (entrypoint.exists) return entrypoint.path;
  }

  final main = root.getChildAssumingFile('lib/main.dart');
  if (main.exists) return main.path;

  final candidates = [
    ..._dartFiles(root.getChildAssumingFolder('lib')),
    ..._dartFiles(root.getChildAssumingFolder('test')),
  ]..sort();
  return candidates.isEmpty ? null : candidates.first;
}

final class _ProjectConfigScanner {
  _ProjectConfigScanner(this.root);

  final Folder root;

  static const _analyzerPluginPackages = [
    'flutter_skill_lints',
    'riverpod_lint',
    'many_lints',
    'freezed_lint',
    'custom_lint',
  ];

  List<String> scan() {
    final issues = <String>{};
    final pubspecText = _read(root.getChildAssumingFile('pubspec.yaml'));
    if (pubspecText != null) {
      _scanPubspec(pubspecText, issues);
    }

    final analysisOptions = root.getChildAssumingFile('analysis_options.yaml');
    final analysisOptionsText = _read(analysisOptions);

    if (analysisOptionsText == null) {
      issues.add('cfg_analysis_options_canonical');
    } else {
      _scanAnalysisOptions(analysisOptionsText, issues);
    }

    if (_hasJsonModels()) {
      final buildYaml = _read(root.getChildAssumingFile('build.yaml'));
      if (buildYaml == null || !RegExp(r'explicit_to_json\s*:\s*true\b').hasMatch(buildYaml)) {
        issues.add('cfg_explicit_to_json');
      }
    }

    return issues.toList();
  }

  void _scanPubspec(String text, Set<String> issues) {
    for (final package in _analyzerPluginPackages) {
      if (_hasYamlKey(text, package)) {
        issues.add('cfg_prohibited_lint_plugins');
        return;
      }
    }
  }

  void _scanAnalysisOptions(String text, Set<String> issues) {
    if (!RegExp(r'(^|\n)plugins\s*:', multiLine: true).hasMatch(text) ||
        !RegExp(r'(^|\n)\s*flutter_skill_lints\s*:', multiLine: true).hasMatch(text) ||
        !RegExp(r'(^|\n)\s*riverpod_lint\s*:', multiLine: true).hasMatch(text) ||
        text.contains('tool/analyzer_plugins') ||
        RegExp(r'(^|\n)\s*many_lints\s*:').hasMatch(text)) {
      issues.add('cfg_analysis_options_canonical');
    }

    if (_analyzerPluginPackages.skip(2).any((package) => _hasYamlKey(text, package)) ||
        _hasLocalPluginSource(text)) {
      issues.add('cfg_prohibited_lint_plugins');
    }

    for (final option in ['strict-casts', 'strict-inference', 'strict-raw-types']) {
      if (!RegExp('(^|\\n)\\s*$option\\s*:\\s*true\\b').hasMatch(text)) {
        issues.add('cfg_strict_analysis');
      }
    }

    const requiredLints = [
      'avoid_dynamic_calls',
      'unawaited_futures',
      'discarded_futures',
      'avoid_void_async',
      'avoid_print',
      'cancel_subscriptions',
      'close_sinks',
    ];
    for (final lint in requiredLints) {
      final enabledList = RegExp('^\\s*-\\s*$lint\\b', multiLine: true);
      final disabledMap = RegExp('^\\s*$lint\\s*:\\s*false\\b', multiLine: true);
      if (!enabledList.hasMatch(text) || disabledMap.hasMatch(text)) {
        issues.add('cfg_required_lints');
      }
    }

    for (final generated in ['*.g.dart', '*.freezed.dart', '*.gr.dart', '*.arb']) {
      if (!text.contains(generated)) {
        issues.add('cfg_generated_exclude');
      }
    }

    if (!RegExp(r'(^|\n)\s*invalid_annotation_target\s*:\s*ignore\b').hasMatch(text)) {
      issues.add('cfg_freezed_annotation_ignore');
    }
  }

  bool _hasYamlKey(String text, String key) {
    final escaped = RegExp.escape(key);
    return RegExp('(^|[\\n{,])\\s*[\'"]?$escaped[\'"]?\\s*:', multiLine: true).hasMatch(text);
  }

  bool _hasLocalPluginSource(String text) {
    var inPlugins = false;
    var pluginsIndent = 0;
    for (final line in text.split('\n')) {
      if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
      final indent = line.length - line.trimLeft().length;
      final pluginsMatch = RegExp(r'^\s*plugins\s*:(.*)$').firstMatch(line);
      if (pluginsMatch != null) {
        final inlinePlugins = pluginsMatch.group(1) ?? '';
        if (_hasYamlKey(inlinePlugins, 'git') || _hasYamlKey(inlinePlugins, 'path')) {
          return true;
        }
        inPlugins = true;
        pluginsIndent = indent;
        continue;
      }
      if (inPlugins && indent <= pluginsIndent) {
        inPlugins = false;
      }
      if (inPlugins && (_hasYamlKey(line, 'git') || _hasYamlKey(line, 'path'))) {
        return true;
      }
    }
    return false;
  }

  bool _hasJsonModels() {
    for (final path in _dartFiles(root.getChildAssumingFolder('lib'))) {
      final file = root.provider.getFile(path);
      final text = _read(file);
      if (text == null) continue;
      if (RegExp(r'factory\s+\w+\.fromJson\s*\(').hasMatch(text) ||
          RegExp(r'\btoJson\s*\(').hasMatch(text) ||
          text.contains('@JsonSerializable')) {
        return true;
      }
    }
    return false;
  }
}

String? _read(File file) {
  if (!file.exists) return null;
  try {
    return file.readAsStringSync();
  } on FileSystemException {
    return null;
  }
}

Iterable<String> _dartFiles(Folder folder) sync* {
  if (!folder.exists) return;

  List<Resource> children;
  try {
    children = folder.getChildren();
  } on FileSystemException {
    return;
  }

  for (final child in children) {
    if (child is File) {
      if (_isDartSource(child.path)) yield child.path;
    } else if (child is Folder) {
      yield* _dartFiles(child);
    }
  }
}

bool _isDartSource(String path) {
  if (!path.endsWith('.dart')) return false;
  const generatedSuffixes = ['.g.dart', '.freezed.dart', '.gr.dart', '.gen.dart', '.mocks.dart'];
  return !generatedSuffixes.any(path.endsWith);
}
