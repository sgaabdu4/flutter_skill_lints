import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when user-facing copy in widget UI does not come from gen-l10n.
class AvoidHardcodedStrings extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_hardcoded_strings',
    'Avoid hardcoded user-facing strings in widget UI.',
    correctionMessage:
        'Move the text into the gen-l10n ARB files and read it through '
        'AppLocalizations (context.l10n).',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidHardcodedStrings()
    : super(
        name: 'avoid_hardcoded_strings',
        description:
            'Warns when user-facing strings in widget UI are hardcoded literals or '
            'String constants instead of gen-l10n AppLocalizations lookups.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (_isExcludedContext(context)) return;
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addFunctionExpressionInvocation(this, visitor);
    registry.addMethodInvocation(this, visitor);
    registry.addNamedArgument(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFieldDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidHardcodedStrings rule;

  static const _textChecker = TypeChecker.fromName('Text', packageName: 'flutter');
  static const _contextChecker = TypeChecker.fromName('BuildContext', packageName: 'flutter');
  static const _widgetOrStateChecker = TypeChecker.any([
    TypeChecker.fromName('Widget', packageName: 'flutter'),
    flutterStateChecker,
  ]);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (enclosingWidgetPreview(node) != null) return;

    final arguments = node.argumentList.arguments;

    final type = node.staticType;
    if (type != null && node.constructorName.name == null && _textChecker.isExactlyType(type)) {
      final positional = _firstPositional(arguments);
      if (positional != null) _reportCopy(positional);
    }
  }

  void _reportCopy(Expression expression) {
    for (final copy in _copyLeaves(expression)) {
      if (_isUserFacingCopy(copy)) rule.reportAtNode(copy);
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (!isEnclosedClassAssignableTo(node, _widgetOrStateChecker)) return;
    for (final parameter in node.parameters.parameters) {
      final name = parameter.name?.lexeme;
      final value = parameter.defaultClause?.value;
      if (name != null && value != null && _isLabelName(name)) _reportCopy(value);
    }
    for (final initializer in node.initializers) {
      if (initializer is ConstructorFieldInitializer && _isLabelName(initializer.fieldName.name)) {
        _reportCopy(initializer.expression);
      }
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (!isEnclosedClassAssignableTo(node, _widgetOrStateChecker)) return;
    for (final variable in node.fields.variables) {
      final initializer = variable.initializer;
      if (initializer != null && _isLabelName(variable.name.lexeme)) _reportCopy(initializer);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isGetter || !_isLabelName(node.name.lexeme)) return;
    final library = node.declaredFragment?.element.library;
    if (library == null || !_importsFlutterUi(library)) return;
    if (enclosingWidgetPreview(node) != null) return;
    final body = node.body;
    if (body is ExpressionFunctionBody) {
      _reportCopy(body.expression);
    } else {
      body.accept(_ReturnedCopyVisitor(_reportCopy));
    }
  }

  /// Callback fields, parameters, and locals resolve as function-expression invocations; declared methods and functions do not. Top-level and static function variables such as `debugPrint` are global hooks and are skipped.
  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (node.function.staticType is FunctionType) {
      _reportCallbackProse(node, node.function, node.argumentList);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.realTarget;
    if (node.methodName.name == 'call' && target?.staticType is FunctionType) {
      _reportCallbackProse(node, target, node.argumentList);
    }
  }

  @override
  void visitNamedArgument(NamedArgument node) {
    if (!_isLabelName(node.name.lexeme)) return;
    final copies = _copyLeaves(node.argumentExpression).where(_isUserFacingCopy).toList();
    if (copies.isEmpty) return;
    if (enclosingWidgetPreview(node) != null || !_isUiCall(node)) return;
    copies.forEach(rule.reportAtNode);
  }

  bool _isUiCall(NamedArgument argument) {
    final callee = argument.correspondingParameter?.enclosingElement;
    if (callee is ExecutableElement) return _isUiExecutable(callee);
    final call = argument.parent?.parent;
    final function = switch (call) {
      FunctionExpressionInvocation() => call.function,
      MethodInvocation() => call.methodName,
      _ => null,
    };
    return function != null &&
        !_isGlobalFunctionVariable(function) &&
        isEnclosedClassAssignableTo(argument, _widgetOrStateChecker);
  }

  bool _isUiExecutable(ExecutableElement callee) {
    final enclosing = callee.enclosingElement;
    return _isFlutterUiLibrary(callee.library) ||
        _widgetOrStateChecker.isAssignableFromType(callee.returnType) ||
        (enclosing is InterfaceElement && _widgetOrStateChecker.isSuperOf(enclosing)) ||
        (enclosing is ExtensionElement && _isUiType(enclosing.extendedType)) ||
        callee.formalParameters.any((parameter) => _contextChecker.isExactlyType(parameter.type)) ||
        (callee is ConstructorElement && _importsFlutterUi(callee.library));
  }

  bool _isUiType(DartType type) =>
      _contextChecker.isExactlyType(type) || _widgetOrStateChecker.isAssignableFromType(type);

  void _reportCallbackProse(AstNode node, Expression? callee, ArgumentList arguments) {
    if (_isGlobalFunctionVariable(callee) ||
        enclosingWidgetPreview(node) != null ||
        !isEnclosedClassAssignableTo(node, _widgetOrStateChecker)) {
      return;
    }
    for (final argument in arguments.arguments) {
      final expression = argument.argumentExpression;
      final text = _callbackArgumentText(expression);
      if (text != null && _isProse(text)) rule.reportAtNode(expression);
    }
  }
}

/// The literal text of a callback argument; interpolated values become `$`.
String? _callbackArgumentText(Expression expression) => switch (expression) {
  StringInterpolation(:final elements) => [
    for (final element in elements) element is InterpolationString ? element.value : r'$',
  ].join(),
  _ => stringLiteralText(expression) ?? _constantStringText(expression),
};

/// Prose contains whitespace or ends in sentence punctuation; identifiers, keys, paths, and URLs do not.
bool _isProse(String text) {
  final trimmed = text.trim();
  return hasLetter(trimmed) && (_whitespace.hasMatch(trimmed) || _sentenceEnd.hasMatch(trimmed));
}

final RegExp _whitespace = RegExp(r'\s');
final RegExp _sentenceEnd = RegExp(r'[A-Za-z][.!?…]+$');

Expression? _firstPositional(NodeList<Argument> arguments) {
  return arguments.isEmpty ? null : arguments.first.argumentExpression;
}

bool _isExcludedContext(RuleContext context) =>
    isTestSourceContext(context) ||
    isGeneratedRuleContext(context) ||
    context.definingUnit.file.path.replaceAll('\\', '/').contains('/l10n/');

final RegExp _nonUiFlutterLibrary = RegExp(
  r'^package:flutter/(?:src/)?(?:foundation|services|scheduler)\b',
);

bool _isFlutterUiLibrary(LibraryElement library) {
  final uri = library.uri.toString();
  return (uri.startsWith('package:flutter/') && !_nonUiFlutterLibrary.hasMatch(uri)) ||
      uri.startsWith('package:material_ui/') ||
      uri.startsWith('package:cupertino_ui/');
}

bool _importsFlutterUi(LibraryElement library) =>
    library.firstFragment.libraryImports.any((import) {
      final imported = import.importedLibrary;
      return imported != null && _isFlutterUiLibrary(imported);
    });

bool _isUserFacingLiteral(Expression expression) {
  final text = stringLiteralText(expression) ?? _constantStringText(expression);
  return text != null && hasLetter(text);
}

bool _isUserFacingCopy(Expression expression) =>
    _isUserFacingLiteral(expression) || _isConstantListLookup(expression);

/// The values the expression can take: each branch of a conditional or switch, without parentheses.
Iterable<Expression> _copyLeaves(Expression expression) sync* {
  switch (expression) {
    case ParenthesizedExpression(:final expression):
      yield* _copyLeaves(expression);
    case ConditionalExpression(:final thenExpression, :final elseExpression):
      yield* _copyLeaves(thenExpression);
      yield* _copyLeaves(elseExpression);
    case SwitchExpression(:final cases):
      for (final switchCase in cases) {
        yield* _copyLeaves(switchCase.expression);
      }
    default:
      yield expression;
  }
}

/// A lookup such as `_days[index]` into a `const` list that holds user-facing strings.
bool _isConstantListLookup(Expression expression) {
  if (expression is! IndexExpression) return false;
  final variable = _referencedElement(expression.realTarget);
  if (variable is! VariableElement || !variable.isConst) return false;
  final items = variable.computeConstantValue()?.toListValue();
  return items != null &&
      items.any((item) {
        final text = item.toStringValue();
        return text != null && hasLetter(text);
      });
}

bool _isLabelName(String name) =>
    isUserFacingLabel(name) ||
    const {'caption', 'body'}.contains(name) ||
    _labelSuffix.hasMatch(name);

final RegExp _labelSuffix = RegExp(
  r'[a-z](?:Label|Text|Title|Subtitle|Tooltip|Message|Hint|Description|Heading|Caption|Body)$',
);

/// Collects the `return` expressions of one function body, skipping nested closures.
final class _ReturnedCopyVisitor extends RecursiveAstVisitor<void> {
  _ReturnedCopyVisitor(this.onReturn);

  final void Function(Expression expression) onReturn;

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (expression != null) onReturn(expression);
  }
}

/// The value of a resolved `const` String variable or static field.
String? _constantStringText(Expression expression) {
  final variable = _referencedElement(expression);
  if (variable is! VariableElement || !variable.isConst) return null;
  return variable.computeConstantValue()?.toStringValue();
}

/// Whether [callee] reads a top-level variable or static field, such as `debugPrint`; these are global hooks, not the widget's callbacks.
bool _isGlobalFunctionVariable(Expression? callee) {
  final variable = callee == null ? null : _referencedElement(callee);
  return variable is TopLevelVariableElement || (variable is FieldElement && variable.isStatic);
}

/// The resolved element an identifier or property access reads, with getters unwrapped to their variable.
Element? _referencedElement(Expression expression) {
  final element = switch (expression) {
    SimpleIdentifier(:final element) => element,
    PrefixedIdentifier(:final element) => element,
    PropertyAccess(:final propertyName) => propertyName.element,
    _ => null,
  };
  return element is PropertyAccessorElement ? element.variable : element;
}
