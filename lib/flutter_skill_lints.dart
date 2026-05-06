/// Analyzer plugin entrypoint for Flutter skill lint rules.
library;

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:flutter_skill_lints/src/additional_lints/additional_lints.dart';
import 'package:flutter_skill_lints/src/rules.dart';

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
      registry.registerWarningRule(rule);
    }
  }
}
