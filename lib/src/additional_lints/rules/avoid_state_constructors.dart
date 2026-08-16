import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a `State` subclass declares a constructor with a non-empty body
/// or initializer list.
///
/// Constructors in `State` objects should not contain initialization logic.
/// All setup should go into `State.initState` instead, which is the proper
/// lifecycle method for initialization.
class AvoidStateConstructors extends ClassDeclarationRule {
  static const LintCode code = LintCode(
    'avoid_state_constructors',
    'Avoid constructors with logic in State classes.',
    correctionMessage: 'Move initialization logic to initState().',
  );

  AvoidStateConstructors()
    : super(
        name: 'avoid_state_constructors',
        description:
            'Warns when a State subclass has a constructor with a '
            'non-empty body or initializer list.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidStateConstructors rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = flutterStateBody(node);
    if (body == null) return;

    for (final constructor in constructorsWithLogic(body)) {
      rule.reportAtNode(constructor);
    }
  }
}
