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

/// Refuses a font size under 11 logical pixels in a `TextStyle`.
final class AvoidSmallFontSize extends AnalysisRule {
  static const double minimumFontSize = 11;

  static const LintCode code = LintCode(
    'avoid_small_font_size',
    'A font size under 11 logical pixels is hard to read.',
    correctionMessage:
        'Use a font size of 11 or more, or a style from the text theme. '
        'Shorten the text instead of shrinking it.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidSmallFontSize()
    : super(
        name: 'avoid_small_font_size',
        description:
            'Flags a fontSize under 11 in a TextStyle constructor, a dot shorthand '
            'constructor or a copyWith call.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context) || isTestSourceContext(context)) return;
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addDotShorthandConstructorInvocation(this, visitor);
    registry.addMethodInvocation(this, visitor);
    registry.addPrefixedIdentifier(this, visitor);
    registry.addDotShorthandPropertyAccess(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  static const _textStyleChecker = TypeChecker.fromName('TextStyle', packageName: 'flutter');
  static const _textScalerChecker = TypeChecker.fromName('TextScaler', packageName: 'flutter');

  final AvoidSmallFontSize rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _checkFontSize(node.staticType, node.argumentList);
    _checkScaler(node.staticType, node.constructorName.name?.name, node.argumentList);
  }

  @override
  void visitDotShorthandConstructorInvocation(DotShorthandConstructorInvocation node) {
    _checkFontSize(node.staticType, node.argumentList);
    _checkScaler(node.staticType, node.constructorName.name, node.argumentList);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    final target = node.realTarget;
    final targetType = target?.staticType;
    if (name == 'copyWith') _checkFontSize(targetType, node.argumentList);
    if (name == 'apply' && target != null && targetType != null) _checkApply(target, node);
  }

  void _checkApply(Expression target, MethodInvocation node) {
    if (!_textStyleChecker.isExactlyType(target.staticType!)) return;
    final factor = namedArgumentExpression(node.argumentList, 'fontSizeFactor');
    final delta = namedArgumentExpression(node.argumentList, 'fontSizeDelta');
    final size = _sizeOf(target);
    if (size == null || size <= 0 || (factor == null && delta == null)) return;
    final scale = factor == null ? 1.0 : _numberOf(factor);
    final shift = delta == null ? 0.0 : _numberOf(delta);
    if (scale == null || shift == null) return;
    if (size * scale + shift < AvoidSmallFontSize.minimumFontSize) {
      rule.reportAtNode((factor ?? delta)!);
    }
  }

  double? _sizeOf(Expression style) {
    final arguments = switch (style) {
      InstanceCreationExpression(:final argumentList) => argumentList,
      DotShorthandConstructorInvocation(:final argumentList) => argumentList,
      _ => null,
    };
    final size = arguments == null ? null : namedArgumentExpression(arguments, 'fontSize');
    if (size != null) return _numberOf(size);
    final field = style.computeConstantValue()?.value?.getField('fontSize');
    return field?.toDoubleValue() ?? field?.toIntValue()?.toDouble();
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'noScaling' &&
        !_isComparison(node) &&
        _isScalerMember(node.identifier.element)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) {
    if (node.propertyName.name == 'noScaling' &&
        !_isComparison(node) &&
        _isScalerMember(node.propertyName.element)) {
      rule.reportAtNode(node);
    }
  }

  bool _isComparison(Expression node) {
    AstNode child = node;
    while (child.parent is ParenthesizedExpression) {
      child = child.parent!;
    }
    return switch (child.parent) {
      BinaryExpression(:final operator) => const {'==', '!='}.contains(operator.lexeme),
      ConstantPattern() => true,
      ArgumentList(parent: MethodInvocation(:final methodName)) => methodName.name == 'identical',
      _ => false,
    };
  }

  bool _isScalerMember(Element? element) {
    final owner = element?.enclosingElement;
    return owner != null && _textScalerChecker.isExactly(owner);
  }

  void _checkScaler(DartType? type, String? constructor, ArgumentList arguments) {
    if (constructor != 'linear' || type == null || !_textScalerChecker.isExactlyType(type)) return;
    final scale = arguments.arguments.firstOrNull?.argumentExpression;
    if (scale != null && _isShrinking(scale, 1)) rule.reportAtNode(scale);
  }

  void _checkFontSize(DartType? type, ArgumentList arguments) {
    if (type == null || !_textStyleChecker.isExactlyType(type)) return;
    final size = namedArgumentExpression(arguments, 'fontSize');
    if (size == null) return;
    final value = _numberOf(size);
    if (value != null && value > 0 && value < AvoidSmallFontSize.minimumFontSize) {
      rule.reportAtNode(size);
    }
  }

  bool _isShrinking(Expression expression, double unit) {
    final value = _numberOf(expression);
    return value != null && value < unit;
  }

  double? _numberOf(Expression expression) {
    final object = expression.computeConstantValue()?.value;
    return object?.toDoubleValue() ?? object?.toIntValue()?.toDouble();
  }
}
