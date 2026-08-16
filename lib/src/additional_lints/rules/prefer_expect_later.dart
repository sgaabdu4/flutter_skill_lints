import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a `Future` is passed to `expect()` instead of `expectLater()`.
///
/// Not awaiting a `Future` passed to `expect` can lead to unexpected test
/// results — the assertion may complete before the asynchronous operation
/// finishes, silently passing.
///
/// **Bad:**
/// ```dart
/// expect(Future.value(1), completion(1));
/// ```
///
/// **Good:**
/// ```dart
/// await expectLater(Future.value(1), completion(1));
/// ```
class PreferExpectLater extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'prefer_expect_later',
    "Prefer 'expectLater' when testing Futures.",
    correctionMessage: "Use 'await expectLater(...)' instead of 'expect(...)'.",
  );

  PreferExpectLater()
    : super(
        code: code,
        name: 'prefer_expect_later',
        description: 'Warns when a Future is passed to expect() instead of expectLater().',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferExpectLater rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'expect') return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final actualExpr = args[0];

    final actualType = actualExpr.argumentExpression.staticType;
    if (actualType == null || actualType is DynamicType) return;

    if (_isFutureType(actualType)) {
      rule.reportAtNode(node.methodName);
    }
  }

  static bool _isFutureType(DartType type) {
    if (type is! InterfaceType) return false;
    final name = type.element.name;
    if (name == 'Future' || name == 'FutureOr') {
      return type.element.library.identifier.startsWith('dart:async');
    }
    for (final supertype in type.element.allSupertypes) {
      if ((supertype.element.name == 'Future' || supertype.element.name == 'FutureOr') &&
          supertype.element.library.identifier.startsWith('dart:async')) {
        return true;
      }
    }
    return false;
  }
}
