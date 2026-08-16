import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/enum_name_access.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Suggests using `.byName()` instead of `.firstWhere((e) => e.name == value)`
/// on enum values.
class PreferEnumsByName extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'prefer_enums_by_name',
    'Use .byName() instead of .firstWhere() to access enum values by name.',
    correctionMessage: 'Replace with .byName() for better readability.',
  );

  PreferEnumsByName()
    : super(
        code: code,
        name: 'prefer_enums_by_name',
        description: 'Use .byName() instead of .firstWhere() to find enum values by name.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferEnumsByName rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Check that the target is .values on an enum type
    if (!_isEnumValues(node.target)) return;

    final comparison = enumByNameCandidate(node);
    if (comparison == null) return;
    final paramName = comparison.parameterName;
    final bodyExpr = comparison.body;

    if (isEnumNameAccess(bodyExpr.leftOperand, paramName) ||
        isEnumNameAccess(bodyExpr.rightOperand, paramName)) {
      rule.reportAtNode(node);
    }
  }

  /// Checks if [target] is `SomeEnum.values` where `SomeEnum` is an enum.
  static bool _isEnumValues(Expression? target) {
    if (target case PrefixedIdentifier(
      identifier: SimpleIdentifier(name: 'values'),
      prefix: SimpleIdentifier(element: final element?),
    ) when element is EnumElement) {
      return true;
    }
    if (target case PropertyAccess(
      propertyName: SimpleIdentifier(name: 'values'),
      target: Expression(staticType: final type?),
    )) {
      final typeElement = type.element;
      return typeElement is EnumElement;
    }
    return false;
  }
}
