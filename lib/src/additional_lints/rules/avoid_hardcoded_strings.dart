import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
import '../ast_node_analysis.dart';

/// Warns when a user-facing string literal is hardcoded in widget UI code
/// instead of being sourced from localization or a dedicated strings constant.
///
/// Flags string literals passed as the data of a [Text] widget or to a curated
/// set of user-facing named parameters (for example `label`, `hintText`,
/// `title`, `tooltip`, `semanticLabel`). Constant/strings/localization files,
/// generated sources, and tests are exempt.
class AvoidHardcodedStrings extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_hardcoded_strings',
    'Avoid hardcoded user-facing strings in widget UI.',
    correctionMessage:
        'Move the text into localization (AppLocalizations / context.l10n) or a '
        'dedicated *_strings.dart constant and reference it here.',
  );

  AvoidHardcodedStrings()
    : super(
        name: 'avoid_hardcoded_strings',
        description:
            'Warns when user-facing string literals are hardcoded in widget UI '
            'instead of being sourced from localization or a strings constant.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (_isExcludedContext(context)) return;
    registry.addInstanceCreationExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidHardcodedStrings rule;

  static const _textChecker = TypeChecker.fromName('Text', packageName: 'flutter');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final arguments = node.argumentList.arguments;

    final type = node.staticType;
    if (type != null && node.constructorName.name == null && _textChecker.isExactlyType(type)) {
      final positional = _firstPositional(arguments);
      if (positional != null && _isUserFacingLiteral(positional)) {
        rule.reportAtNode(positional);
      }
    }

    for (final argument in arguments.whereType<NamedExpression>()) {
      if (!_isUserFacingLabel(argument.name.lexeme)) continue;
      if (_isUserFacingLiteral(argument.expression)) {
        rule.reportAtNode(argument.expression);
      }
    }
  }
}

Expression? _firstPositional(NodeList<Expression> arguments) {
  for (final argument in arguments) {
    if (argument is Expression) return argument;
  }
  return null;
}

bool _isExcludedContext(RuleContext context) {
  if (context.isInTestDirectory || isGeneratedRuleContext(context)) return true;

  final path = context.definingUnit.file.path.replaceAll('\\', '/');
  return !path.contains('/lib/') ||
      path.endsWith('_test.dart') ||
      path.endsWith('_strings.dart') ||
      path.endsWith('_constants.dart') ||
      path.endsWith('_keys.dart') ||
      path.contains('/constants/') ||
      path.contains('/l10n/') ||
      path.contains('/generated/');
}

bool _isUserFacingLabel(String name) => _userFacingLabels.contains(name.toLowerCase());

bool _isUserFacingLiteral(Expression expression) {
  final text = _literalText(expression);
  return text != null && _hasLetter(text);
}

String? _literalText(Expression expression) {
  if (expression is SimpleStringLiteral) return expression.value;

  if (expression is AdjacentStrings) {
    final buffer = StringBuffer();
    for (final string in expression.strings) {
      final part = _literalText(string);
      if (part != null) buffer.write(part);
    }
    return buffer.toString();
  }

  if (expression is StringInterpolation) {
    final buffer = StringBuffer();
    for (final element in expression.elements) {
      if (element is InterpolationString) buffer.write(element.value);
    }
    return buffer.toString();
  }

  return null;
}

bool _hasLetter(String value) => _letter.hasMatch(value);

final RegExp _letter = RegExp('[A-Za-z]');

const _userFacingLabels = {
  'text',
  'data',
  'label',
  'labeltext',
  'hint',
  'hinttext',
  'helpertext',
  'errortext',
  'title',
  'subtitle',
  'tooltip',
  'semanticslabel',
  'semanticlabel',
  'message',
  'placeholder',
  'prefixtext',
  'suffixtext',
  'toptext',
  'bottomtext',
  'description',
  'heading',
};
