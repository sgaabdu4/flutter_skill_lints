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
    expect(registry.lintRules, isEmpty);
    expect(registry.warningRules.keys, hasLength(registry.warningRules.keys.toSet().length));
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
    expect(registeredFixCount, 66);
    expect(registry.assistKinds, hasLength(1));
    expect(registry.warningRules, containsPair('avoid_ref_read_inside_build', isNotNull));
    expect(registry.warningRules, containsPair('use_ref_and_state_synchronously', isNotNull));
    expect(registry.warningRules, containsPair('prefer_padding_over_container', isNotNull));
    expect(registry.warningRules, containsPair('avoid_constant_switches', isNotNull));
    expect(registry.warningRules, containsPair('prefer_class_destructuring', isNotNull));
    expect(registry.warningRules, containsPair('use_existing_destructuring', isNotNull));
    expect(registry.warningRules, containsPair('list_all_equatable_fields', isNotNull));
    expect(registry.warningRules, containsPair('prefer_equatable_mixin', isNotNull));
    expect(registry.warningRules, isNot(contains('use_bloc_suffix')));
    expect(registry.warningRules, isNot(contains('use_cubit_suffix')));
    expect(registry.warningRules, isNot(contains('use_gap')));
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

const _enabledAdditionalRuleCount = 85;
