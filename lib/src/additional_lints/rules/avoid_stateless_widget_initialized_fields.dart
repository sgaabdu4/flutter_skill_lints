import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when a `StatelessWidget` declares initialized instance fields.
class AvoidStatelessWidgetInitializedFields extends ClassDeclarationCheckRule {
  static const LintCode code = LintCode(
    'avoid_stateless_widget_initialized_fields',
    'Avoid initialized instance fields in StatelessWidget classes.',
    correctionMessage: 'Pass immutable widget data through the constructor instead.',
  );

  AvoidStatelessWidgetInitializedFields()
    : super(
        name: 'avoid_stateless_widget_initialized_fields',
        description: 'Warns when StatelessWidget classes initialize instance fields.',
        code: code,
      );

  @override
  void checkClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !flutterStatelessWidgetChecker.isSuperOf(element)) return;

    for (final field in node.body.members.whereType<FieldDeclaration>()) {
      if (field.isStatic) continue;

      for (final variable in field.fields.variables) {
        if (variable.initializer == null) continue;
        reportAtToken(variable.name);
      }
    }
  }
}
