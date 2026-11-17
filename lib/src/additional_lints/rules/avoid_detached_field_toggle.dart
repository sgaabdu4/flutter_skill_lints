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
    final toggle = _ToggleFinder(_stateName(obscure));
    if (suffixes.isNotEmpty) {
      for (final suffix in suffixes) {
        suffix.accept(toggle);
      }
      if (toggle.labelFound) rule.reportAtNode(node.constructorName);
      return;
    }
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
  _ToggleFinder(this._stateName);

  static const _textChecker = TypeChecker.fromName('Text', packageName: 'flutter');
  static final _showHide = RegExp(r'^\s*(show|hide)\b', caseSensitive: false);
  static final _eyeIcon = RegExp(
    r'^(visibility|visibilityOff|visibility_off|removeRedEye|remove_red_eye|eye|eyeSlash|eye_slash)',
  );

  final String? _stateName;
  bool labelFound = false;
  bool _stateFound = false;
  bool _iconFound = false;
  int _functionDepth = 0;

  bool get found => labelFound || _iconFound || _stateFound;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type != null && _textChecker.isExactlyType(type)) {
      final text = node.argumentList.arguments.firstOrNull?.argumentExpression;
      final value = text == null ? null : stringLiteralText(text);
      if (value != null && _showHide.hasMatch(value)) labelFound = true;
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (_eyeIcon.hasMatch(node.name)) _iconFound = true;
    if (_functionDepth > 0 && _stateName != null && node.name == _stateName) _stateFound = true;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _functionDepth++;
    super.visitFunctionExpression(node);
    _functionDepth--;
  }
}
