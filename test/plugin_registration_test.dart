import 'dart:io';

import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:flutter_skill_lints/flutter_skill_lints.dart' as flutter_skill_lints;
import 'package:flutter_skill_lints/flutter_skill_lints.dart';
import 'package:flutter_skill_lints/src/additional_lints/additional_lints.dart';
import 'package:flutter_skill_lints/src/rules.dart';
import 'package:test/test.dart';

void main() {
  test('top-level plugin variable is a FlutterSkillLintsPlugin', () {
    expect(flutter_skill_lints.plugin, isA<FlutterSkillLintsPlugin>());
    expect(flutter_skill_lints.plugin.name, 'Flutter Skill Lints');
  });

  test('registers every rule once', () {
    final registry = _RecordingPluginRegistry('flutter_skill_lints');
    final plugin = FlutterSkillLintsPlugin();

    plugin.register(registry);

    expect(registry.warningRules.length, _enabledAdditionalRuleCount + flutterSkillRules.length);
    expect(flutterSkillRules, hasLength(_enabledFlutterSkillRuleCount));
    expect(
      flutterSkillRules
          .expand((rule) => rule.diagnosticCodes.map((code) => code.lowerCaseName))
          .toSet(),
      hasLength(_enabledFlutterSkillDiagnosticCount),
    );
    expect(registry.lintRules, isEmpty);
    expect(registry.warningRules.keys, hasLength(registry.warningRules.keys.toSet().length));
  });

  test('registered diagnostics have hover descriptions and correction messages', () {
    final registry = _RecordingPluginRegistry('flutter_skill_lints');
    final plugin = FlutterSkillLintsPlugin();

    plugin.register(registry);

    for (final rule in [...registry.warningRules.values, ...registry.lintRules.values]) {
      expect(rule.description.trim(), isNotEmpty, reason: '${rule.name} description');
      for (final code in rule.diagnosticCodes) {
        expect(
          code.correctionMessage?.trim(),
          isNotEmpty,
          reason: '${code.lowerCaseName} correctionMessage',
        );
      }
    }
  });

  test('skill lint references resolve to registered diagnostics', () {
    final skillRegistry = _RecordingPluginRegistry('flutter_skill_lints');
    final additionalRegistry = _RecordingPluginRegistry('flutter_skill_lints_additional');

    FlutterSkillLintsPlugin().register(skillRegistry);
    AdditionalLintsPlugin().register(additionalRegistry);

    final registeredCodes = {
      ...skillRegistry.warningRules.values.expand(
        (rule) => rule.diagnosticCodes.map((code) => code.lowerCaseName),
      ),
      ...skillRegistry.lintRules.values.expand(
        (rule) => rule.diagnosticCodes.map((code) => code.lowerCaseName),
      ),
      ...additionalRegistry.warningRules.values.expand(
        (rule) => rule.diagnosticCodes.map((code) => code.lowerCaseName),
      ),
    };
    final companionSkill = Directory('.agents/skills/building-flutter-apps');
    final skillFiles = [
      File('${companionSkill.path}/SKILL.md'),
      ...Directory('${companionSkill.path}/references')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.md')),
    ];
    final issues = <String>[];
    final refs = <String>{};

    for (final file in skillFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final lintMarker = RegExp(r'\bLints?:\s*', caseSensitive: false).firstMatch(lines[i]);
        if (lintMarker == null) continue;

        final lintList = lines[i].substring(lintMarker.end);
        for (final code in _documentedLintCodes(lintList)) {
          refs.add(code);
          if (!registeredCodes.contains(code)) {
            issues.add('$normalizedPath:${i + 1} references missing lint `$code`');
          }
        }
      }
    }

    expect(refs, isNotEmpty);
    expect(refs, contains('presentation_widget_controller_state'));
    expect(issues, isEmpty, reason: issues.join('\n'));
  });

  test('documentation references exclude prose examples without hiding lint names', () {
    expect(
      _documentedLintCodes(
        '`first_rule` (required `String`), `second_rule` '
        '(numbers such as `price`, nested (including `weight`)), `unknown_rule`',
      ),
      ['first_rule', 'second_rule', 'unknown_rule'],
    );
    expect(_documentedLintCodes('`unknown`'), ['unknown']);
    expect(_documentedLintCodes('`first_rule` (example `call(value)`) and `last_rule`'), [
      'first_rule',
      'last_rule',
    ]);
  });

  test('fire-and-forget diagnostic explains reusable utility contracts', () {
    final rule = flutterSkillRules.singleWhere(
      (rule) => rule.name == 'use_unawaited_for_fire_and_forget_futures',
    );
    final code = rule.diagnosticCodes.singleWhere(
      (code) => code.lowerCaseName == 'use_unawaited_for_fire_and_forget_futures',
    );
    final message = code.correctionMessage ?? '';

    expect(message, contains('unawaited'));
    expect(message, contains('reusable utilities'));
    expect(message, contains('Future.wait'));
  });

  test('router-extra diagnostic points to typed route params, not a codec', () {
    final rule = flutterSkillRules.singleWhere((rule) => rule.name == 'router_complex_extra');
    final code = rule.diagnosticCodes.singleWhere(
      (code) => code.lowerCaseName == 'router_complex_extra',
    );
    final message = code.correctionMessage ?? '';

    expect(message, contains('stable IDs'));
    expect(message, contains('path/query params'));
    expect(message, contains('typed routes'));
    expect(message, isNot(contains('extraCodec')));
    expect(message, isNot(contains('configure')));
  });

  test('repeated id lookup diagnostics are errors', () {
    for (final name in ['linear_id_lookup_in_hot_path', 'nested_linear_lookup_by_id']) {
      final rule = flutterSkillRules.singleWhere((rule) => rule.name == name);
      final code = rule.diagnosticCodes.singleWhere((code) => code.lowerCaseName == name);

      expect(code.severity, DiagnosticSeverity.ERROR, reason: name);
    }
  });

  test('ref-read-in-build diagnostic explains callback reads', () {
    final registry = _RecordingPluginRegistry('flutter_skill_lints_additional');
    final plugin = AdditionalLintsPlugin();

    plugin.register(registry);

    final rule = registry.warningRules['avoid_ref_read_inside_build'];
    final code = rule?.diagnosticCodes.singleWhere(
      (code) => code.lowerCaseName == 'avoid_ref_read_inside_build',
    );
    final message = code?.correctionMessage ?? '';

    expect(message, contains('ref.watch'));
    expect(message, contains('callbacks'));
    expect(message, contains('ref.read'));
  });

  test('avoid-returning-widgets diagnostic explains framework override boundary', () {
    final registry = _RecordingPluginRegistry('flutter_skill_lints_additional');
    final plugin = AdditionalLintsPlugin();

    plugin.register(registry);

    final rule = registry.warningRules['avoid_returning_widgets'];
    final code = rule?.diagnosticCodes.singleWhere(
      (code) => code.lowerCaseName == 'avoid_returning_widgets',
    );
    final message = code?.correctionMessage ?? '';

    expect(message, contains('named Widget class'));
    expect(message, contains('framework build/builder overrides'));
  });

  test('Freezed value-class diagnostic explains the no mental tax convention', () {
    final rule = flutterSkillRules.singleWhere(
      (rule) => rule.name == 'freezed_required_value_class',
    );
    final code = rule.diagnosticCodes.singleWhere(
      (code) => code.lowerCaseName == 'freezed_required_value_class',
    );
    final message = code.correctionMessage ?? '';

    expect(message, contains('@freezed sealed classes'));
    expect(message, contains('mental tax'));
    expect(message, contains('do not use Equatable'));
  });

  test('rule source files document every rule with API docs', () {
    final issues = <String>[];
    final ruleFiles = [
      ...Directory('lib/src/rules')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
      ...Directory('lib/src/additional_lints/rules')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
    ];

    for (final file in ruleFiles) {
      final path = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final classMatch = RegExp(
          r'^(?:final\s+)?class\s+(\w+)\s+extends\s+(?:Multi)?AnalysisRule\b',
        ).firstMatch(line);
        if (classMatch != null) {
          final docs = _docBlockBefore(lines, i);
          if (docs.isEmpty) {
            issues.add('$path:${i + 1} ${classMatch.group(1)} is missing /// docs');
          }
          continue;
        }

        if (path.endsWith('/source_scanner_rule.dart')) continue;
        if (line.trimLeft().startsWith('scannerRule(')) {
          final codeName = _scannerRuleCodeName(lines.skip(i).take(12).join('\n'));
          final docs = _docBlockBefore(lines, i);
          if (docs.isEmpty) {
            issues.add('$path:${i + 1} $codeName is missing /// docs');
          }
        }
      }
    }

    expect(issues, isEmpty, reason: issues.join('\n'));
  });

  test('rule source files avoid app-specific symbols', () {
    final ruleSource = Directory('lib/src/rules')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => MapEntry(file.path.replaceAll('\\', '/'), file.readAsStringSync()))
        .toList();
    final issues = <String>[];

    for (final entry in ruleSource) {
      for (final forbidden in _appSpecificRuleSymbols) {
        if (entry.value.contains(forbidden)) {
          issues.add('${entry.key} contains $forbidden');
        }
      }
    }

    expect(issues, isEmpty, reason: issues.join('\n'));
  });

  test('registers the additional analyzer surface inspired by many_lints', () {
    final registry = _RecordingPluginRegistry('flutter_skill_lints_additional');
    final plugin = AdditionalLintsPlugin();

    plugin.register(registry);

    final registeredFixCount = registry.fixKinds.values.fold<int>(
      0,
      (count, rules) => count + rules.length,
    );

    expect(registry.warningRules.length, _enabledAdditionalRuleCount);
    expect(registeredFixCount, 63);
    expect(registry.assistKinds, hasLength(1));
    expect(registry.warningRules, containsPair('avoid_ref_read_inside_build', isNotNull));
    expect(registry.warningRules, containsPair('use_ref_and_state_synchronously', isNotNull));
    expect(registry.warningRules, containsPair('prefer_padding_over_container', isNotNull));
    expect(registry.warningRules, containsPair('avoid_constant_switches', isNotNull));
    expect(registry.warningRules, containsPair('prefer_class_destructuring', isNotNull));
    expect(registry.warningRules, containsPair('use_existing_destructuring', isNotNull));
    expect(registry.warningRules, isNot(contains('use_bloc_suffix')));
    expect(registry.warningRules, isNot(contains('use_cubit_suffix')));
    expect(registry.warningRules, isNot(contains('use_gap')));
    expect(registry.warningRules, isNot(contains('prefer_contains')));
    expect(registry.warningRules, containsPair('avoid_public_notifier_properties', isNotNull));
    expect(registry.warningRules, containsPair('avoid_ref_inside_state_dispose', isNotNull));
    expect(registry.warningRules, containsPair('prefer_type_over_var', isNotNull));
    expect(registry.warningRules, isNot(contains('prefer_switch_expression')));
  });

  test('registers every additional analyzer rule file', () {
    final registry = _RecordingPluginRegistry('flutter_skill_lints_additional');
    final plugin = AdditionalLintsPlugin();

    plugin.register(registry);

    final ruleFiles = Directory('lib/src/additional_lints/rules')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.uri.pathSegments.last.replaceAll('.dart', ''))
        .toSet();

    expect(ruleFiles, hasLength(_enabledAdditionalRuleCount));
    expect(registry.warningRules.keys.toSet(), ruleFiles);
  });

  test('excludes off-profile additional rule source files', () {
    final paths = Directory('lib/src/additional_lints')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.replaceAll('\\', '/'))
        .join('\n');

    for (final forbidden in [
      'avoid_bloc_public_methods',
      'avoid_passing_bloc_to_bloc',
      'avoid_passing_build_context_to_blocs',
      'prefer_bloc_extensions',
      'prefer_immutable_bloc_state',
      'prefer_multi_bloc_provider',
      'use_bloc_suffix',
      'use_cubit_suffix',
      'use_gap',
      'prefer_shorthands',
      'prefer_returning_shorthands',
      'prefer_switch_expression',
      'prefer_overriding_parent_equality',
      'list_all_equatable_fields',
      'prefer_equatable_mixin',
      'prefer_compute_over_isolate_run',
      'avoid_missing_controller',
      // No skill basis; the skill's own Debouncer.call and inline record
      // signatures (dart-patterns-records.md:61-80) contradict them.
      'avoid_declaring_call_method',
      'move_records_to_typedefs',
      // Duplicates use_dedicated_media_query_methods: one read reported twice.
      'prefer_dedicated_media_query_methods',
      // Duplicates avoid_null_bang, which core-stack.md:60 names.
      'avoid_non_null_assertion',
    ]) {
      expect(paths, isNot(contains(forbidden)));
    }
  });

  test('model skill MUST and NEVER diagnostics report at error severity', () {
    final registry = _RecordingPluginRegistry('flutter_skill_lints');
    FlutterSkillLintsPlugin().register(registry);

    for (final name in _modelSkillErrorDiagnostics) {
      final rule = registry.warningRules[name];
      expect(rule, isNotNull, reason: name);
      expect(
        rule!.diagnosticCodes.map((code) => code.severity),
        everyElement(DiagnosticSeverity.ERROR),
        reason: name,
      );
    }
  });

  test('skill MUST and NEVER sweep diagnostics report at error severity', () {
    for (final name in _sweepSkillErrorDiagnostics) {
      final rule = flutterSkillRules.singleWhere((rule) => rule.name == name);
      expect(
        rule.diagnosticCodes.map((code) => code.severity),
        everyElement(DiagnosticSeverity.ERROR),
        reason: name,
      );
    }
  });

  test('every skill diagnostic outside the non-error allowlist is an error', () {
    final nonError = <String>[
      for (final rule in flutterSkillRules)
        for (final code in rule.diagnosticCodes)
          if (code.severity != DiagnosticSeverity.ERROR) code.lowerCaseName,
    ];

    expect(nonError.where((name) => !_nonErrorSkillDiagnostics.contains(name)), isEmpty);
  });

  test('appends Flutter skill rules after additional analyzer rules', () {
    final registry = _RecordingPluginRegistry('flutter_skill_lints');
    final plugin = FlutterSkillLintsPlugin();

    plugin.register(registry);

    final registeredNames = registry.warningRules.keys.toList();
    expect(
      registeredNames.take(_enabledAdditionalRuleCount),
      contains('avoid_ref_read_inside_build'),
    );
    expect(
      registeredNames.skip(_enabledAdditionalRuleCount).toList(),
      flutterSkillRules.map((rule) => rule.name).toList(),
    );
  });
}

const _enabledFlutterSkillRuleCount = 229;
const _enabledFlutterSkillDiagnosticCount = 237;
const _enabledAdditionalRuleCount = 274;

const _modelSkillErrorDiagnostics = [
  'use_sealed_freezed_classes',
  'freezed_legacy_when_map',
  'use_freezed_instead_of_immutable',
  'vo_public_raw_constructor',
  'domain_raw_required_string',
  'domain_unit_primitive',
  'avoid_throw',
  'typed_id_raw_id',
  'avoid_positional_record_fields',
  'prefer_dot_shorthands',
  'prefer_wildcard_pattern',
  'use_existing_destructuring',
  'datetime_now_requires_timezone_intent',
  'domain_entity_primitive_factory',
  'avoid_returning_widgets',
  'prefer_class_destructuring',
  'ad_hoc_id_index_lookup',
  'ui_snackbar_boundary',
  'ad_hoc_intl_format',
  'inline_num_clamp',
  'record_use_outside_ffi',
];

/// Skill codes whose MUST/NEVER text was confirmed in the final severity sweep.
const _sweepSkillErrorDiagnostics = [
  // performance.md: "Never override `operator ==` on Widget".
  'flutter_widget_operator_equals',
  // common-patterns.md rule 7: "MUST guard page back with a typed fallback route".
  'guard_context_pop',
  // common-patterns.md rule 10: "mutation order MUST be: persist write -> targeted parent sync -> navigate".
  'state_broad_invalidation',
];

/// Skill codes that stay below error because no skill MUST/NEVER backs them.
const _nonErrorSkillDiagnostics = [
  // No skill text bans `dynamic`; the profile only enables no_dynamic_casts and avoid_dynamic_calls.
  'avoid_dynamic_except_json_maps',
  // `_ensureRepository` is only a trigger signal; no MUST/NEVER covers null repository returns.
  'avoid_silent_repository_null_return',
  // flutter-optimizations.md: "Use `CustomScrollView`, not `ListView` in `SingleChildScrollView`" (no MUST/NEVER).
  'avoid_list_in_single_child_scroll_view',
  // layout-diagnostics.md: "Adapt via LayoutBuilder/MediaQuery.sizeOf, not device type/orientation" (no MUST/NEVER).
  'avoid_orientation_layout',
  // flutter-optimizations.md: "Use `borderRadius` on `Container`, not `ClipRRect` wrap" (no MUST/NEVER).
  'avoid_clip_rrect_container',
  // Not named by the skill; performance.md rules 15/16 belong to the id-lookup and save-all lints.
  'full_collection_load_in_loop',
  // services-and-singletons.md: "The callee catches internally" (no MUST/NEVER); platform commands are unnamed.
  'unguarded_fire_and_forget_platform_command',
  // The skill never mandates this fallback check.
  'implicit_null_fallback',
  // Severity owned by the acceptance branch; not decided in this sweep.
  'select_returns_unstable_record_identity',
];

Iterable<String> _documentedLintCodes(String text) sync* {
  var depth = 0;
  final tokens = RegExp(r'`[^`]*`|[()]');
  for (final match in tokens.allMatches(text)) {
    final token = match.group(0)!;
    if (token == '(') {
      depth++;
    } else if (token == ')') {
      if (depth > 0) depth--;
    } else if (depth == 0 && RegExp(r'^`[a-z][a-z0-9_]+`$').hasMatch(token)) {
      yield token.substring(1, token.length - 1);
    }
  }
}

final class _RecordingPluginRegistry extends PluginRegistry {
  _RecordingPluginRegistry(this.pluginName);

  final String pluginName;
  final List<AssistKind> assistKinds = [];
  final Map<FixKind, List<String>> fixKinds = {};
  final Map<String, AbstractAnalysisRule> warningRules = {};
  final Map<String, AbstractAnalysisRule> lintRules = {};

  @override
  void registerLintRule(AbstractAnalysisRule rule) {
    lintRules[rule.name] = rule;
  }

  @override
  void registerWarningRule(AbstractAnalysisRule rule) {
    warningRules[rule.name] = rule;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #registerAssist) {
      assistKinds.add(const AssistKind('test_assist', 0, 'test assist'));
      return null;
    }
    if (invocation.memberName == #registerFixForRule) {
      final code = invocation.positionalArguments.first as DiagnosticCode;
      const kind = FixKind('test_fix', 0, 'test fix');
      fixKinds.putIfAbsent(kind, () => []).add(code.lowerCaseName);
      return null;
    }
    return super.noSuchMethod(invocation);
  }
}

const _appSpecificRuleSymbols = [
  'run'
      'SampleProject',
  'pop'
      'Or'
      'Go',
  'show'
      'Blurred'
      'Dialog',
  'App'
      'Navigation',
  'App'
      'Modal',
  'app'
      'Navigation'
      'CoordinatorProvider',
];

List<String> _docBlockBefore(List<String> lines, int index) {
  var cursor = index - 1;
  while (cursor >= 0 && lines[cursor].trim().isEmpty) {
    cursor--;
  }

  final docs = <String>[];
  while (cursor >= 0) {
    final line = lines[cursor].trimLeft();
    if (!line.startsWith('///')) break;
    docs.insert(0, line.substring(3).trim());
    cursor--;
  }
  return docs;
}

String _scannerRuleCodeName(String source) {
  final match = RegExp(r"LintCode\(\s*'([^']+)'", dotAll: true).firstMatch(source);
  return match == null ? 'scannerRule' : match.group(1)!;
}
