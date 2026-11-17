import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Refuses a literal font size under 14 logical pixels in a `TextStyle`.
final class AvoidSmallFontSize extends AnalysisRule {
  static const double minimumFontSize = 14;

  static const LintCode code = LintCode(
    'avoid_small_font_size',
    'A font size under 14 logical pixels is hard to read.',
    correctionMessage:
        'Use a font size of 14 or more, or a style from the text theme. '
        'Shorten the text instead of shrinking it.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidSmallFontSize()
    : super(
        name: 'avoid_small_font_size',
        description:
            'Flags a literal fontSize under 14 in a TextStyle constructor, a dot shorthand '
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
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  static const _textStyleChecker = TypeChecker.fromName('TextStyle', packageName: 'flutter');

  final AvoidSmallFontSize rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) =>
      _check(node.staticType, node.argumentList);

  @override
  void visitDotShorthandConstructorInvocation(DotShorthandConstructorInvocation node) =>
      _check(node.staticType, node.argumentList);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'copyWith') _check(node.realTarget?.staticType, node.argumentList);
  }

  void _check(DartType? type, ArgumentList arguments) {
    if (type == null || !_textStyleChecker.isExactlyType(type)) return;
    final size = namedArgumentExpression(arguments, 'fontSize');
    final value = switch (size) {
      IntegerLiteral(:final value) => value,
      DoubleLiteral(:final value) => value,
      _ => null,
    };
    if (size != null && value != null && value < AvoidSmallFontSize.minimumFontSize) {
      rule.reportAtNode(size);
    }
  }
}
