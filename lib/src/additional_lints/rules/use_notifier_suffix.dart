import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/class_suffix_validator.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Reports Riverpod notifier classes that do not use the `Notifier` suffix.
///
/// Riverpod codegen strips the suffix when creating provider names, so the
/// conventional `class FooNotifier extends _$FooNotifier` shape keeps generated
/// providers predictable. Covers manual notifiers, generated `_$Foo` bases and
/// `@riverpod` classes before code generation.
class UseNotifierSuffix extends ClassSuffixValidator {
  static const LintCode code = LintCode(
    'use_notifier_suffix',
    'Use Notifier suffix',
    correctionMessage:
        'Rename the class to {0}Notifier so Riverpod codegen names stay predictable.',
    severity: DiagnosticSeverity.ERROR,
  );

  static const _notifier = TypeChecker.any([
    TypeChecker.fromName('AnyNotifier', packageName: 'riverpod'),
    TypeChecker.fromName('Notifier', packageName: 'riverpod'),
  ]);

  UseNotifierSuffix()
    : super(
        name: 'use_notifier_suffix',
        description: 'Reports Riverpod notifier classes that lack the suffix that codegen expects.',
        requiredSuffix: 'Notifier',
        baseClassName: 'Notifier',
        packageName: 'riverpod',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final UseNotifierSuffix rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final name = node.namePart.typeName;
    if (name.lexeme.endsWith(rule.requiredSuffix)) return;
    final element = node.declaredFragment?.element;
    if (element == null) return;
    if (UseNotifierSuffix._notifier.isSuperOf(element) || _hasRiverpodAnnotation(node)) {
      rule.reportAtToken(name, arguments: [name.lexeme]);
    }
  }

  bool _hasRiverpodAnnotation(ClassDeclaration node) {
    return node.metadata.any((annotation) {
      final element = annotation.element;
      final isRiverpod = switch (element) {
        ConstructorElement(:final enclosingElement) => enclosingElement.name == 'Riverpod',
        PropertyAccessorElement(:final name) => name == 'riverpod',
        _ => false,
      };
      final library = element?.library?.uri.toString() ?? '';
      return isRiverpod && library.startsWith('package:riverpod_annotation/');
    });
  }
}
