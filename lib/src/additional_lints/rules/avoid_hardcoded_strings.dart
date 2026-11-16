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
      if (positional != null && _isUserFacingLiteral(positional)) {
        rule.reportAtNode(positional);
      }
    }

    for (final argument in arguments.whereType<NamedArgument>()) {
      if (!isUserFacingLabel(argument.name.lexeme)) continue;
      if (_isUserFacingLiteral(argument.argumentExpression)) {
        rule.reportAtNode(argument.argumentExpression);
      }
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
    if (!_callLabelNames.contains(node.name.lexeme)) return;
    if (node.parent?.parent is InstanceCreationExpression) return;
    if (!_isUserFacingLiteral(node.argumentExpression)) return;
    if (enclosingWidgetPreview(node) != null || !_isUiCall(node)) return;
    rule.reportAtNode(node.argumentExpression);
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
        callee.formalParameters.any((parameter) => _contextChecker.isExactlyType(parameter.type)) ||
        (callee is ConstructorElement && _importsFlutterUi(callee.library));
  }

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

const _callLabelNames = {'title', 'label', 'tooltip', 'hintText', 'helperText', 'errorText'};

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
  return uri.startsWith('package:flutter/') && !_nonUiFlutterLibrary.hasMatch(uri);
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
