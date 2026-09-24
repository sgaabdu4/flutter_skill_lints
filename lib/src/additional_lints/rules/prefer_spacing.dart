import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/flutter_widget_helpers.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when SizedBox widgets are used for spacing inside Row, Column, or Flex
/// children instead of using the `spacing` argument (Flutter 3.27+).
///
/// Detects three patterns:
/// 1. Direct SizedBox in children list with uniform spacing
/// 2. `.separatedBy()` with SizedBox
/// 3. `.expand()` with generator yielding SizedBox
class PreferSpacing extends InstanceAndMethodInvocationRule {
  static const LintCode code = LintCode(
    'prefer_spacing',
    "Prefer passing the 'spacing' argument instead of using SizedBox.",
    correctionMessage: "Use the 'spacing' argument on Row, Column, or Flex instead.",
  );

  PreferSpacing()
    : super(
        code: code,
        name: 'prefer_spacing',
        description:
            "Prefer the 'spacing' argument over SizedBox for spacing in "
            'Row, Column, and Flex.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSpacing rule;

  _Visitor(this.rule);

  static const _sizedBoxChecker = TypeChecker.fromName('SizedBox', packageName: 'flutter');

  static const _flexWidgets = [
    (TypeChecker.fromName('Column', packageName: 'flutter'), FlexAxis.vertical),
    (TypeChecker.fromName('Row', packageName: 'flutter'), FlexAxis.horizontal),
    (TypeChecker.fromName('Flex', packageName: 'flutter'), null),
  ];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _checkFlexWidget(node.staticType, node.argumentList);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;

    if (methodName == 'separatedBy') {
      _checkSeparatedBy(node);
      return;
    }
    if (methodName == 'expand') {
      _checkExpand(node);
      return;
    }

    // Handle flex widget constructor calls parsed as MethodInvocation
    _checkFlexWidget(node.staticType, node.argumentList);
  }

  /// Checks a flex widget (Row/Column/Flex) for SizedBox spacers in children.
  void _checkFlexWidget(DartType? staticType, ArgumentList argumentList) {
    if (staticType == null) return;

    final match = _flexWidgets.firstWhereOrNull((e) => e.$1.isExactlyType(staticType));
    if (match == null) return;

    // Check that the widget doesn't already have a spacing argument
    final hasSpacingArg = argumentList.arguments.whereType<NamedArgument>().any(
      (arg) => arg.name.lexeme == 'spacing',
    );
    if (hasSpacingArg) return;
    if (!_preservesMainAxisDistribution(argumentList)) return;

    // Find the children argument
    final childrenArg = argumentList.arguments.whereType<NamedArgument>().firstWhereOrNull(
      (arg) => arg.name.lexeme == 'children',
    );
    if (childrenArg == null) return;

    final childrenExpr = childrenArg.argumentExpression;

    // Pattern 1: Direct list literal with SizedBox spacers
    if (childrenExpr is ListLiteral) {
      final axis = match.$2 ?? _literalFlexAxis(argumentList);
      if (axis != null) _checkDirectSizedBoxInList(childrenExpr, axis);
    }
  }

  FlexAxis? _literalFlexAxis(ArgumentList arguments) {
    final direction = arguments.arguments
        .whereType<NamedArgument>()
        .firstWhereOrNull((argument) => argument.name.lexeme == 'direction')
        ?.argumentExpression;
    final name = _flutterEnumConstantName(direction, 'Axis');
    return switch (name) {
      'horizontal' => FlexAxis.horizontal,
      'vertical' => FlexAxis.vertical,
      _ => null,
    };
  }

  bool _preservesMainAxisDistribution(ArgumentList arguments) {
    final alignment = arguments.arguments
        .whereType<NamedArgument>()
        .firstWhereOrNull((argument) => argument.name.lexeme == 'mainAxisAlignment')
        ?.argumentExpression;
    if (alignment == null) return true;
    final name = _flutterEnumConstantName(alignment, 'MainAxisAlignment');
    return const {'start', 'center', 'end', 'spaceBetween'}.contains(name);
  }

  String? _flutterEnumConstantName(Expression? expression, String enumName) {
    final type = expression?.staticType;
    if (type is! InterfaceType ||
        !TypeChecker.fromName(enumName, packageName: 'flutter').isExactlyType(type)) {
      return null;
    }
    final constant = expression?.computeConstantValue()?.value;
    if (constant == null || !constant.hasKnownValue) return null;
    final variable = constant.variable;
    if (variable is FieldElement && variable.isEnumConstant) return variable.name;
    final index = constant.getField('index')?.toIntValue();
    if (index == null) return null;
    final members = type.element.fields.where((field) => field.isEnumConstant).toList();
    return index >= 0 && index < members.length ? members[index].name : null;
  }

  /// Pattern 1: Direct SizedBox widgets used as spacers in a children list.
  /// Only triggers when all SizedBox spacers have the same value (uniform).
  void _checkDirectSizedBoxInList(ListLiteral list, FlexAxis parentAxis) {
    final sizedBoxes = _uniformSizedBoxes(list, parentAxis);
    if (sizedBoxes == null) return;
    for (final sizedBox in sizedBoxes) {
      rule.reportAtNode(sizedBox);
    }
  }

  List<Expression>? _uniformSizedBoxes(ListLiteral list, FlexAxis parentAxis) {
    if (list.elements.length < 3 || list.elements.length.isEven) return null;
    final sizedBoxes = <Expression>[];
    String? uniformValue;
    for (var index = 0; index < list.elements.length; index++) {
      final element = list.elements[index];
      if (index.isEven) {
        if (!_isRetainedChild(element, parentAxis)) return null;
        continue;
      }
      final spacingInfo = _constantSeparator(element, parentAxis);
      if (spacingInfo == null || element is! Expression) return null;
      sizedBoxes.add(element);
      uniformValue ??= spacingInfo.$2;
      if (uniformValue != spacingInfo.$2) return null;
    }
    return sizedBoxes;
  }

  bool _isRetainedChild(CollectionElement element, FlexAxis axis) {
    if (element is! Expression) return false;
    final spacing = _extractSizedBoxSpacingFromExpr(element);
    return spacing == null || !_matchesAxis(spacing.$1, axis);
  }

  (String, String)? _constantSeparator(CollectionElement element, FlexAxis axis) {
    if (element is! Expression) return null;
    final spacing = _extractSizedBoxSpacingFromExpr(element);
    if (spacing == null || !_matchesAxis(spacing.$1, axis)) return null;
    return _hasConstantExtent(element, spacing.$1) ? spacing : null;
  }

  bool _hasConstantExtent(Expression element, String axis) {
    final arguments = switch (element) {
      InstanceCreationExpression(:final argumentList) => argumentList.arguments,
      MethodInvocation(:final argumentList) => argumentList.arguments,
      _ => null,
    };
    final extent = arguments
        ?.whereType<NamedArgument>()
        .firstWhereOrNull((argument) => argument.name.lexeme == axis)
        ?.argumentExpression;
    final value = extent?.computeConstantValue()?.value;
    return value?.toIntValue() != null || value?.toDoubleValue() != null;
  }

  bool _matchesAxis(String axis, FlexAxis? parentAxis) {
    if (parentAxis == null) return true;
    return parentAxis == FlexAxis.vertical ? axis == 'height' : axis == 'width';
  }

  /// Pattern 2: `.separatedBy(SizedBox(...))` on a list used as children.
  void _checkSeparatedBy(MethodInvocation node) {
    if (!_isChildrenOfFlexWidget(node)) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final separatorArg = args.first;
    if (_extractSizedBoxSpacingFromExpr(separatorArg.argumentExpression) == null) return;

    rule.reportAtNode(node);
  }

  /// Pattern 3: `.expand((w) sync* { yield SizedBox(...); yield w; })`
  void _checkExpand(MethodInvocation node) {
    if (!_isChildrenOfFlexWidget(node)) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final callback = args.first.argumentExpression;
    if (callback is! FunctionExpression) return;

    final body = callback.body;
    if (body is! BlockFunctionBody) return;

    final finder = _SizedBoxYieldFinder();
    body.visitChildren(finder);

    if (finder.foundSizedBoxYield) {
      rule.reportAtNode(node);
    }
  }

  /// Checks if a node is used as the `children` argument of a Row/Column/Flex.
  bool _isChildrenOfFlexWidget(Expression node) {
    // Walk up through chained method calls like .skip(1).toList()
    // where our node is the target (receiver) of subsequent calls
    AstNode topOfChain = node;
    while (topOfChain.parent is MethodInvocation) {
      final parent = topOfChain.parent! as MethodInvocation;
      if (parent.target != topOfChain) break;
      topOfChain = parent;
    }

    // Should be a NamedArgument(children: ...)
    final namedExpr = topOfChain.parent;
    if (namedExpr is! NamedArgument) return false;
    if (namedExpr.name.lexeme != 'children') return false;

    final argList = namedExpr.parent;
    if (argList is! ArgumentList) return false;

    final parentExpr = argList.parent;

    // Check parent doesn't already have spacing arg
    final parentArgs = switch (parentExpr) {
      InstanceCreationExpression() => parentExpr.argumentList.arguments,
      MethodInvocation() => parentExpr.argumentList.arguments,
      _ => null,
    };
    if (parentArgs == null) return false;

    final hasSpacingArg = parentArgs.whereType<NamedArgument>().any(
      (arg) => arg.name.lexeme == 'spacing',
    );
    if (hasSpacingArg) return false;

    // Check if parent is a flex widget
    final parentType = switch (parentExpr) {
      InstanceCreationExpression() => parentExpr.staticType,
      MethodInvocation() => parentExpr.staticType,
      _ => null,
    };
    if (parentType == null) return false;

    return _flexWidgets.any((e) => e.$1.isExactlyType(parentType));
  }

  /// Extracts spacing info from an expression that might be a SizedBox.
  /// Handles both InstanceCreationExpression and MethodInvocation forms.
  /// Returns (paramName, valueSource) or null.
  static (String, String)? _extractSizedBoxSpacingFromExpr(Expression expr) {
    if (expr is InstanceCreationExpression) {
      if (!isExpressionExactlyType(expr, _sizedBoxChecker)) return null;
      return _extractSizedBoxSpacing(expr.argumentList.arguments);
    }
    if (expr is MethodInvocation) {
      if (!isExpressionExactlyType(expr, _sizedBoxChecker)) return null;
      return _extractSizedBoxSpacing(expr.argumentList.arguments);
    }
    return null;
  }

  /// Extracts spacing info from SizedBox arguments.
  /// Returns (paramName, valueSource) or null if not a pure spacer.
  static (String, String)? _extractSizedBoxSpacing(NodeList<Argument> args) {
    String? spacingParam;
    String? spacingValue;

    for (final arg in args) {
      if (arg is NamedArgument) {
        final name = arg.name.lexeme;
        if (name == 'key') return null;
        if ((name == 'height' || name == 'width') && spacingParam == null) {
          spacingParam = name;
          spacingValue = arg.argumentExpression.toSource();
        } else {
          return null; // has child, both dimensions, or other params
        }
      } else {
        return null; // positional args not expected
      }
    }

    if (spacingParam == null || spacingValue == null) return null;
    return (spacingParam, spacingValue);
  }
}

/// Recursively searches for `yield SizedBox(...)` expressions.
class _SizedBoxYieldFinder extends RecursiveAstVisitor<void> {
  bool foundSizedBoxYield = false;

  @override
  void visitYieldStatement(YieldStatement node) {
    final expr = node.expression;
    if (_Visitor._extractSizedBoxSpacingFromExpr(expr) != null) {
      foundSizedBoxYield = true;
    }
    super.visitYieldStatement(node);
  }

  // Stop at nested function boundaries
  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
