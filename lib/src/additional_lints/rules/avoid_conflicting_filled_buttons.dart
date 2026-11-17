import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
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
  static const _maxStyleDepth = 3;

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
      for (final button in _buttonsIn(element)) {
        final fill = _fillOf(button);
        if (fill == null) continue;
        buttons++;
        fills.add(fill);
      }
    }
    if (buttons >= 2 && fills.length > 1) rule.reportAtNode(node.constructorName);
  }

  Iterable<InstanceCreationExpression> _buttonsIn(CollectionElement element) sync* {
    switch (element) {
      case IfElement(:final thenElement, :final elseElement):
        yield* _buttonsIn(thenElement);
        if (elseElement != null) yield* _buttonsIn(elseElement);
      case Expression():
        if (_filledButtonIn(element, 0) case final button?) yield button;
      default:
        break;
    }
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

  /// The fill of [button], or null when it cannot be read.
  String? _fillOf(InstanceCreationExpression button) {
    final style = namedArgumentExpression(button.argumentList, 'style');
    final kind = button.staticType?.element?.name == 'ElevatedButton' ? 'elevated' : 'filled';
    final fill = style == null ? '' : _styleFill(style, 0);
    return switch (fill) {
      null => null,
      '' => 'default:$kind',
      _ => fill,
    };
  }

  /// '' for the default fill, a key for an explicit fill, null when unreadable.
  String? _styleFill(Expression style, int depth) {
    if (style is NullLiteral) return '';
    if (style is ParenthesizedExpression) return _styleFill(style.expression, depth);
    final arguments = switch (style) {
      InstanceCreationExpression(:final argumentList, :final constructorName)
          when constructorName.type.name.lexeme == 'ButtonStyle' =>
        argumentList,
      MethodInvocation(:final argumentList, :final methodName)
          when methodName.name == 'styleFrom' =>
        argumentList,
      _ => null,
    };
    if (arguments != null) {
      final color = namedArgumentExpression(arguments, 'backgroundColor');
      if (color == null || color is NullLiteral) return '';
      return 'color:${_colourKey(_withoutPropertyWrapper(color))}';
    }
    final identifier = switch (style) {
      SimpleIdentifier() => style,
      PrefixedIdentifier(:final identifier) => identifier,
      PropertyAccess(:final propertyName) => propertyName,
      _ => null,
    };
    if (identifier == null || depth > _maxStyleDepth) return null;
    if (identifier.name == 'style' && _isButtonTheme(style)) return '';
    final initializer = _initializerOf(identifier.element, style.root);
    return initializer == null ? null : _styleFill(initializer, depth + 1);
  }

  bool _isButtonTheme(Expression style) {
    final target = switch (style) {
      PrefixedIdentifier(:final prefix) => prefix,
      PropertyAccess(:final target) => target,
      _ => null,
    };
    final name = switch (target) {
      SimpleIdentifier(:final name) => name,
      PropertyAccess(:final propertyName) => propertyName.name,
      _ => null,
    };
    return name != null && name.endsWith('ButtonTheme');
  }

  Expression? _initializerOf(Element? element, AstNode root) {
    final variable = switch (element) {
      GetterElement(:final variable) => variable,
      VariableElement() => element,
      _ => null,
    };
    if (variable == null) return null;
    final library = variable.library;
    if (library == null || library.isInSdk) return null;
    final local = _LocalDeclaration(variable);
    root.accept(local);
    if (local.found != null) return local.found?.initializer;
    final parsed = library.session.getParsedLibraryByElement(library);
    if (parsed is! ParsedLibraryResult) return null;
    try {
      final node = parsed.getFragmentDeclaration(variable.baseElement.firstFragment)?.node;
      return node is VariableDeclaration ? node.initializer : null;
    } on ArgumentError {
      return null;
    }
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

  String _colourKey(Expression color) {
    try {
      return color.computeConstantValue()?.value?.toString() ?? color.toSource();
    } on ArgumentError {
      return color.toSource();
    }
  }
}

final class _LocalDeclaration extends RecursiveAstVisitor<void> {
  _LocalDeclaration(this._variable);

  final VariableElement _variable;
  VariableDeclaration? found;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.declaredFragment?.element == _variable) found = node;
    super.visitVariableDeclaration(node);
  }
}
