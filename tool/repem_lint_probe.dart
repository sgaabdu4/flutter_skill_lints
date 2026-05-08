// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:analysis_server_plugin/src/registry.dart';
import 'package:flutter_skill_lints/flutter_skill_lints.dart';

const _defaultRepemRoot = '/Users/abid/Workspaces/afenso/repem';
const _probeDirName = 'flutter_skill_lints_probe';

Future<void> main(List<String> args) async {
  final repemRoot = Directory(args.isEmpty ? _defaultRepemRoot : args.first);
  if (!repemRoot.existsSync()) {
    stderr.writeln('Repem root does not exist: ${repemRoot.path}');
    exitCode = 64;
    return;
  }

  final registeredCodes = _registeredCodes();
  final cases = <String, ProbeCase>{};
  for (final probeCase in [
    ..._localPropertyCases(),
    ..._localRuleAssignmentCases(),
    ..._localAssertReportsCases(),
    ..._localAssertRuleDiagnosticCases(),
    ..._manyLintCases(registeredCodes),
  ]) {
    if (!registeredCodes.contains(probeCase.code)) continue;
    cases.putIfAbsent(probeCase.code, () => probeCase);
  }

  final probeRoots = [
    Directory('${repemRoot.path}/lib/$_probeDirName'),
    Directory('${repemRoot.path}/test/$_probeDirName'),
    Directory('${repemRoot.path}/functions/$_probeDirName'),
  ];

  for (final root in probeRoots) {
    if (root.existsSync()) {
      stderr.writeln('Refusing to overwrite existing probe directory: ${root.path}');
      exitCode = 65;
      return;
    }
  }

  final writtenFiles = <File>[];
  final hookEnvironment = HookProbeEnvironment(repemRoot);
  final configEnvironment = ConfigProbeEnvironment(repemRoot);
  try {
    await hookEnvironment.setUp();
    writtenFiles.addAll(_writeCases(repemRoot, cases.values));
    final sourceAnalysis = await _runDartAnalyze(repemRoot, label: 'source probes');
    final configResults = await configEnvironment.run();
    final observedCodes = {
      ..._observedDiagnosticCodes(sourceAnalysis.output),
      for (final result in configResults) ...result.observedCodes,
    };
    final configProbeCodes = {for (final result in configResults) result.expectedCode};
    final probedCodes = {...cases.keys, ...configProbeCodes};
    final missingDiagnostics = probedCodes.difference(observedCodes).toList()..sort();
    final missingProbeCases = registeredCodes.difference(probedCodes).toList()..sort();

    stdout.writeln('registered=${registeredCodes.length}');
    stdout.writeln('probe_cases=${probedCodes.length}');
    stdout.writeln('observed_expected=${probedCodes.intersection(observedCodes).length}');
    stdout.writeln('missing_diagnostics=${missingDiagnostics.length}');
    for (final code in missingDiagnostics) {
      final location = cases[code]?.relativePath ?? configEnvironment.locationFor(code);
      stdout.writeln('missing_diagnostic $code -> $location');
    }
    stdout.writeln('missing_probe_cases=${missingProbeCases.length}');
    for (final code in missingProbeCases) {
      stdout.writeln('missing_probe_case $code');
    }

    final analyses = [sourceAnalysis, for (final result in configResults) result.analysis];
    if (analyses.any((analysis) => analysis.hasServerFailure)) {
      for (final analysis in analyses.where((analysis) => analysis.hasServerFailure)) {
        stderr.writeln('Analyzer failure during ${analysis.label}:');
        stderr.writeln(analysis.output);
      }
      exitCode = 1;
      return;
    }

    if (missingDiagnostics.isNotEmpty || missingProbeCases.isNotEmpty) {
      exitCode = 1;
    }
  } finally {
    for (final file in writtenFiles.reversed) {
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    for (final root in probeRoots.reversed) {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    }
    await hookEnvironment.restore();
  }
}

Future<AnalyzeRun> _runDartAnalyze(Directory root, {required String label}) async {
  final result = await Process.run('dart', [
    'analyze',
    '--format=machine',
  ], workingDirectory: root.path);
  return AnalyzeRun(
    label: label,
    exitCode: result.exitCode,
    output: '${result.stdout}\n${result.stderr}',
  );
}

Set<String> _registeredCodes() {
  final registry = PluginRegistryImpl('flutter_skill_lints');
  FlutterSkillLintsPlugin().register(registry);
  return {
    for (final rule in registry.warningRules.values)
      for (final code in rule.diagnosticCodes) code.lowerCaseName,
  };
}

List<ProbeCase> _localPropertyCases() {
  final cases = <ProbeCase>[];
  for (final fileName in [
    'test/source_scanner_rules_test.dart',
    'test/extended_source_rules_test.dart',
  ]) {
    final file = File(fileName);
    if (!file.existsSync()) continue;
    for (final block in _reflectiveBlocks(file.readAsStringSync())) {
      final code = _firstMatch(block.body, RegExp(r"String get ruleName => '([^']+)'"));
      final source = _extractGetterSource(block.body);
      if (code == null || source == null) continue;
      cases.add(ProbeCase(code, _probePathFor(code, block.body), source));
    }
  }
  cases.addAll(_inheritedLocalPropertyCases());
  return cases;
}

List<ProbeCase> _localRuleAssignmentCases() {
  final file = File('test/flutter_skill_rules_test.dart');
  if (!file.existsSync()) return const [];

  final runtimeTypeCodes = _runtimeTypeCodes();
  final cases = <ProbeCase>[];
  for (final block in _reflectiveBlocks(file.readAsStringSync())) {
    final ruleType = _firstMatch(block.body, RegExp(r'rule = (\w+)\(\);'));
    final code = ruleType == null ? null : runtimeTypeCodes[ruleType];
    final source = _firstMatch(
      block.body,
      RegExp(r"const source = r?'''\n([\s\S]*?)\n'''", multiLine: true),
    );
    if (code == null || source == null) continue;
    cases.add(ProbeCase(code, _defaultPathFor(code), source));
  }
  return cases;
}

List<ProbeCase> _localAssertReportsCases() {
  final file = File('test/flutter_optimization_source_rules_test.dart');
  if (!file.existsSync()) return const [];

  final cases = <ProbeCase>[];
  for (final block in _reflectiveBlocks(file.readAsStringSync())) {
    final code = _firstMatch(block.body, RegExp(r"String get ruleName => '([^']+)'"));
    final source = _firstMatch(
      block.body,
      RegExp(r"assertReports\(\s*r?'''\n([\s\S]*?)\n'''", multiLine: true),
    );
    if (code == null || source == null) continue;
    cases.add(ProbeCase(code, _defaultPathFor(code), source));
  }
  return cases;
}

List<ProbeCase> _localAssertRuleDiagnosticCases() {
  final file = File('test/persistence_crash_source_rules_test.dart');
  if (!file.existsSync()) return const [];

  final cases = <ProbeCase>[];
  for (final block in _reflectiveBlocks(file.readAsStringSync())) {
    final code = _firstMatch(block.body, RegExp(r"String get ruleName => '([^']+)'"));
    final source = _firstMatch(
      block.body,
      RegExp(r"assertRuleDiagnostic\(\s*r?'''\n([\s\S]*?)\n'''", multiLine: true),
    );
    if (code == null || source == null) continue;
    cases.add(ProbeCase(code, _probePathFor(code, block.body, useExplicitPath: true), source));
  }
  return cases;
}

List<ProbeCase> _inheritedLocalPropertyCases() {
  const notifierFixture = r'''
class Notifier<T> {
  Ref get ref => Ref();
}

class Ref {
  Object watch(Object provider) => Object();
}

class Repository {
  void save() {}
}

final provider = Object();

class TodosNotifier extends Notifier<int> {
  final Repository _repository = Repository();

  void updateTodo() {
    ref.watch(provider);
    _repository.save();
  }
}
''';
  return const [
    ProbeCase(
      'notifier_ensure_deps',
      'lib/flutter_skill_lints_probe/notifier_ensure_deps.dart',
      notifierFixture,
    ),
    ProbeCase(
      'notifier_watch_method',
      'lib/flutter_skill_lints_probe/notifier_watch_method.dart',
      notifierFixture,
    ),
    ProbeCase(
      'ui_snackbar_boundary',
      'lib/features/todos/presentation/widgets/flutter_skill_lints_probe_todo_view.dart',
      'void build(context) { ScaffoldMessenger.of(context).showSnackBar(Object()); }',
    ),
    ProbeCase(
      'use_closest_build_context',
      'lib/flutter_skill_lints_probe/use_closest_build_context.dart',
      r'''
import 'package:flutter/widgets.dart';

class Host {
  void show({required Widget Function(BuildContext context) builder}) {}
}

extension HostContext on BuildContext {
  void show({required Widget Function(BuildContext context) builder}) {}
}

class Child extends Widget {
  const Child({required BuildContext hostContext});
}

class Sheet {
  static void show(BuildContext context) => context.show(
    builder: (sheetContext) => Child(hostContext: context),
  );
}
''',
    ),
  ];
}

List<ProbeCase> _manyLintCases(Set<String> registeredCodes) {
  final home = Platform.environment['HOME'];
  if (home == null) return const [];
  final testRoot = Directory('$home/.pub-cache/hosted/pub.dev/many_lints-0.4.0/test');
  if (!testRoot.existsSync()) return const [];

  final cases = <ProbeCase>[];
  for (final code in registeredCodes) {
    final testFile = File('${testRoot.path}/${code}_test.dart');
    if (!testFile.existsSync()) continue;
    final source = _firstMatch(
      testFile.readAsStringSync(),
      RegExp(r"assertDiagnostics\(\s*r?'''\n([\s\S]*?)\n'''", multiLine: true),
    );
    if (source == null) continue;
    cases.add(ProbeCase(code, _defaultPathFor(code), source));
  }
  return cases;
}

Map<String, String> _runtimeTypeCodes() {
  final registry = PluginRegistryImpl('flutter_skill_lints');
  FlutterSkillLintsPlugin().register(registry);
  final result = <String, String>{};
  for (final rule in registry.warningRules.values) {
    if (rule.diagnosticCodes.length == 1) {
      result[rule.runtimeType.toString()] = rule.diagnosticCodes.single.lowerCaseName;
    }
  }
  return result;
}

List<File> _writeCases(Directory repemRoot, Iterable<ProbeCase> cases) {
  final writtenFiles = <File>[];
  for (final probeCase in cases) {
    final file = File('${repemRoot.path}/${probeCase.relativePath}');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(_withIgnorePrefix(probeCase.source));
    writtenFiles.add(file);
  }
  return writtenFiles;
}

String _replaceRequired(String text, Pattern from, String to, String description) {
  final updated = text.replaceFirst(from, to);
  if (updated == text) {
    throw StateError('Unable to apply config probe: $description');
  }
  return updated;
}

Set<String> _observedDiagnosticCodes(String output) {
  final codes = <String>{};
  for (final rawLine in output.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final parts = line.split('|');
    if (parts.length >= 3) {
      codes.add(parts[2].toLowerCase());
    }
  }
  return codes;
}

String _withIgnorePrefix(String source) =>
    '''
// ignore_for_file: ambiguous_import, avoid_print, avoid_void_async, body_might_complete_normally, const_initialized_with_non_constant_value, const_with_non_const, const_with_non_type, creation_with_non_type, dead_code, deprecated_member_use, duplicate_definition, equal_elements_in_set, extends_non_class, final_not_initialized, hash_and_equals, invalid_annotation_target, invalid_override, invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, missing_override_of_must_be_overridden, non_abstract_class_inherits_abstract_member, not_enough_positional_arguments, override_on_non_overriding_member, redirect_to_non_class, return_of_invalid_type, type_argument_not_matching_bounds, undefined_annotation, undefined_class, undefined_enum_constant, undefined_function, undefined_getter, undefined_identifier, undefined_method, undefined_named_parameter, unused_element, unused_field, unused_import, unused_local_variable
$source
''';

String _probePathFor(String code, String body, {bool useExplicitPath = false}) {
  final explicitPath = useExplicitPath ? _firstMatch(body, RegExp(r"path:\s*'([^']+)'")) : null;
  final getterPath = _firstMatch(body, RegExp(r"String\?? get path => '([^']+)'"));
  final rawPath = explicitPath ?? getterPath;
  if (rawPath == null) return _defaultPathFor(code);

  var suffix = rawPath;
  suffix = suffix.replaceFirst(r'$testPackageLibPath', '');
  suffix = suffix.replaceFirst(r'$testPackageRootPath', '');
  if (suffix == '/main.dart') return 'lib/main_${_probeDirName}_$code.dart';
  if (suffix == '/app.dart') return 'lib/$_probeDirName/app.dart';
  if (suffix.startsWith('/lib/')) suffix = suffix.substring('/lib'.length);
  final basename = suffix.split('/').last;
  final probeBasename = 'flutter_skill_lints_probe_${code}_$basename';
  if (suffix.startsWith('/test/')) {
    final dir = suffix.substring('/test/'.length).split('/')..removeLast();
    return ['test', ...dir, probeBasename].join('/');
  }
  if (suffix.startsWith('/functions/')) {
    final dir = suffix.substring('/functions/'.length).split('/')..removeLast();
    return ['functions', ...dir, probeBasename].join('/');
  }
  if (suffix.startsWith('/')) {
    final dir = suffix.substring(1).split('/')..removeLast();
    return ['lib', ...dir, probeBasename].join('/');
  }
  return _defaultPathFor(code);
}

String _defaultPathFor(String code) {
  if (_needsTestPath(code)) return 'test/$_probeDirName/${code}_test.dart';
  return 'lib/$_probeDirName/$code.dart';
}

bool _needsTestPath(String code) =>
    code.startsWith('test_') ||
    code == 'fire_forget_in_tests' ||
    code == 'hive_test_close_missing' ||
    code == 'avoid_misused_test_matchers' ||
    code == 'prefer_expect_later' ||
    code == 'prefer_test_matchers' ||
    code == 'prefer_use_prefix';

String? _extractGetterSource(String body) {
  final matches = [
    RegExp(r"String get source =>\s*r?'''\n([\s\S]*?)\n'''").firstMatch(body),
    RegExp(r"String get source =>\s*'([^']*)';").firstMatch(body),
  ].whereType<RegExpMatch>().toList()..sort((a, b) => a.start.compareTo(b.start));
  return matches.isEmpty ? null : matches.first.group(1);
}

String? _firstMatch(String text, RegExp pattern) => pattern.firstMatch(text)?.group(1);

List<ClassBlock> _reflectiveBlocks(String source) {
  final starts = RegExp(
    r'@reflectiveTest\s+(?:final\s+)?class\s+(\w+)\s+extends\s+[^{]+\{',
  ).allMatches(source).toList();
  final blocks = <ClassBlock>[];
  for (var index = 0; index < starts.length; index++) {
    final start = starts[index];
    final end = index + 1 < starts.length ? starts[index + 1].start : source.length;
    blocks.add(ClassBlock(start.group(1)!, source.substring(start.end, end)));
  }
  return blocks;
}

final class HookProbeEnvironment {
  HookProbeEnvironment(this.repemRoot)
    : _overridesFile = File('${repemRoot.path}/pubspec_overrides.yaml'),
      _lockFile = File('${repemRoot.path}/pubspec.lock'),
      _fakePackagesRoot = Directory('${repemRoot.path}/flutter_skill_lints_probe_packages');

  final Directory repemRoot;
  final File _overridesFile;
  final File _lockFile;
  final Directory _fakePackagesRoot;
  String? _originalOverrides;
  String? _originalLock;
  var _didSetUp = false;

  Future<void> setUp() async {
    _originalOverrides = _overridesFile.existsSync() ? _overridesFile.readAsStringSync() : null;
    _originalLock = _lockFile.existsSync() ? _lockFile.readAsStringSync() : null;

    _writeFakePackage(
      name: 'flutter_hooks',
      libraryName: 'flutter_hooks',
      source: r'''
import 'package:flutter/widgets.dart';

class HookWidget extends Widget {
  const HookWidget({super.key});
  Widget build(BuildContext context) => const SizedBox();
}

T useState<T>(T initialData) => initialData;
T useMemoized<T>(T Function() valueBuilder) => valueBuilder();

class HookBuilder extends Widget {
  const HookBuilder({super.key, required this.builder});
  final Widget Function(BuildContext context) builder;
}
''',
    );
    _writeFakePackage(
      name: 'hooks_riverpod',
      libraryName: 'hooks_riverpod',
      source: r'''
import 'package:flutter/widgets.dart';

class HookConsumerWidget extends Widget {
  const HookConsumerWidget({super.key});
  Widget build(BuildContext context) => const SizedBox();
}
''',
    );

    _overridesFile.writeAsStringSync('''
dependency_overrides:
  flutter_hooks:
    path: flutter_skill_lints_probe_packages/flutter_hooks
  hooks_riverpod:
    path: flutter_skill_lints_probe_packages/hooks_riverpod
''');

    final get = await Process.run('flutter', ['pub', 'get'], workingDirectory: repemRoot.path);
    if (get.exitCode != 0) {
      stderr.writeln('flutter pub get failed while setting up hook probes.');
      stderr.writeln(get.stdout);
      stderr.writeln(get.stderr);
      throw StateError('Unable to set up hook probe dependencies.');
    }
    _didSetUp = true;
  }

  Future<void> restore() async {
    if (_originalOverrides == null) {
      if (_overridesFile.existsSync()) _overridesFile.deleteSync();
    } else {
      _overridesFile.writeAsStringSync(_originalOverrides!);
    }
    if (_originalLock == null) {
      if (_lockFile.existsSync()) _lockFile.deleteSync();
    } else {
      _lockFile.writeAsStringSync(_originalLock!);
    }
    if (_fakePackagesRoot.existsSync()) {
      _fakePackagesRoot.deleteSync(recursive: true);
    }
    if (_didSetUp) {
      final get = await Process.run('flutter', ['pub', 'get'], workingDirectory: repemRoot.path);
      if (get.exitCode != 0) {
        stderr.writeln('flutter pub get failed while restoring hook probes.');
        stderr.writeln(get.stdout);
        stderr.writeln(get.stderr);
        exitCode = get.exitCode;
      }
    }
  }

  void _writeFakePackage({
    required String name,
    required String libraryName,
    required String source,
  }) {
    final packageRoot = Directory('${_fakePackagesRoot.path}/$name');
    packageRoot.createSync(recursive: true);
    File('${packageRoot.path}/pubspec.yaml').writeAsStringSync('''
name: $name
publish_to: none

environment:
  sdk: ^3.10.0

dependencies:
  flutter:
    sdk: flutter
''');
    final lib = Directory('${packageRoot.path}/lib')..createSync(recursive: true);
    File('${lib.path}/$libraryName.dart').writeAsStringSync(source);
  }
}

final class ConfigProbeEnvironment {
  ConfigProbeEnvironment(this.repemRoot)
    : _analysisOptions = File('${repemRoot.path}/analysis_options.yaml'),
      _buildYaml = File('${repemRoot.path}/build.yaml'),
      _mainDev = File('${repemRoot.path}/lib/main_dev.dart'),
      _pubspec = File('${repemRoot.path}/pubspec.yaml');

  static final _probes = [
    const ConfigProbe(
      'cfg_analysis_options_canonical',
      'analysis_options.yaml containing legacy analyzer plugin path',
      _applyLegacyAnalyzerPluginPath,
    ),
    const ConfigProbe(
      'cfg_strict_analysis',
      'analysis_options.yaml with strict-raw-types disabled',
      _applyLooseStrictAnalysis,
    ),
    const ConfigProbe(
      'cfg_required_lints',
      'analysis_options.yaml missing unawaited_futures',
      _applyMissingRequiredLint,
    ),
    const ConfigProbe(
      'cfg_generated_exclude',
      'analysis_options.yaml missing ARB generated-file exclude',
      _applyMissingGeneratedExclude,
    ),
    const ConfigProbe(
      'cfg_freezed_annotation_ignore',
      'analysis_options.yaml missing invalid_annotation_target ignore',
      _applyMissingFreezedIgnore,
    ),
    const ConfigProbe(
      'cfg_prohibited_lint_plugins',
      'pubspec.yaml with prohibited custom_lint dependency',
      _applyProhibitedLintPlugin,
    ),
    const ConfigProbe(
      'cfg_explicit_to_json',
      'build.yaml without explicit_to_json: true',
      _applyMissingExplicitToJson,
    ),
    const ConfigProbe(
      'cfg_e2e_entrypoint',
      'lib/main_dev.dart without Flutter Driver extension before runApp',
      _applyMissingE2eEntrypoint,
    ),
  ];

  final Directory repemRoot;
  final File _analysisOptions;
  final File _buildYaml;
  final File _mainDev;
  final File _pubspec;

  String locationFor(String code) {
    for (final probe in _probes) {
      if (probe.expectedCode == code) return probe.description;
    }
    return 'config probe';
  }

  Future<List<ConfigProbeResult>> run() async {
    final results = <ConfigProbeResult>[];
    for (final probe in _probes) {
      final snapshots = [
        FileSnapshot(_analysisOptions),
        FileSnapshot(_buildYaml),
        FileSnapshot(_mainDev),
        FileSnapshot(_pubspec),
      ];
      for (final snapshot in snapshots) {
        snapshot.capture();
      }
      try {
        probe.apply(this);
        final analysis = await _runDartAnalyze(repemRoot, label: probe.description);
        results.add(
          ConfigProbeResult(
            expectedCode: probe.expectedCode,
            observedCodes: _observedDiagnosticCodes(analysis.output),
            analysis: analysis,
          ),
        );
      } finally {
        for (final snapshot in snapshots.reversed) {
          snapshot.restore();
        }
      }
    }
    return results;
  }

  String _readAnalysisOptions() => _analysisOptions.readAsStringSync();

  void _writeAnalysisOptions(String text) => _analysisOptions.writeAsStringSync(text);

  static void _applyLegacyAnalyzerPluginPath(ConfigProbeEnvironment env) {
    final text = env._readAnalysisOptions();
    env._writeAnalysisOptions('# tool/analyzer_plugins\n$text');
  }

  static void _applyLooseStrictAnalysis(ConfigProbeEnvironment env) {
    final text = env._readAnalysisOptions();
    env._writeAnalysisOptions(
      _replaceRequired(
        text,
        'strict-raw-types: true',
        'strict-raw-types: false',
        'disable strict-raw-types',
      ),
    );
  }

  static void _applyMissingRequiredLint(ConfigProbeEnvironment env) {
    final text = env._readAnalysisOptions();
    env._writeAnalysisOptions(
      _replaceRequired(
        text,
        RegExp(r'\n    - unawaited_futures\n'),
        '\n',
        'remove unawaited_futures lint',
      ),
    );
  }

  static void _applyMissingGeneratedExclude(ConfigProbeEnvironment env) {
    final text = env._readAnalysisOptions();
    env._writeAnalysisOptions(
      _replaceRequired(text, RegExp(r'\n    - "\*\*/\*\.arb"\n'), '\n', 'remove ARB exclude'),
    );
  }

  static void _applyMissingFreezedIgnore(ConfigProbeEnvironment env) {
    final text = env._readAnalysisOptions();
    env._writeAnalysisOptions(
      _replaceRequired(
        text,
        RegExp(r'\n    invalid_annotation_target: ignore\n'),
        '\n',
        'remove invalid_annotation_target ignore',
      ),
    );
  }

  static void _applyProhibitedLintPlugin(ConfigProbeEnvironment env) {
    final text = env._pubspec.readAsStringSync();
    env._pubspec.writeAsStringSync(
      _replaceRequired(
        text,
        RegExp(r'\ndev_dependencies:\n'),
        '\ndev_dependencies:\n  custom_lint: ^0.8.1\n',
        'add prohibited custom_lint dependency',
      ),
    );
  }

  static void _applyMissingExplicitToJson(ConfigProbeEnvironment env) {
    if (!env._buildYaml.existsSync()) {
      env._buildYaml.writeAsStringSync('''
targets:
  \$default:
    builders:
      json_serializable:json_serializable:
        enabled: true
''');
      return;
    }
    final text = env._buildYaml.readAsStringSync();
    env._buildYaml.writeAsStringSync(
      _replaceRequired(
        text,
        'explicit_to_json: true',
        'explicit_to_json: false',
        'disable explicit_to_json',
      ),
    );
  }

  static void _applyMissingE2eEntrypoint(ConfigProbeEnvironment env) {
    env._mainDev.parent.createSync(recursive: true);
    env._mainDev.writeAsStringSync(r'''
import 'package:flutter/widgets.dart';

void main() {
  runApp(const SizedBox());
}
''');
  }
}

typedef ConfigProbeApplier = void Function(ConfigProbeEnvironment env);

final class ConfigProbe {
  const ConfigProbe(this.expectedCode, this.description, this.apply);

  final String expectedCode;
  final String description;
  final ConfigProbeApplier apply;
}

final class ConfigProbeResult {
  const ConfigProbeResult({
    required this.expectedCode,
    required this.observedCodes,
    required this.analysis,
  });

  final String expectedCode;
  final Set<String> observedCodes;
  final AnalyzeRun analysis;
}

final class FileSnapshot {
  FileSnapshot(this.file);

  final File file;
  String? _content;
  var _existed = false;

  void capture() {
    _existed = file.existsSync();
    _content = _existed ? file.readAsStringSync() : null;
  }

  void restore() {
    if (!_existed) {
      if (file.existsSync()) file.deleteSync();
      return;
    }
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(_content!);
  }
}

final class AnalyzeRun {
  const AnalyzeRun({required this.label, required this.exitCode, required this.output});

  final String label;
  final int exitCode;
  final String output;

  bool get hasServerFailure =>
      output.contains('server.pluginError') ||
      output.contains('analysis server crashed') ||
      output.contains('Bad state: The analysis server crashed');
}

final class ClassBlock {
  const ClassBlock(this.name, this.body);

  final String name;
  final String body;
}

final class ProbeCase {
  const ProbeCase(this.code, this.relativePath, this.source);

  final String code;
  final String relativePath;
  final String source;
}
