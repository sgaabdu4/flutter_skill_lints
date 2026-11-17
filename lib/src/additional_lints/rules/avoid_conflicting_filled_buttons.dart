import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/instance_creation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Refuses filled buttons with different fill colours in one `Row` or `Wrap`.
final class AvoidConflictingFilledButtons extends InstanceCreationRule {
  static const LintCode code = LintCode(
    'avoid_conflicting_filled_buttons',
    'Filled buttons with different fill colours compete for attention in one Row or Wrap.',
    correctionMessage:
        'Keep one filled button for the main action and use an outlined, text or tonal button '
        'for the others. Give buttons for an equal choice the same fill.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidConflictingFilledButtons()
    : super(
        name: 'avoid_conflicting_filled_buttons',
        description:
            'Flags two or more FilledButton or ElevatedButton widgets with different fill colours '
            'in one Row or Wrap.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  static const _rowChecker = TypeChecker.any([
    TypeChecker.fromName('Row', packageName: 'flutter'),
    TypeChecker.fromName('Wrap', packageName: 'flutter'),
  ]);
  static const _filledButtonChecker = TypeChecker.any([
    TypeChecker.fromName('FilledButton', packageName: 'flutter'),
    TypeChecker.fromName('ElevatedButton', packageName: 'flutter'),
    TypeChecker.fromName('FilledButton', packageName: 'material_ui'),
    TypeChecker.fromName('ElevatedButton', packageName: 'material_ui'),
  ]);
  static const _propertyAllNames = {'WidgetStatePropertyAll', 'MaterialStatePropertyAll'};
  static const _maxWrapperDepth = 4;

  final AvoidConflictingFilledButtons rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type == null || !_rowChecker.isExactlyType(type)) return;
    final children = namedArgumentExpression(node.argumentList, 'children');
    if (children is! ListLiteral) return;
    final fills = <String>{};
    var buttons = 0;
    for (final element in children.elements) {
      final button = element is Expression ? _filledButtonIn(element, 0) : null;
      if (button == null) continue;
      buttons++;
      fills.add(_fillOf(button));
    }
    if (buttons >= 2 && fills.length > 1) rule.reportAtNode(node.constructorName);
  }

  InstanceCreationExpression? _filledButtonIn(Expression expression, int depth) {
    if (depth > _maxWrapperDepth) return null;
    return switch (expression) {
      ParenthesizedExpression(:final expression) => _filledButtonIn(expression, depth + 1),
      InstanceCreationExpression(:final staticType?)
          when _filledButtonChecker.isExactlyType(staticType) =>
        expression,
      InstanceCreationExpression(:final argumentList) => switch (namedArgumentExpression(
        argumentList,
        'child',
      )) {
        final child? => _filledButtonIn(child, depth + 1),
        null => null,
      },
      _ => null,
    };
  }

  String _fillOf(InstanceCreationExpression button) {
    final style = namedArgumentExpression(button.argumentList, 'style');
    if (style == null || style is NullLiteral) return 'default';
    final arguments = switch (style) {
      InstanceCreationExpression(:final argumentList) => argumentList,
      MethodInvocation(:final argumentList) => argumentList,
      _ => null,
    };
    if (arguments == null) return 'style:${style.toSource()}';
    final color = namedArgumentExpression(arguments, 'backgroundColor');
    if (color == null || color is NullLiteral) return 'default';
    return 'color:${_colourKey(_withoutPropertyWrapper(color))}';
  }

  Expression _withoutPropertyWrapper(Expression color) {
    final (name, arguments) = switch (color) {
      InstanceCreationExpression(:final constructorName, :final argumentList) => (
        constructorName.type.name.lexeme,
        argumentList,
      ),
      MethodInvocation(:final methodName, :final argumentList, :final target) => (
        target is SimpleIdentifier && methodName.name == 'all' ? target.name : null,
        argumentList,
      ),
      _ => (null, null),
    };
    final isWrapper =
        name != null && (_propertyAllNames.contains(name) || name == 'WidgetStateProperty');
    final first = arguments?.arguments.firstOrNull?.argumentExpression;
    return isWrapper && first != null ? first : color;
  }

  String _colourKey(Expression color) =>
      color.computeConstantValue()?.value?.toString() ?? color.toSource();
}
