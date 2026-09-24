import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

/// Only expressions known not to invalidate a mounted check may follow it.
bool isPureMountedGuardSuffix(Expression expression) {
  final value = expression.unParenthesized;
  if (value is SimpleIdentifier) {
    final element = value.element;
    return element is FormalParameterElement ||
        element is LocalVariableElement && !element.isLate ||
        element is PropertyAccessorElement &&
            element.isOriginVariable &&
            _isStablePrivateField(element.variable);
  }
  if (value is BooleanLiteral ||
      value is IntegerLiteral ||
      value is StringLiteral ||
      value is NullLiteral) {
    return true;
  }
  if (value is BinaryExpression) {
    if (value.operator.lexeme != '==' && value.operator.lexeme != '!=') return false;
    final type = value.leftOperand.staticType;
    if (type == null ||
        !(type.isDartCoreBool ||
            type.isDartCoreInt ||
            type.isDartCoreString ||
            type.isDartCoreNum)) {
      return false;
    }
    return isPureMountedGuardSuffix(value.leftOperand) &&
        isPureMountedGuardSuffix(value.rightOperand);
  }
  return false;
}

/// A notifier's inherited Riverpod ref, rather than a same-named local value.
bool isRiverpodRefAccess(Expression expression) {
  final ref = switch (expression) {
    PrefixedIdentifier(:final prefix) => prefix,
    PropertyAccess(:final target) => target,
    _ => null,
  };
  final element = ref is SimpleIdentifier ? ref.element : null;
  if (element is! PropertyAccessorElement) return false;
  final library = element.library.uri.toString();
  return library.startsWith('package:riverpod/') || library.startsWith('package:flutter_riverpod/');
}

bool _isStablePrivateField(VariableElement variable) {
  if (variable is! FieldElement || !variable.isPrivate || variable.isStatic || variable.isLate) {
    return false;
  }
  final owner = variable.enclosingElement;
  if (owner is! ClassElement) return false;
  // A same-library subtype can override even a private field's getter.
  return !owner.library.classes.any(
    (candidate) =>
        candidate != owner && candidate.allSupertypes.any((type) => type.element == owner),
  );
}
