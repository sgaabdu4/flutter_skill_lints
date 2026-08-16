import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/file_system/file_system.dart';

import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/pubspec_rule_utils.dart';

abstract class PubspecAnalysisRule extends NodeRegistrationRule {
  PubspecAnalysisRule({required super.name, required super.description, required super.code});

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final root = context.package?.root;
    if (root == null || !isPubspecAnchorUnit(root, context)) return;

    final pubspecText = readFileText(root.getFile('pubspec.yaml'));
    if (!shouldRegister(root, context, pubspecText)) return;

    registry.addCompilationUnit(this, createVisitor());
  }

  bool shouldRegister(Folder root, RuleContext context, String? pubspecText) {
    return pubspecText != null && shouldRegisterPubspec(pubspecText);
  }

  bool shouldRegisterPubspec(String text) => true;
}
