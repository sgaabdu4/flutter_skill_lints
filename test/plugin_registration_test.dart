// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:analysis_server_plugin/src/registry.dart';
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
    final registry = PluginRegistryImpl('flutter_skill_lints');
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
    final registry = PluginRegistryImpl('flutter_skill_lints');
    final plugin = FlutterSkillLintsPlugin();

    plugin.register(registry);

    for (final rule in registry.warningRules.values) {
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

  test('ref-read-in-build diagnostic explains callback reads', () {
    final registry = PluginRegistryImpl('flutter_skill_lints_additional');
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
    final registry = PluginRegistryImpl('flutter_skill_lints_additional');
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
      ...Directory(
        'lib/src/rules',
      ).listSync().whereType<File>().where((file) => file.path.endsWith('.dart')),
      ...Directory(
        'lib/src/additional_lints/rules',
      ).listSync().whereType<File>().where((file) => file.path.endsWith('.dart')),
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

  test('registers the additional analyzer surface inspired by many_lints', () {
    final registry = PluginRegistryImpl('flutter_skill_lints_additional');
    final plugin = AdditionalLintsPlugin();

    plugin.register(registry);

    final registeredFixCount = registry.fixKinds.values.fold<int>(
      0,
      (count, rules) => count + rules.length,
    );

    expect(registry.warningRules.length, _enabledAdditionalRuleCount);
    expect(registeredFixCount, 64);
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
    expect(registry.warningRules, isNot(contains('avoid_public_notifier_properties')));
    expect(registry.warningRules, isNot(contains('avoid_ref_inside_state_dispose')));
    expect(registry.warningRules, isNot(contains('prefer_switch_expression')));
  });

  test('registers every additional analyzer rule file', () {
    final registry = PluginRegistryImpl('flutter_skill_lints_additional');
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
    ]) {
      expect(paths, isNot(contains(forbidden)));
    }
  });

  test('appends Flutter skill rules after additional analyzer rules', () {
    final registry = PluginRegistryImpl('flutter_skill_lints');
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

const _enabledFlutterSkillRuleCount = 110;
const _enabledFlutterSkillDiagnosticCount = 117;
const _enabledAdditionalRuleCount = 81;

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
