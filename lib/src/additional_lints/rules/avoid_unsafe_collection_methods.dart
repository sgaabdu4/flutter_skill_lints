import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unsafe_reduce.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Reports `first` and `single` reads that can throw on empty iterables.
///
/// Test files are skipped: a `StateError` there fails the test, which is the
/// intended outcome (testing.md reads `.first`/`.single` in expectations).
class AvoidUnsafeCollectionMethods extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unsafe_collection_methods',
    'Reading {0} without proving the iterable is non-empty can throw.',
    correctionMessage: 'Check isNotEmpty first or use a nullable/checked lookup.',
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
    if (isTestSourceContext(context)) return;
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
    if (_hasAdjacentLengthAssertion(reportNode, target, propertyName)) return;

    rule.reportAtNode(reportNode, arguments: [propertyName]);
  }

  static bool _isIterable(Expression expression) {
    final type = expression.staticType;
    return type != null && _iterableChecker.isAssignableFromType(type);
  }
}

bool _hasAdjacentLengthAssertion(AstNode use, Expression target, String propertyName) {
  if (target is! SimpleIdentifier || target.element is! LocalElement) return false;
  final statement = _directAssertionStatement(use);
  if (statement == null) return false;
  final assertion = _precedingAssertion(statement);
  if (assertion == null) return false;
  final expectedLength = _assertedLength(assertion, target.element);
  return expectedLength != null &&
      (propertyName == 'single' ? expectedLength == 1 : expectedLength > 0);
}

ExpressionStatement? _directAssertionStatement(AstNode use) {
  Statement? statement;
  for (AstNode? current = use; current != null; current = current.parent) {
    if (current is FunctionExpression) return null;
    if (current is Statement) {
      statement = current;
      break;
    }
  }
  if (statement is! ExpressionStatement || statement.expression is! MethodInvocation) {
    return null;
  }
  final useAssertion = statement.expression as MethodInvocation;
  if (useAssertion.target != null ||
      !_isTestAssertion(useAssertion.methodName.element) ||
      useAssertion.argumentList.arguments.firstOrNull != use) {
    return null;
  }
  return statement;
}

MethodInvocation? _precedingAssertion(ExpressionStatement statement) {
  final block = statement.parent;
  if (block is! Block) return null;
  final index = block.statements.indexOf(statement);
  if (index < 1) return null;
  final previous = block.statements[index - 1];
  if (previous is! ExpressionStatement || previous.expression is! MethodInvocation) return null;
  final assertion = previous.expression as MethodInvocation;
  if (assertion.target != null ||
      !_isTestAssertion(assertion.methodName.element) ||
      assertion.argumentList.arguments.length != 2) {
    return null;
  }
  return assertion;
}

int? _assertedLength(MethodInvocation assertion, Element? target) {
  final actual = assertion.argumentList.arguments.first;
  final matcher = assertion.argumentList.arguments.last;
  if (actual is! SimpleIdentifier || actual.element != target || matcher is! MethodInvocation) {
    return null;
  }
  final length = matcher.argumentList.arguments.singleOrNull;
  if (matcher.target != null ||
      matcher.methodName.name != 'hasLength' ||
      !_isMatcherHasLength(matcher.methodName.element) ||
      length is! IntegerLiteral) {
    return null;
  }
  return length.value;
}

bool _isTestAssertion(Element? element) =>
    element is TopLevelFunctionElement &&
    element.name == 'expect' &&
    (element.library.identifier.startsWith('package:test_api/') ||
        element.library.identifier.startsWith('package:flutter_test/'));

bool _isMatcherHasLength(Element? element) =>
    element is TopLevelFunctionElement &&
    element.name == 'hasLength' &&
    (element.library.identifier.startsWith('package:matcher/') ||
        element.library.identifier.startsWith('package:test_api/') ||
        element.library.identifier.startsWith('package:flutter_test/'));
