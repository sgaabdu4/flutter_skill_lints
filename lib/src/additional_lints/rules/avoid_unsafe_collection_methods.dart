import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';
import 'avoid_unsafe_reduce.dart';

/// Reports `first` and `single` reads that can throw on empty iterables.
class AvoidUnsafeCollectionMethods extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unsafe_collection_methods',
    'Reading {0} without proving the iterable is non-empty can throw.',
    correctionMessage: 'Check isNotEmpty first or use a nullable/checked lookup.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidUnsafeCollectionMethods()
    : super(
        name: 'avoid_unsafe_collection_methods',
        description: 'Reports first and single reads on iterables that may be empty.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addPrefixedIdentifier(this, visitor);
    registry.addPropertyAccess(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnsafeCollectionMethods rule;

  _Visitor(this.rule);

  static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');
  static const _unsafeProperties = {'first', 'single'};

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _check(node, node.prefix, node.identifier.name);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.target;
    if (target == null) return;

    _check(node, target, node.propertyName.name);
  }

  void _check(AstNode reportNode, Expression target, String propertyName) {
    if (!_unsafeProperties.contains(propertyName)) return;
    if (!_isIterable(target)) return;
    if (hasNonEmptyProof(reportNode, target)) return;

    rule.reportAtNode(reportNode, arguments: [propertyName]);
  }

  static bool _isIterable(Expression expression) {
    final type = expression.staticType;
    return type != null && _iterableChecker.isAssignableFromType(type);
  }
}
