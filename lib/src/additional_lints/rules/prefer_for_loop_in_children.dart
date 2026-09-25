import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when functional approaches (`.map().toList()`, `List.generate()`,
/// `.fold()`, spread with `.map()`) are used to build widget lists instead
/// of collection-for syntax.
class PreferForLoopInChildren extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_for_loop_in_children',
    'Prefer using a for-loop instead of functional list building.',
    correctionMessage: 'Use collection-for syntax: [for (final item in items) Widget(item)].',
    severity: DiagnosticSeverity.ERROR,
  );

  PreferForLoopInChildren()
    : super(
        name: 'prefer_for_loop_in_children',
        description:
            'Warns when .map().toList(), List.generate(), .fold(), or '
            'spread with .map() are used to build widget lists instead of '
            'collection-for syntax.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addListLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferForLoopInChildren rule;
  static const _widgetChecker = TypeChecker.fromName('Widget', packageName: 'flutter');
  static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');
  static const _listChecker = TypeChecker.fromUrl('dart:core#List');

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;

    // Pattern 1: iterable.map((e) => ...).toList()
    if (methodName == 'toList') {
      _checkMapToList(node);
      return;
    }

    // Pattern 4: iterable.fold([], (list, e) { ... })
    if (methodName == 'fold') {
      _checkFold(node);
      return;
    }

    // Pattern 3: List.generate(n, (i) => ...) — parsed as MethodInvocation
    // when no type args
    if (methodName == 'generate') {
      _checkListGenerate(node);
      return;
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Pattern 3: List<Widget>.generate(n, (i) => ...) — parsed as
    // InstanceCreationExpression when type args are present
    final constructorName = node.constructorName;
    if (constructorName.name?.name == 'generate') {
      if (_isWidgetCollection(node.staticType) &&
          _listChecker.isExactlyType(node.staticType!) &&
          _isGrowable(node.argumentList)) {
        final args = node.argumentList.arguments;
        if (args.length >= 2 && args[1] is FunctionExpression) {
          rule.reportAtNode(node);
        }
      }
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    // Pattern 2: [...iterable.map((e) => ...)]
    for (final element in node.elements) {
      if (element is SpreadElement) {
        _checkSpreadMap(element);
      }
    }
  }

  /// Pattern 1: `iterable.map((e) => ...).toList()`
  void _checkMapToList(MethodInvocation node) {
    // Skip if inside a spread — Pattern 2 handles that case
    if (node.parent is SpreadElement) return;

    final target = node.target;
    if (target is! MethodInvocation) return;
    if (target.methodName.name != 'map') return;
    if (!_isCoreIterableMethod(node) || !_isCoreIterableMethod(target)) return;
    if (!_isWidgetCollection(node.staticType)) return;
    if (!_isGrowable(node.argumentList)) return;

    final args = target.argumentList.arguments;
    if (args.isEmpty) return;
    if (args.first is! FunctionExpression) return;

    rule.reportAtNode(node);
  }

  /// Pattern 3: `List.generate(n, (i) => ...)` without type args
  void _checkListGenerate(MethodInvocation node) {
    final target = node.target;
    if (target is! SimpleIdentifier) return;
    if (target.name != 'List') return;

    // Verify it resolves to dart:core List
    final element = target.element;
    if (element == null) return;
    final library = element.library;
    if (library == null || !library.identifier.startsWith('dart:core')) return;
    if (!_isWidgetCollection(node.staticType)) return;
    if (!_isGrowable(node.argumentList)) return;

    final args = node.argumentList.arguments;
    if (args.length < 2) return;
    if (args[1] is! FunctionExpression) return;

    rule.reportAtNode(node);
  }

  /// Pattern 4: `iterable.fold([], (list, e) { list.add(...); return list; })`
  void _checkFold(MethodInvocation node) {
    if (!_isCoreIterableMethod(node) ||
        !_isWidgetCollection(node.staticType) ||
        !_listChecker.isExactlyType(node.staticType!)) {
      return;
    }
    final args = node.argumentList.arguments;
    if (args.length < 2) return;

    // First arg should be an empty list literal
    final initialValue = args.first;
    if (initialValue is! ListLiteral) return;
    if (initialValue.elements.isNotEmpty || initialValue.constKeyword != null) return;

    // Only an append-once fold can become one collection-for child per item.
    final callback = args[1];
    if (callback is! FunctionExpression || !_isAppendOnceFold(callback)) return;

    rule.reportAtNode(node);
  }

  /// Pattern 2: `...iterable.map((e) => ...)` inside a list literal,
  /// including `...iterable.map((e) => ...).toList()`
  void _checkSpreadMap(SpreadElement spread) {
    var expr = spread.expression;

    // Unwrap optional .toList()
    if (expr is MethodInvocation && expr.methodName.name == 'toList') {
      expr = expr.target!;
    }

    if (expr is! MethodInvocation) return;
    if (expr.methodName.name != 'map') return;
    if (!_isCoreIterableMethod(expr) || !_isWidgetCollection(expr.staticType)) return;

    final args = expr.argumentList.arguments;
    if (args.isEmpty) return;
    if (args.first is! FunctionExpression) return;

    rule.reportAtNode(spread);
  }

  static bool _isWidgetCollection(DartType? type) {
    return type is InterfaceType &&
        type.typeArguments.length == 1 &&
        _iterableChecker.isAssignableFromType(type) &&
        _widgetChecker.isAssignableFromType(type.typeArguments.single);
  }

  static bool _isGrowable(ArgumentList arguments) {
    for (final argument in arguments.arguments.whereType<NamedArgument>()) {
      if (argument.name.lexeme == 'growable') {
        return argument.argumentExpression.computeConstantValue()?.value?.toBoolValue() == true;
      }
    }
    return true;
  }

  static bool _isCoreIterableMethod(MethodInvocation node) {
    final method = node.methodName.element;
    return method is MethodElement && method.library.identifier == 'dart:core';
  }

  static bool _isAppendOnceFold(FunctionExpression callback) {
    final parameters = callback.parameters?.parameters;
    if (parameters == null || parameters.length != 2) return false;
    final accumulator = parameters.first.declaredFragment?.element;
    if (accumulator == null) return false;

    final addCall = switch (callback.body) {
      final BlockFunctionBody body => _blockAppendCall(body, accumulator),
      final ExpressionFunctionBody body => _cascadeAppendCall(body.expression, accumulator),
      _ => null,
    };
    if (addCall == null ||
        addCall.methodName.name != 'add' ||
        addCall.argumentList.arguments.length != 1) {
      return false;
    }
    final method = addCall.methodName.element;
    if (method is! MethodElement ||
        method.library.identifier != 'dart:core' ||
        method.enclosingElement?.name != 'List') {
      return false;
    }
    final finder = _AccumulatorReferenceFinder(accumulator);
    addCall.argumentList.arguments.single.accept(finder);
    return !finder.found;
  }

  static MethodInvocation? _blockAppendCall(BlockFunctionBody body, Element accumulator) {
    final statements = body.block.statements;
    if (statements.length == 1 && statements.single is ReturnStatement) {
      return _cascadeAppendCall((statements.single as ReturnStatement).expression, accumulator);
    }
    if (statements.length != 2 ||
        statements.first is! ExpressionStatement ||
        statements.last is! ReturnStatement) {
      return null;
    }
    final add = (statements.first as ExpressionStatement).expression;
    final returned = (statements.last as ReturnStatement).expression;
    if (add is! MethodInvocation ||
        add.target is! SimpleIdentifier ||
        (add.target! as SimpleIdentifier).element != accumulator ||
        returned is! SimpleIdentifier ||
        returned.element != accumulator) {
      return null;
    }
    return add;
  }

  static MethodInvocation? _cascadeAppendCall(Expression? expression, Element accumulator) {
    if (expression is! CascadeExpression ||
        expression.target is! SimpleIdentifier ||
        (expression.target as SimpleIdentifier).element != accumulator ||
        expression.cascadeSections.length != 1 ||
        expression.cascadeSections.single is! MethodInvocation) {
      return null;
    }
    return expression.cascadeSections.single as MethodInvocation;
  }
}

final class _AccumulatorReferenceFinder extends RecursiveAstVisitor<void> {
  _AccumulatorReferenceFinder(this.accumulator);

  final Element accumulator;
  bool found = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element == accumulator) found = true;
    super.visitSimpleIdentifier(node);
  }
}
