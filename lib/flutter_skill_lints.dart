/// Analyzer plugin entrypoint for Flutter skill lint rules.
library;

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:flutter_skill_lints/src/additional_lints/additional_lints.dart';
import 'package:flutter_skill_lints/src/rules.dart';
import 'package:flutter_skill_lints/src/rules/avoid_null_bang.dart';

/// Top-level plugin variable required by `analysis_server_plugin`.
final plugin = FlutterSkillLintsPlugin();

/// Registers Flutter skill diagnostics with the Dart analysis server.
final class FlutterSkillLintsPlugin extends Plugin {
  @override
  String get name => 'Flutter Skill Lints';

  @override
  void register(PluginRegistry registry) {
    AdditionalLintsPlugin().register(registry);

    for (final rule in flutterSkillRules) {
      // The stronger avoid_non_null_assertion is enabled by default. Keep this
      // overlapping diagnostic available to clients that explicitly opt in.
      if (rule is AvoidNullBang) {
        registry.registerLintRule(rule);
      } else {
        registry.registerWarningRule(rule);
      }
    }
  }
}
