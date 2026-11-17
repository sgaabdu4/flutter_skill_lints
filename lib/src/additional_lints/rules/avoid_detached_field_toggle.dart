import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/instance_creation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Refuses a show or hide control for an obscured field that sits beside the field.
final class AvoidDetachedFieldToggle extends InstanceCreationRule {
  static const LintCode code = LintCode(
    'avoid_detached_field_toggle',
    'The show or hide control of an obscured field belongs inside the field.',
    correctionMessage:
        'Put an IconButton with a tooltip or semantic label in the suffixIcon of the '
        'InputDecoration. Do not use a sibling button or a text label.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidDetachedFieldToggle()
    : super(
        name: 'avoid_detached_field_toggle',
        description:
            'Flags a TextField or TextFormField with obscureText whose show or hide control is '
            'a sibling widget or a text label.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  static const _fieldChecker = TypeChecker.any([
    TypeChecker.fromName('TextField', packageName: 'flutter'),
    TypeChecker.fromName('TextFormField', packageName: 'flutter'),
  ]);
  static const _flexChecker = TypeChecker.any([
    TypeChecker.fromName('Row', packageName: 'flutter'),
    TypeChecker.fromName('Column', packageName: 'flutter'),
    TypeChecker.fromName('Wrap', packageName: 'flutter'),
    TypeChecker.fromName('Stack', packageName: 'flutter'),
  ]);
  static const _maxWrapperDepth = 4;

  final AvoidDetachedFieldToggle rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type == null || !_fieldChecker.isExactlyType(type)) return;
    final obscure = namedArgumentExpression(node.argumentList, 'obscureText');
    if (obscure == null || (obscure is BooleanLiteral && !obscure.value)) return;
    final suffixes = _suffixes(node);
    final state = _stateName(obscure);
    if (suffixes.isNotEmpty) {
      final label = _ToggleFinder(state, false);
      for (final suffix in suffixes) {
        suffix.accept(label);
      }
      if (label.labelFound) rule.reportAtNode(node.constructorName);
      return;
    }
    final toggle = _ToggleFinder(state, true);
    for (final sibling in _siblings(node)) {
      sibling.accept(toggle);
    }
    if (toggle.found) rule.reportAtNode(node.constructorName);
  }

  List<Expression> _suffixes(InstanceCreationExpression field) {
    final decoration = namedArgumentExpression(field.argumentList, 'decoration');
    final arguments = switch (decoration) {
      InstanceCreationExpression(:final argumentList) => argumentList,
      MethodInvocation(:final argumentList) => argumentList,
      _ => null,
    };
    if (arguments == null) return const [];
    return [
      for (final name in const ['suffixIcon', 'suffix']) ?namedArgumentExpression(arguments, name),
    ];
  }

  Iterable<Expression> _siblings(InstanceCreationExpression field) {
    AstNode current = field;
    for (var depth = 0; depth <= _maxWrapperDepth; depth++) {
      final parent = current.parent;
      if (parent is ListLiteral) {
        final flex = parent.parent?.parent?.parent;
        if (flex is! InstanceCreationExpression ||
            flex.staticType == null ||
            !_flexChecker.isExactlyType(flex.staticType!)) {
          return const [];
        }
        return parent.elements.whereType<Expression>().where((element) => element != current);
      }
      final isWrapper =
          parent is NamedArgument || parent is ArgumentList || parent is InstanceCreationExpression;
      if (parent == null || !isWrapper) return const [];
      current = parent;
    }
    return const [];
  }

  String? _stateName(Expression obscure) {
    var current = obscure;
    while (true) {
      if (current is ParenthesizedExpression) {
        current = current.expression;
      } else if (current is PrefixExpression && current.operator.type == TokenType.BANG) {
        current = current.operand;
      } else {
        break;
      }
    }
    return switch (current) {
      SimpleIdentifier(:final name) => name,
      PrefixedIdentifier(:final identifier) => identifier.name,
      _ => null,
    };
  }
}

final class _ToggleFinder extends RecursiveAstVisitor<void> {
  _ToggleFinder(this._stateName, this._siblingMode);

  static const _textChecker = TypeChecker.fromName('Text', packageName: 'flutter');
  static const _fieldChecker = TypeChecker.any([
    TypeChecker.fromName('TextField', packageName: 'flutter'),
    TypeChecker.fromName('TextFormField', packageName: 'flutter'),
  ]);
  static const _iconDataChecker = TypeChecker.fromName('IconData', packageName: 'flutter');
  static const _callbackNames = {'onPressed', 'onChanged', 'onTap'};
  static final _showHide = RegExp(
    r'^\s*(show|hide)(\s+(password|pass|pin|text|it|characters|secret|code))?\s*[.!]?\s*$',
    caseSensitive: false,
  );
  static final _eyeIcon = RegExp(
    r'^(visibility|visibilityOff|visibility_off|removeRedEye|remove_red_eye|eye|eyeSlash|eye_slash)'
    r'(_?(outlined|rounded|sharp|fill|solid)|(Outlined|Rounded|Sharp|Fill|Solid))?$',
  );

  final String? _stateName;
  final bool _siblingMode;
  bool labelFound = false;
  bool found = false;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type != null && _fieldChecker.isExactlyType(type)) return;
    if (!_siblingMode) {
      if (_isShowHideText(node)) labelFound = true;
      super.visitInstanceCreationExpression(node);
      return;
    }
    final callbacks = [
      for (final argument in node.argumentList.arguments)
        if (argument is NamedArgument && _callbackNames.contains(argument.name.lexeme)) argument,
    ];
    if (callbacks.isEmpty) {
      super.visitInstanceCreationExpression(node);
      return;
    }
    final own = _OwnControl();
    for (final argument in node.argumentList.arguments) {
      if (!callbacks.contains(argument)) argument.accept(own);
    }
    if (own.found || callbacks.any((argument) => _writesState(argument.argumentExpression, node))) {
      found = true;
    }
  }

  bool _isShowHideText(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type == null || !_textChecker.isExactlyType(type)) return false;
    final text = node.argumentList.arguments.firstOrNull?.argumentExpression;
    final value = text == null ? null : stringLiteralText(text);
    return value != null && _showHide.hasMatch(value);
  }

  bool _writesState(Expression callback, AstNode from) {
    final state = _stateName;
    if (state == null) return false;
    final body = switch (callback) {
      FunctionExpression() => callback,
      SimpleIdentifier(:final name) => _namedFunction(from.root, name),
      _ => null,
    };
    if (body == null) return false;
    final writes = _StateWrite(state);
    body.accept(writes);
    return writes.found;
  }

  AstNode? _namedFunction(AstNode root, String name) {
    final finder = _NamedFunction(name);
    root.accept(finder);
    return finder.found;
  }
}

final class _OwnControl extends RecursiveAstVisitor<void> {
  bool showHideLabel = false;
  bool eyeIcon = false;
  bool otherLabel = false;

  /// A "Show" or "Hide" label, or an eye icon on a control with no other text.
  bool get found => showHideLabel || (eyeIcon && !otherLabel);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type != null && _ToggleFinder._textChecker.isExactlyType(type)) {
      final text = node.argumentList.arguments.firstOrNull?.argumentExpression;
      final value = text == null ? null : stringLiteralText(text);
      if (value != null && _ToggleFinder._showHide.hasMatch(value)) {
        showHideLabel = true;
      } else {
        otherLabel = true;
      }
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final type = node.staticType;
    if (type != null &&
        _ToggleFinder._iconDataChecker.isExactlyType(type) &&
        _ToggleFinder._eyeIcon.hasMatch(node.name)) {
      eyeIcon = true;
    }
  }
}

final class _StateWrite extends RecursiveAstVisitor<void> {
  _StateWrite(this._state);

  final String _state;
  bool found = false;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final target = node.leftHandSide;
    final name = switch (target) {
      SimpleIdentifier(:final name) => name,
      PrefixedIdentifier(:final identifier) => identifier.name,
      PropertyAccess(:final propertyName) => propertyName.name,
      _ => null,
    };
    if (name == _state) found = true;
    super.visitAssignmentExpression(node);
  }
}

final class _NamedFunction extends RecursiveAstVisitor<void> {
  _NamedFunction(this._name);

  final String _name;
  AstNode? found;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == _name) found = node;
    super.visitMethodDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.name.lexeme == _name) found = node;
    super.visitFunctionDeclaration(node);
  }
}
