import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Base class for rules that validate class name suffixes based on supertype.
abstract class ClassSuffixValidator extends AnalysisRule {
  final String requiredSuffix;
  final TypeChecker typeChecker;
  final LintCode _lintCode;

  /// Creates a class suffix validator rule.
  ClassSuffixValidator({
    required super.name,
    required super.description,
    required this.requiredSuffix,
    required String baseClassName,
    required String packageName,
  }) : typeChecker = TypeChecker.fromName(baseClassName, packageName: packageName),
       _lintCode = LintCode(
         name,
         'Use $requiredSuffix suffix',
         correctionMessage:
             'Rename the class to {0}$requiredSuffix so its suffix matches the required role.',
       );

  @override
  LintCode get diagnosticCode => _lintCode;

  /// Whether [node], which declares [element], must carry [requiredSuffix].
  bool requiresSuffix(ClassDeclaration node, ClassElement element) =>
      typeChecker.isSuperOf(element);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _ClassSuffixVisitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _ClassSuffixVisitor extends SimpleAstVisitor<void> {
  final ClassSuffixValidator rule;

  _ClassSuffixVisitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return;

    final name = node.namePart.typeName;
    final className = name.lexeme;

    // Check if class extends/implements the target type and lacks the suffix
    if (!className.endsWith(rule.requiredSuffix) && rule.requiresSuffix(node, element)) {
      rule.reportAtToken(name, arguments: [className]);
    }
  }
}
