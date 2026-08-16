import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/pubspec_rule.dart';

/// Reports pubspec publish targets that are not `none`.
final class PreferPublishToNone extends PubspecAnalysisRule {
  static const LintCode code = LintCode(
    'prefer_publish_to_none',
    'Prefer `publish_to: none` for app and private package pubspecs.',
    correctionMessage: 'Set publish_to to none when this package should not be published.',
  );

  PreferPublishToNone()
    : super(
        name: 'prefer_publish_to_none',
        description: 'Reports pubspec publish_to values other than none.',
        code: code,
      );

  @override
  bool shouldRegisterPubspec(String text) => _hasNonNonePublishTarget(text);

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferPublishToNone rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    rule.reportAtToken(node.beginToken);
  }
}

bool _hasNonNonePublishTarget(String text) {
  final match = RegExp(
    r'''^\s*publish_to\s*:\s*['"]?([^'"#\s]+)['"]?\s*(?:#.*)?$''',
    multiLine: true,
  ).firstMatch(text);
  final target = match?.group(1);

  return target != null && target != 'none';
}
