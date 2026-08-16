import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Flags custom widget classes that return Flutter slivers without a Sliver prefix.
final class PreferSliverPrefix extends CompilationUnitRule {
  static const LintCode code = LintCode(
    'prefer_sliver_prefix',
    'Prefix custom sliver widget classes with `Sliver`.',
    correctionMessage: 'Rename this widget so its class name starts with `Sliver`.',
  );

  PreferSliverPrefix()
    : super(
        name: 'prefer_sliver_prefix',
        description:
            'Flags StatelessWidget and StatefulWidget classes that build Flutter slivers '
            'but are not prefixed with Sliver.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferSliverPrefix rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final statefulWidgets = <ClassDeclaration>[];
    final states = <ClassDeclaration>[];

    for (final declaration in node.declarations.whereType<ClassDeclaration>()) {
      final element = declaration.declaredFragment?.element;
      if (element == null) continue;

      if (flutterStatelessWidgetChecker.isSuperOf(element)) {
        _checkStatelessWidget(declaration);
      } else if (flutterStatefulWidgetChecker.isSuperOf(element)) {
        statefulWidgets.add(declaration);
      } else if (flutterStateChecker.isSuperOf(element)) {
        states.add(declaration);
      }
    }

    for (final widget in statefulWidgets) {
      _checkStatefulWidget(widget, states);
    }
  }

  void _checkStatelessWidget(ClassDeclaration node) {
    final className = node.namePart.typeName.lexeme;
    if (_hasSliverPrefix(className)) return;
    if (!_buildReturnsFlutterSliver(node)) return;

    rule.reportAtToken(node.namePart.typeName);
  }

  void _checkStatefulWidget(ClassDeclaration widget, List<ClassDeclaration> states) {
    final widgetName = widget.namePart.typeName.lexeme;
    if (_hasSliverPrefix(widgetName)) return;

    final state = _findStateForWidget(states, widgetName);
    if (state == null || !_buildReturnsFlutterSliver(state)) return;

    rule.reportAtToken(widget.namePart.typeName);
  }
}

bool _hasSliverPrefix(String name) => name.startsWith('Sliver');

bool _buildReturnsFlutterSliver(ClassDeclaration node) {
  final body = node.body;
  if (body is! BlockClassBody) return false;

  final build = body.members.whereType<MethodDeclaration>().firstWhereOrNull(
    (member) => member.name.lexeme == 'build',
  );
  if (build == null) return false;

  final expression = maybeGetSingleReturnExpression(build.body);
  return expression != null && _isFlutterSliverExpression(expression);
}

bool _isFlutterSliverExpression(Expression expression) {
  final type = expression.staticType;
  if (type is! InterfaceType) return false;

  final element = type.element;
  final typeName = element.name;
  if (typeName == null || !typeName.startsWith('Sliver')) return false;

  return element.library.identifier.startsWith('package:flutter/');
}

ClassDeclaration? _findStateForWidget(List<ClassDeclaration> states, String widgetName) {
  for (final state in states) {
    final superclass = state.extendsClause?.superclass;
    if (superclass == null) continue;

    final typeArguments = superclass.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.length != 1) continue;

    final typeArgument = typeArguments.single;
    if (typeArgument is NamedType && typeArgument.name.lexeme == widgetName) {
      return state;
    }
  }

  return null;
}
