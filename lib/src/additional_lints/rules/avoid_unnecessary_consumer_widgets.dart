import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/riverpod_consumer_checkers.dart';

/// Warns when a ConsumerWidget does not use WidgetRef.
///
/// A widget that never reads providers does not need Riverpod wiring, so it can
/// be a regular StatelessWidget.
class AvoidUnnecessaryConsumerWidgets extends ClassDeclarationRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_consumer_widgets',
    'ConsumerWidget does not use WidgetRef. Consider using StatelessWidget instead.',
    correctionMessage: 'Change the base class and remove unused ref parameter.',
  );

  AvoidUnnecessaryConsumerWidgets()
    : super(
        name: 'avoid_unnecessary_consumer_widgets',
        description:
            'Warns when ConsumerWidget does not use WidgetRef and can be a StatelessWidget.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryConsumerWidgets rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration cls) {
    final superclass = cls.extendsClause?.superclass;
    final superclassElement = superclass?.element;
    if (superclass == null || superclassElement == null) return;

    if (!consumerWidgetChecker.isExactly(superclassElement)) return;

    // Find build method
    final body = cls.body;
    if (body is! BlockClassBody) return;

    final buildMethod = body.members.whereType<MethodDeclaration>().firstWhereOrNull(
      (m) => m.name.lexeme == 'build',
    );

    if (buildMethod == null) return;

    // Find ref parameter
    final refParam = buildMethod.parameters?.parameters.firstWhereOrNull(
      (p) => p.name?.lexeme == 'ref',
    );

    if (refParam == null) return;

    // Check if ref is used
    final refUsed = _isIdentifierUsed(buildMethod.body, 'ref');

    if (!refUsed) {
      rule.reportAtToken(cls.namePart.typeName);
    }
  }

  bool _isIdentifierUsed(AstNode? node, String name) {
    if (node == null) return false;

    final visitor = _IdentifierVisitor(name);
    node.visitChildren(visitor);
    return visitor.used;
  }
}

class _IdentifierVisitor extends RecursiveAstVisitor<void> {
  final String name;
  bool used = false;

  _IdentifierVisitor(this.name);

  @override
  void visitSimpleIdentifier(SimpleIdentifier id) {
    if (id.name == name) used = true;
    super.visitSimpleIdentifier(id);
  }
}
