import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a widget's build method returns a sliver widget but the class
/// name does not include 'Sliver'.
///
/// Consistent sliver naming helps developers quickly identify
/// which widgets are sliver-based and can be used inside CustomScrollView.
class UseSliverPrefix extends CompilationUnitRule {
  static const LintCode code = LintCode(
    'use_sliver_prefix',
    "Widget returns a sliver but its name does not include 'Sliver'.",
    correctionMessage: "Include 'Sliver' in the class name.",
  );

  UseSliverPrefix()
    : super(
        name: 'use_sliver_prefix',
        description: 'Warns when a widget returns a sliver but lacks Sliver in its name.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final UseSliverPrefix rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final classes = _classGroups(node);
    _reportStatelessSliverWidgets(classes.statelessWidgets);
    _reportStatefulSliverWidgets(classes.statefulWidgets, classes.stateClasses);
  }

  ({
    List<ClassDeclaration> stateClasses,
    List<ClassDeclaration> statefulWidgets,
    List<ClassDeclaration> statelessWidgets,
  })
  _classGroups(CompilationUnit node) {
    final statefulWidgets = <ClassDeclaration>[];
    final stateClasses = <ClassDeclaration>[];
    final statelessWidgets = <ClassDeclaration>[];
    for (final declaration in node.declarations.whereType<ClassDeclaration>()) {
      final element = declaration.declaredFragment?.element;
      if (element == null) continue;
      final className = declaration.namePart.typeName.lexeme;
      if (flutterStatelessWidgetChecker.isSuperOf(element)) {
        statelessWidgets.add(declaration);
      } else if (flutterStatefulWidgetChecker.isSuperOf(element)) {
        statefulWidgets.add(declaration);
      } else if (flutterStateChecker.isSuperOf(element)) {
        stateClasses.add(declaration);
      }
      if (_hasSliverName(className)) {
        statelessWidgets.remove(declaration);
        statefulWidgets.remove(declaration);
      }
    }
    return (
      statelessWidgets: statelessWidgets,
      statefulWidgets: statefulWidgets,
      stateClasses: stateClasses,
    );
  }

  void _reportStatelessSliverWidgets(List<ClassDeclaration> widgets) {
    for (final widget in widgets) {
      if (_buildReturnsSliverWidget(widget)) rule.reportAtToken(widget.namePart.typeName);
    }
  }

  void _reportStatefulSliverWidgets(
    List<ClassDeclaration> widgets,
    List<ClassDeclaration> stateClasses,
  ) {
    for (final widget in widgets) {
      final widgetName = widget.namePart.typeName.lexeme;
      final stateClass = findStateClass(stateClasses, widgetName);
      if (stateClass != null && _buildReturnsSliverWidget(stateClass)) {
        rule.reportAtToken(widget.namePart.typeName);
      }
    }
  }

  static bool _hasSliverName(String name) => name.toLowerCase().contains('sliver');

  /// Checks if a class has a `build()` method that returns a sliver widget.
  static bool _buildReturnsSliverWidget(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return false;

    final buildMethod = body.members.whereType<MethodDeclaration>().firstWhereOrNull(
      (m) => m.name.lexeme == 'build',
    );

    if (buildMethod == null) return false;

    final returnExpr = maybeGetSingleReturnExpression(buildMethod.body);
    if (returnExpr == null) return false;

    return _isSliverExpression(returnExpr);
  }

  /// Checks if the expression's static type is a sliver widget from Flutter.
  static bool _isSliverExpression(Expression expression) {
    final type = expression.staticType;
    if (type is! InterfaceType) return false;

    final typeName = type.element.name;
    if (typeName == null) return false;

    // Check if the type name starts with 'Sliver' and is from Flutter
    if (!typeName.startsWith('Sliver')) return false;

    final libraryUri = type.element.library.identifier;
    return libraryUri.startsWith('package:flutter/');
  }
}
