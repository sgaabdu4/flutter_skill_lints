import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/riverpod_type_checkers.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a `Notifier` or `AsyncNotifier` subclass declares a constructor
/// with a non-empty body or initializer list.
///
/// Constructors in Notifier classes should not contain initialization logic.
/// All setup should go into the `build()` method instead, which is the proper
/// lifecycle method for initialization in Riverpod.
class AvoidNotifierConstructors extends ClassDeclarationRule {
  static const LintCode code = LintCode(
    'avoid_notifier_constructors',
    'Avoid constructors with logic in Notifier classes.',
    correctionMessage: 'Move initialization logic to the build() method.',
  );

  AvoidNotifierConstructors()
    : super(
        name: 'avoid_notifier_constructors',
        description:
            'Warns when a Notifier or AsyncNotifier subclass has a '
            'constructor with a non-empty body or initializer list.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidNotifierConstructors rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!isClassAssignableTo(node, notifierChecker)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final constructor in constructorsWithLogic(body)) {
      rule.reportAtNode(constructor);
    }
  }
}
