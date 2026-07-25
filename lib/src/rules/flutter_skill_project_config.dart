import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Reports package-level Flutter skill configuration drift.
///
/// Why: the skill depends on analyzer plugins, strict language checks, generated-file
/// exclusions, JSON serialization settings, and deterministic E2E entrypoints. This rule
/// reads project files and reports drift through diagnostics anchored to a Dart analysis
/// unit before the app relies on missing runtime proof.
final class FlutterSkillProjectConfig extends MultiAnalysisRule {
  FlutterSkillProjectConfig()
    : super(
        name: 'flutter_skill_project_config',
        description: 'Reports Flutter skill project-level analyzer configuration drift.',
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
      'Enable strict analyzer language options and required analyzer errors.',
      correctionMessage:
          'Set strict-casts, strict-inference, strict-raw-types, '
          'missing_required_param, and missing_return.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'cfg_required_lints': LintCode(
      'cfg_required_lints',
      'Enable the required Flutter skill Dart lints.',
      correctionMessage:
          'Enable the complete Flutter skill linter.rules list from analysis_options.yaml.',
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
          'Use top-level plugins.flutter_skill_lints.version, or a local '
          'plugins.flutter_skill_lints.path while testing a checkout, and '
          'plugins.riverpod_lint. Do not add many_lints, freezed_lint, '
          'custom_lint, or other local plugin path/git sources.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'cfg_explicit_to_json': LintCode(
      'cfg_explicit_to_json',
      'Set json_serializable explicit_to_json in build.yaml.',
      correctionMessage:
          'Add build.yaml with json_serializable options and explicit_to_json: true.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'cfg_e2e_entrypoint': LintCode(
      'cfg_e2e_entrypoint',
      'Add a deterministic Flutter Driver E2E entrypoint.',
      correctionMessage:
          'Create lib/main_dev.dart and call enableFlutterDriverExtension() before runApp.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'avoid_any_version': LintCode(
      'avoid_any_version',
      'Avoid using any as a pubspec dependency version.',
      correctionMessage: 'Pin the dependency to a concrete version constraint.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'avoid_dependency_overrides': LintCode(
      'avoid_dependency_overrides',
      'Avoid dependency_overrides in pubspec.yaml.',
      correctionMessage: 'Remove dependency_overrides before shipping the package.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'prefer_publish_to_none': LintCode(
      'prefer_publish_to_none',
      'Use publish_to: none for non-published package configs.',
      correctionMessage: 'Set publish_to: none when this package should not be published.',
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

    final anchorPath = _anchorPath(root);
    if (anchorPath != null && currentUnit.file.path != anchorPath) return;

    final issues = _ProjectConfigScanner(root).scan();
    if (issues.isEmpty) return;

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
      if (_isFlutterPackage(pubspecText)) {
        _scanFlutterE2eEntrypoint(issues);
      }
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

    if (_hasAnyDependencyVersion(text)) {
      issues.add('avoid_any_version');
    }
    if (_hasPubspecSectionEntries(text, 'dependency_overrides')) {
      issues.add('avoid_dependency_overrides');
    }
    if (_hasNonNonePublishTarget(text)) {
      issues.add('prefer_publish_to_none');
    }
  }

  bool _isFlutterPackage(String text) =>
      RegExp(r'(^|\n)\s*flutter\s*:\s*\n\s*sdk\s*:\s*flutter\b').hasMatch(text) ||
      RegExp(r'(^|\n)\s*flutter\s*:', multiLine: true).hasMatch(text);

  void _scanFlutterE2eEntrypoint(Set<String> issues) {
    final mainDev = _read(root.getChildAssumingFile('lib/main_dev.dart'));
    if (mainDev == null || !_hasDeterministicFlutterE2eEntrypoint(mainDev)) {
      issues.add('cfg_e2e_entrypoint');
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
    for (final error in ['missing_required_param', 'missing_return']) {
      if (!RegExp('(^|\\n)\\s*$error\\s*:\\s*error\\b').hasMatch(text)) {
        issues.add('cfg_strict_analysis');
      }
    }

    const requiredLints = [
      'always_use_package_imports',
      'require_trailing_commas',
      'prefer_single_quotes',
      'directives_ordering',
      'avoid_multiple_declarations_per_line',
      'prefer_const_constructors',
      'prefer_const_declarations',
      'prefer_const_literals_to_create_immutables',
      'prefer_final_locals',
      'always_declare_return_types',
      'type_annotate_public_apis',
      'avoid_positional_boolean_parameters',
      'avoid_equals_and_hash_code_on_mutable_classes',
      'avoid_private_typedef_functions',
      'avoid_returning_this',
      'avoid_setters_without_getters',
      'prefer_mixin',
      'use_to_and_as_if_applicable',
      'avoid_dynamic_calls',
      'avoid_print',
      'avoid_void_async',
      'cancel_subscriptions',
      'close_sinks',
      'discarded_futures',
      'unawaited_futures',
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

  bool _hasAnyDependencyVersion(String text) {
    const dependencySections = ['dependencies', 'dev_dependencies', 'dependency_overrides'];
    for (final section in dependencySections) {
      for (final line in _sectionLines(text, section)) {
        if (RegExp(r'''^\s*['"]?[\w-]+['"]?\s*:\s*['"]?any['"]?\s*(?:#.*)?$''').hasMatch(line)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _hasPubspecSectionEntries(String text, String section) {
    final sectionMatch = RegExp(
      '^\\s*${RegExp.escape(section)}\\s*:(.*)\$',
      multiLine: true,
    ).firstMatch(text);
    if (sectionMatch == null) return false;

    final inline = sectionMatch.group(1) ?? '';
    if (inline.trim().isNotEmpty && inline.trim() != '{}') return true;

    return _sectionLines(
      text,
      section,
    ).any((line) => RegExp(r'''^\s*['"]?[\w-]+['"]?\s*:''').hasMatch(line));
  }

  bool _hasNonNonePublishTarget(String text) {
    for (final line in text.split('\n')) {
      if (line.trimLeft().startsWith('#')) continue;
      final match = RegExp(
        r'''^\s*publish_to\s*:\s*['"]?([^'"#\s]+)['"]?\s*(?:#.*)?$''',
      ).firstMatch(line);
      if (match == null) continue;
      return match.group(1) != 'none';
    }
    return false;
  }

  Iterable<String> _sectionLines(String text, String section) sync* {
    final lines = text.split('\n');
    var inSection = false;
    var sectionIndent = 0;

    for (final line in lines) {
      if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
      final indent = line.length - line.trimLeft().length;
      final sectionMatch = RegExp('^\\s*${RegExp.escape(section)}\\s*:(.*)\$').firstMatch(line);
      if (sectionMatch != null) {
        sectionIndent = indent;
        inSection = (sectionMatch.group(1) ?? '').trim().isEmpty;
        continue;
      }
      if (!inSection) continue;
      if (indent <= sectionIndent) {
        inSection = false;
        continue;
      }
      yield line;
    }
  }

  bool _hasLocalPluginSource(String text) {
    var inPlugins = false;
    var pluginsIndent = 0;
    String? currentPlugin;
    var currentPluginIndent = 0;

    for (final line in text.split('\n')) {
      if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
      final indent = line.length - line.trimLeft().length;
      final pluginsMatch = RegExp(r'^\s*plugins\s*:(.*)$').firstMatch(line);
      if (pluginsMatch != null) {
        final inlinePlugins = pluginsMatch.group(1) ?? '';
        if (_flowStyleHasProhibitedLocalSource(inlinePlugins)) return true;
        inPlugins = inlinePlugins.trim().isEmpty;
        pluginsIndent = indent;
        currentPlugin = null;
        continue;
      }
      if (inPlugins && indent <= pluginsIndent) {
        inPlugins = false;
        currentPlugin = null;
      }
      if (inPlugins) {
        if (currentPlugin != null && indent <= currentPluginIndent) {
          currentPlugin = null;
        }

        final pluginMatch = RegExp(r'''^\s*['"]?([A-Za-z_]\w*)['"]?\s*:(.*)$''').firstMatch(line);
        if (pluginMatch != null && indent > pluginsIndent) {
          final candidate = pluginMatch.group(1);
          if (candidate == 'path' || candidate == 'git') {
            if (!_allowsLocalPluginSource(currentPlugin, line)) {
              return true;
            }
            continue;
          } else {
            currentPlugin = candidate;
            currentPluginIndent = indent;
          }
          final rest = pluginMatch.group(2) ?? '';
          if (_lineHasLocalSource(rest) && !_allowsLocalPluginSource(currentPlugin, rest)) {
            return true;
          }
          continue;
        }

        if (_lineHasLocalSource(line) && !_allowsLocalPluginSource(currentPlugin, line)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _lineHasLocalSource(String text) => _hasYamlKey(text, 'git') || _hasYamlKey(text, 'path');

  bool _allowsLocalPluginSource(String? plugin, String text) =>
      plugin == 'flutter_skill_lints' && _hasYamlKey(text, 'path') && !_hasYamlKey(text, 'git');

  bool _flowStyleHasProhibitedLocalSource(String text) {
    if (!_lineHasLocalSource(text)) return false;
    final withoutAllowedFlutterSkillPath = text.replaceAll(
      RegExp(r'''['"]?flutter_skill_lints['"]?\s*:\s*\{[^}]*['"]?path['"]?\s*:[^}]*\}'''),
      '',
    );
    return _lineHasLocalSource(withoutAllowedFlutterSkillPath);
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

bool _hasDeterministicFlutterE2eEntrypoint(String text) {
  final extensionCall = RegExp(r'\benableFlutterDriverExtension\s*\(').firstMatch(text);
  if (extensionCall == null) return false;

  final afterExtension = text.substring(extensionCall.end);
  return RegExp(r'\brunApp(?:\s*<[^>]+>)?\s*\(').hasMatch(afterExtension) ||
      RegExp(r'\b[A-Za-z_]\w*\.run[A-Z][A-Za-z0-9_]*\s*\(').hasMatch(afterExtension);
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
