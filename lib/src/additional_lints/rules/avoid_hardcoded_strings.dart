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
///
/// Flags string literals, and resolved `const` String variables or static
/// fields (for example a `*Strings` constants class), passed as the data of a
/// [Text] widget or to a curated set of user-facing named parameters (for
/// example `label`, `hintText`, `title`, `tooltip`, `semanticLabel`). Inside
/// Flutter widget and `State` classes it also flags prose (text with
/// whitespace or ending in sentence punctuation) passed to a function-typed
/// value such as `widget.onError('Please choose a time')`; identifiers, keys,
/// URLs, and declared methods or functions stay clean. Sample data inside
/// resolved `@Preview` declarations, `/l10n/` and `/generated/` sources, and
/// tests are exempt.
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
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidHardcodedStrings rule;

  static const _textChecker = TypeChecker.fromName('Text', packageName: 'flutter');
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

  /// Callback fields, parameters, and locals resolve as function-expression
  /// invocations; declared methods and functions do not.
  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (node.function.staticType is FunctionType) _reportCallbackProse(node, node.argumentList);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'call' && node.realTarget?.staticType is FunctionType) {
      _reportCallbackProse(node, node.argumentList);
    }
  }

  void _reportCallbackProse(AstNode node, ArgumentList arguments) {
    if (enclosingWidgetPreview(node) != null ||
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

/// Prose contains whitespace or ends in sentence punctuation; identifiers,
/// keys, paths, and URLs do not.
bool _isProse(String text) {
  final trimmed = text.trim();
  return hasLetter(trimmed) && (_whitespace.hasMatch(trimmed) || _sentenceEnd.hasMatch(trimmed));
}

final RegExp _whitespace = RegExp(r'\s');
final RegExp _sentenceEnd = RegExp(r'[A-Za-z][.!?…]+$');

Expression? _firstPositional(NodeList<Argument> arguments) {
  return arguments.isEmpty ? null : arguments.first.argumentExpression;
}

bool _isExcludedContext(RuleContext context) {
  final path = productionLibPath(context);
  if (path == null) return true;
  return path.contains('/l10n/') || path.contains('/generated/');
}

bool _isUserFacingLiteral(Expression expression) {
  final text = stringLiteralText(expression) ?? _constantStringText(expression);
  return text != null && hasLetter(text);
}

/// The value of a resolved `const` String variable or static field.
String? _constantStringText(Expression expression) {
  final element = switch (expression) {
    SimpleIdentifier(:final element) => element,
    PrefixedIdentifier(:final element) => element,
    PropertyAccess(:final propertyName) => propertyName.element,
    _ => null,
  };
  final variable = element is PropertyAccessorElement ? element.variable : element;
  if (variable is! VariableElement || !variable.isConst) return null;
  return variable.computeConstantValue()?.toStringValue();
}
