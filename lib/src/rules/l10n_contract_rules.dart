import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/riverpod_type_checkers.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

final List<AbstractAnalysisRule> l10nContractRules = [
  L10nStringConcatenation(),
  L10nNotifierLocalizedCopy(),
];

const _localizationsDelegateChecker = TypeChecker.fromName(
  'LocalizationsDelegate',
  packageName: 'flutter',
);

const _anyNotifierChecker = TypeChecker.any([
  notifierChecker,
  TypeChecker.fromName('AnyNotifier', packageName: 'riverpod'),
  TypeChecker.fromName('StreamNotifier', packageName: 'riverpod'),
]);

const _asyncDataChecker = TypeChecker.fromName('AsyncData', packageName: 'riverpod');

/// Whether [element] is an instance getter or method of the gen-l10n class.
///
/// The localizations class is identified by the gen-l10n fingerprint: it (or a
/// supertype) declares a static `LocalizationsDelegate` field.
bool _isLocalizedMember(Element? element) {
  if (element is! ExecutableElement || element.isStatic) return false;
  final owner = element.enclosingElement;
  if (owner is! InterfaceElement) return false;
  return [owner, ...owner.allSupertypes.map((type) => type.element)].any(
    (candidate) => candidate.fields.any(
      (field) => field.isStatic && _localizationsDelegateChecker.isAssignableFromType(field.type),
    ),
  );
}

bool _isLocalizedRead(Expression expression) {
  final target = expression.unParenthesized;
  final element = switch (target) {
    SimpleIdentifier(:final element) => element,
    PrefixedIdentifier(:final identifier) => identifier.element,
    PropertyAccess(:final propertyName) => propertyName.element,
    MethodInvocation(:final methodName) => methodName.element,
    _ => null,
  };
  return _isLocalizedMember(element);
}

/// Use ARB placeholders instead of concatenating localized strings.
///
/// Why: localization.md requires placeholders for runtime values and forbids
/// concatenating localized strings; word order differs between locales.
final class L10nStringConcatenation extends AnalysisRule {
  static const LintCode code = LintCode(
    'l10n_string_concatenation',
    'Do not concatenate or interpolate localized strings.',
    correctionMessage:
        'Add one ARB message with placeholders (or plural/select) and pass runtime values to it.',
    severity: DiagnosticSeverity.ERROR,
  );

  L10nStringConcatenation()
    : super(
        name: 'l10n_string_concatenation',
        description:
            'Flags `+` concatenation and string interpolation that combine AppLocalizations '
            'messages with other text.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (productionLibPath(context) == null) return;
    final visitor = _ConcatenationVisitor(this);
    registry
      ..addBinaryExpression(this, visitor)
      ..addStringInterpolation(this, visitor);
  }
}

final class _ConcatenationVisitor extends SimpleAstVisitor<void> {
  _ConcatenationVisitor(this.rule);

  final L10nStringConcatenation rule;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type != TokenType.PLUS) return;
    if (node.staticType?.isDartCoreString != true) return;
    if (_isLocalizedRead(node.leftOperand) || _isLocalizedRead(node.rightOperand)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    final interpolated = node.elements.whereType<InterpolationExpression>().toList();
    final hasOtherText = node.elements.whereType<InterpolationString>().any(
      (element) => element.value.isNotEmpty,
    );
    if (!hasOtherText && interpolated.length < 2) return;
    if (interpolated.any((element) => _isLocalizedRead(element.expression))) {
      rule.reportAtNode(node);
    }
  }
}

/// Notifiers hold semantic state, not user-facing copy.
///
/// Why: localization.md forbids storing localized copy in notifiers; the UI
/// renders copy from semantic state. Reports AppLocalizations reads inside
/// Riverpod notifiers, and user-facing string literals returned from `build`
/// or assigned to `state` (directly, through `AsyncData`, conditionals, or
/// user-facing named arguments). Values that reach state indirectly through
/// local variables or helper calls are not tracked.
final class L10nNotifierLocalizedCopy extends AnalysisRule {
  static const LintCode code = LintCode(
    'l10n_notifier_localized_copy',
    'Notifiers must expose semantic state, not user-facing copy.',
    correctionMessage: 'Store an enum or sealed status in state and map it to AppLocalizations messages in the widget.',
    severity: DiagnosticSeverity.ERROR,
  );

  L10nNotifierLocalizedCopy()
    : super(
        name: 'l10n_notifier_localized_copy',
        description:
            'Flags AppLocalizations reads and user-facing string literals stored as Riverpod '
            'notifier state.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (productionLibPath(context) == null) return;
    registry.addClassDeclaration(this, _NotifierClassVisitor(this));
  }
}

final class _NotifierClassVisitor extends SimpleAstVisitor<void> {
  _NotifierClassVisitor(this.rule);

  final L10nNotifierLocalizedCopy rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!isClassAssignableTo(node, _anyNotifierChecker)) return;
    node.accept(_NotifierCopyVisitor(rule));
  }
}

final class _NotifierCopyVisitor extends RecursiveAstVisitor<void> {
  _NotifierCopyVisitor(this.rule);

  final L10nNotifierLocalizedCopy rule;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (_isLocalizedMember(node.element)) rule.reportAtNode(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == 'build' && !node.isStatic) {
      final body = node.body;
      if (body is ExpressionFunctionBody) {
        _reportCopy(body.expression);
      } else {
        body.accept(_ReturnedExpressionVisitor(_reportCopy));
      }
    }
    super.visitMethodDeclaration(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final setter = node.writeElement;
    if (setter?.name == 'state' &&
        setter?.library?.uri.toString().startsWith('package:riverpod/') == true) {
      _reportCopy(node.rightHandSide);
    }
    super.visitAssignmentExpression(node);
  }

  void _reportCopy(Expression expression) {
    switch (expression.unParenthesized) {
      case ConditionalExpression(:final thenExpression, :final elseExpression):
        _reportCopy(thenExpression);
        _reportCopy(elseExpression);
      case SwitchExpression(:final cases):
        for (final switchCase in cases) {
          _reportCopy(switchCase.expression);
        }
      case AwaitExpression(:final expression):
        _reportCopy(expression);
      case InstanceCreationExpression(:final argumentList, :final staticType?)
          when _asyncDataChecker.isExactlyType(staticType):
        final arguments = argumentList.arguments;
        if (arguments.isNotEmpty) _reportCopy(arguments.first.argumentExpression);
      case InstanceCreationExpression(:final argumentList) || MethodInvocation(:final argumentList):
        _reportLabelledCopy(argumentList);
      case final literal:
        final text = stringLiteralText(literal);
        if (text != null && hasLetter(text)) rule.reportAtNode(literal);
    }
  }

  void _reportLabelledCopy(ArgumentList arguments) {
    for (final argument in arguments.arguments.whereType<NamedArgument>()) {
      if (isUserFacingLabel(argument.name.lexeme)) _reportCopy(argument.argumentExpression);
    }
  }
}

/// Collects `return` expressions of one function body, skipping nested closures.
final class _ReturnedExpressionVisitor extends RecursiveAstVisitor<void> {
  _ReturnedExpressionVisitor(this.onReturn);

  final void Function(Expression expression) onReturn;

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (expression != null) onReturn(expression);
  }
}
