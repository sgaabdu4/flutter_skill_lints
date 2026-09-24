import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/flutter_widget_helpers.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Layout rules from the skill's layout-diagnostics and flutter-optimizations
/// references. Each one reports only a resolved Flutter widget shape.
final List<AnalysisRule> layoutDiagnosticsRules = [
  AvoidPositionedOutsideStack(),
  AvoidUnboundedListInColumn(),
  AvoidUnboundedTextFieldInRow(),
  AvoidListInSingleChildScrollView(),
  AvoidOrientationLayout(),
  AvoidClipRRectContainer(),
];

const _positionedChecker = TypeChecker.fromName('Positioned', packageName: 'flutter');
const _stackChecker = TypeChecker.fromName('Stack', packageName: 'flutter');
const _boxScrollViewChecker = TypeChecker.fromName('BoxScrollView', packageName: 'flutter');
const _scrollViewChecker = TypeChecker.fromName('ScrollView', packageName: 'flutter');
const _singleChildScrollViewChecker = TypeChecker.fromName(
  'SingleChildScrollView',
  packageName: 'flutter',
);
const _columnChecker = TypeChecker.fromName('Column', packageName: 'flutter');
const _rowChecker = TypeChecker.fromName('Row', packageName: 'flutter');
const _flexChecker = TypeChecker.fromName('Flex', packageName: 'flutter');
const _axisChecker = TypeChecker.fromName('Axis', packageName: 'flutter');
const _textFieldChecker = TypeChecker.any([
  TypeChecker.fromName('TextField', packageName: 'flutter'),
  TypeChecker.fromName('TextFormField', packageName: 'flutter'),
]);
const _childEmbeddingChecker = TypeChecker.any([
  TypeChecker.fromName('RenderObjectWidget', packageName: 'flutter'),
  TypeChecker.fromName('ProxyWidget', packageName: 'flutter'),
]);
const _containerChecker = TypeChecker.fromName('Container', packageName: 'flutter');
const _clipRRectChecker = TypeChecker.fromName('ClipRRect', packageName: 'flutter');
const _mediaQueryChecker = TypeChecker.fromName('MediaQuery', packageName: 'flutter');
const _mediaQueryDataChecker = TypeChecker.fromName('MediaQueryData', packageName: 'flutter');
const _orientationBuilderChecker = TypeChecker.fromName(
  'OrientationBuilder',
  packageName: 'flutter',
);

/// Positioned must be a direct child of Stack.
///
/// Why: Positioned writes StackParentData; under any other render parent
/// Flutter throws "Incorrect use of ParentDataWidget".
final class AvoidPositionedOutsideStack extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_positioned_outside_stack',
    'Positioned has a non-Stack render-object parent.',
    correctionMessage: 'Move Positioned directly under a Stack, or remove it.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidPositionedOutsideStack()
    : super(
        name: 'avoid_positioned_outside_stack',
        description: 'Flags Positioned widgets whose proven render parent is not a Stack.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addInstanceCreationExpression(this, _PositionedVisitor(this, context));
  }
}

final class _PositionedVisitor extends SimpleAstVisitor<void> {
  _PositionedVisitor(this.rule, this.context);

  final AvoidPositionedOutsideStack rule;
  final RuleContext context;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.constructorName.type.element;
    if (element == null || !_positionedChecker.isSuperOf(element)) return;
    if (hasProvenForeignRenderParent(node, _stackChecker, context.typeSystem)) {
      rule.reportAtNode(node.constructorName);
    }
  }
}

/// ListView or GridView directly inside a Column needs a bounded height.
///
/// Why: a Column lays out non-flex children with unbounded height, so a
/// vertical list there throws "Vertical viewport was given unbounded height".
final class AvoidUnboundedListInColumn extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unbounded_list_in_column',
    'ListView or GridView is a direct Column child and gets unbounded height.',
    correctionMessage:
        'Wrap the list in Expanded or Flexible, give it fixed constraints, or use slivers.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidUnboundedListInColumn()
    : super(
        name: 'avoid_unbounded_list_in_column',
        description: 'Flags vertical ListView or GridView widgets placed directly in a Column.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addInstanceCreationExpression(this, _ListInColumnVisitor(this));
  }
}

final class _ListInColumnVisitor extends SimpleAstVisitor<void> {
  _ListInColumnVisitor(this.rule);

  final AvoidUnboundedListInColumn rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!_isBoxScrollView(node) || _scrollAxis(node) != 'vertical') return;
    final shrinkWrap = namedArgumentExpression(node.argumentList, 'shrinkWrap');
    if (shrinkWrap != null && shrinkWrap.computeConstantValue()?.value?.toBoolValue() != false) {
      return;
    }
    final parent = _directFlexParent(node);
    if (parent != null && _flexAxis(parent) == 'vertical') {
      rule.reportAtNode(node.constructorName);
    }
  }
}

/// TextField directly inside a Row needs a bounded width.
///
/// Why: a Row lays out non-flex children with unbounded width, so a field
/// there throws "InputDecorator cannot have an unbounded width".
final class AvoidUnboundedTextFieldInRow extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unbounded_text_field_in_row',
    'Text field is a direct Row child and gets unbounded width.',
    correctionMessage: 'Wrap the field in Expanded or Flexible.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidUnboundedTextFieldInRow()
    : super(
        name: 'avoid_unbounded_text_field_in_row',
        description: 'Flags TextField and TextFormField widgets placed directly in a Row.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addInstanceCreationExpression(this, _TextFieldInRowVisitor(this));
  }
}

final class _TextFieldInRowVisitor extends SimpleAstVisitor<void> {
  _TextFieldInRowVisitor(this.rule);

  final AvoidUnboundedTextFieldInRow rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.constructorName.type.element;
    if (element == null || !_textFieldChecker.isSuperOf(element)) return;
    final parent = _directFlexParent(node);
    if (parent != null && _flexAxis(parent) == 'horizontal') {
      rule.reportAtNode(node.constructorName);
    }
  }
}

/// Use CustomScrollView, not ListView in SingleChildScrollView.
///
/// Why: a list nested in a same-axis SingleChildScrollView either throws for
/// unbounded extent or needs shrinkWrap, which lays out every item.
final class AvoidListInSingleChildScrollView extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_list_in_single_child_scroll_view',
    'ListView or GridView is nested in a SingleChildScrollView on the same axis.',
    correctionMessage: 'Use a CustomScrollView with slivers instead of nesting the list.',
    severity: DiagnosticSeverity.WARNING,
  );

  AvoidListInSingleChildScrollView()
    : super(
        name: 'avoid_list_in_single_child_scroll_view',
        description:
            'Flags ListView or GridView widgets nested in a same-axis SingleChildScrollView.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addInstanceCreationExpression(this, _ListInScrollViewVisitor(this));
  }
}

final class _ListInScrollViewVisitor extends SimpleAstVisitor<void> {
  _ListInScrollViewVisitor(this.rule);

  final AvoidListInSingleChildScrollView rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!_isBoxScrollView(node)) return;
    final axis = _scrollAxis(node);
    if (axis == null) return;
    var parent = directWidgetParent(node);
    while (parent != null) {
      final element = parent.constructorName.type.element;
      if (element == null || _scrollViewChecker.isSuperOf(element)) return;
      if (_singleChildScrollViewChecker.isSuperOf(element)) {
        if (_scrollAxis(parent) == axis) rule.reportAtNode(node.constructorName);
        return;
      }
      final type = parent.staticType;
      final embedsChild =
          _childEmbeddingChecker.isSuperOf(element) ||
          (type != null && _containerChecker.isExactlyType(type));
      if (!embedsChild) return;
      parent = directWidgetParent(parent);
    }
  }
}

/// Adapt layout to available space, not orientation.
///
/// Why: orientation says nothing about the space a widget actually gets
/// (split screen, foldables, desktop windows). Use LayoutBuilder constraints or
/// MediaQuery.sizeOf.
final class AvoidOrientationLayout extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_orientation_layout',
    'Layout reads device orientation instead of available space.',
    correctionMessage: 'Branch on LayoutBuilder constraints or MediaQuery.sizeOf(context).',
    severity: DiagnosticSeverity.WARNING,
  );

  AvoidOrientationLayout()
    : super(
        name: 'avoid_orientation_layout',
        description:
            'Flags MediaQuery orientation reads and OrientationBuilder in production code.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context) || isTestSourceContext(context)) return;
    final visitor = _OrientationVisitor(this);
    registry
      ..addMethodInvocation(this, visitor)
      ..addPropertyAccess(this, visitor)
      ..addPrefixedIdentifier(this, visitor)
      ..addInstanceCreationExpression(this, visitor);
  }
}

final class _OrientationVisitor extends SimpleAstVisitor<void> {
  _OrientationVisitor(this.rule);

  final AvoidOrientationLayout rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'orientationOf' &&
        _isMemberOf(node.methodName.element, _mediaQueryChecker)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) => _checkOrientationGetter(node.propertyName, node);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) =>
      _checkOrientationGetter(node.identifier, node);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.constructorName.type.element;
    if (element != null && _orientationBuilderChecker.isSuperOf(element)) {
      rule.reportAtNode(node.constructorName);
    }
  }

  void _checkOrientationGetter(SimpleIdentifier name, Expression node) {
    if (name.name == 'orientation' && _isMemberOf(name.element, _mediaQueryDataChecker)) {
      rule.reportAtNode(node);
    }
  }

  static bool _isMemberOf(Element? element, TypeChecker owner) {
    final enclosing = element?.enclosingElement;
    return enclosing != null && owner.isExactly(enclosing);
  }
}

/// Use borderRadius on Container, not a ClipRRect wrap.
///
/// Why: a Container decoration paints rounded corners without an extra clip
/// layer; Container.clipBehavior clips its child when that is needed.
final class AvoidClipRRectContainer extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_clip_rrect_container',
    'ClipRRect wraps a Container.',
    correctionMessage: 'Put borderRadius on the Container decoration, with clipBehavior when its child must be clipped.',
    severity: DiagnosticSeverity.WARNING,
  );

  AvoidClipRRectContainer()
    : super(
        name: 'avoid_clip_rrect_container',
        description: 'Flags ClipRRect widgets whose child is a Container.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addInstanceCreationExpression(this, _ClipRRectVisitor(this));
  }
}

final class _ClipRRectVisitor extends SimpleAstVisitor<void> {
  _ClipRRectVisitor(this.rule);

  final AvoidClipRRectContainer rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.constructorName.type.element;
    if (element == null || !_clipRRectChecker.isSuperOf(element)) return;
    final child = namedArgumentExpression(node.argumentList, 'child');
    final childType = child is InstanceCreationExpression ? child.staticType : null;
    if (childType != null && _containerChecker.isExactlyType(childType)) {
      rule.reportAtNode(node.constructorName);
    }
  }
}

bool _isBoxScrollView(InstanceCreationExpression node) {
  final element = node.constructorName.type.element;
  return element != null && _boxScrollViewChecker.isSuperOf(element);
}

/// The Row, Column or Flex whose `children` list holds [node] unchanged.
InstanceCreationExpression? _directFlexParent(InstanceCreationExpression node) {
  final parent = directWidgetParent(node);
  final element = parent?.constructorName.type.element;
  if (parent == null || element == null || !_flexChecker.isSuperOf(element)) return null;
  final argument = node.thisOrAncestorMatching((ancestor) => ancestor is NamedArgument);
  if (argument is! NamedArgument || argument.parent?.parent != parent) return null;
  return argument.name.lexeme == 'children' ? parent : null;
}

/// The main axis of a resolved Row, Column or Flex, when it is known.
String? _flexAxis(InstanceCreationExpression flex) {
  final element = flex.constructorName.type.element;
  if (element == null) return null;
  if (_columnChecker.isSuperOf(element)) return 'vertical';
  if (_rowChecker.isSuperOf(element)) return 'horizontal';
  return _axisName(namedArgumentExpression(flex.argumentList, 'direction'));
}

/// The scroll axis of a scroll view; `scrollDirection` defaults to vertical.
String? _scrollAxis(InstanceCreationExpression scrollView) {
  final direction = namedArgumentExpression(scrollView.argumentList, 'scrollDirection');
  return direction == null ? 'vertical' : _axisName(direction);
}

String? _axisName(Expression? expression) {
  final type = expression?.staticType;
  if (type is! InterfaceType || !_axisChecker.isExactlyType(type)) return null;
  final index = expression?.computeConstantValue()?.value?.getField('index')?.toIntValue();
  if (index == null) return null;
  final constants = type.element.fields.where((field) => field.isEnumConstant).toList();
  return index >= 0 && index < constants.length ? constants[index].name : null;
}
