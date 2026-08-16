import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';

typedef _MapSource = ({String iterable, String parameter, String expression});
typedef _GenerateSource = ({String count, String parameter, String expression});

/// Fix that replaces functional list building with collection-for syntax.
class PreferForLoopInChildrenFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.preferForLoopInChildren',
    DartFixKindPriority.standard,
    'Replace with for-loop',
  );

  PreferForLoopInChildrenFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    // Pattern 1: iterable.map((e) => ...).toList()
    if (targetNode is MethodInvocation && targetNode.methodName.name == 'toList') {
      await _fixMapToList(builder, targetNode);
      return;
    }

    // Pattern 2: ...iterable.map((e) => ...) in a spread
    if (targetNode is SpreadElement) {
      await _fixSpreadMap(builder, targetNode);
      return;
    }

    // Pattern 3: List.generate() — MethodInvocation
    if (targetNode is MethodInvocation && targetNode.methodName.name == 'generate') {
      await _fixListGenerate(builder, targetNode);
      return;
    }

    // Pattern 3: List<Widget>.generate() — InstanceCreationExpression
    if (targetNode is InstanceCreationExpression) {
      await _fixListGenerateInstance(builder, targetNode);
      return;
    }

    // Pattern 4: iterable.fold([], ...)
    if (targetNode is MethodInvocation && targetNode.methodName.name == 'fold') {
      await _fixFold(builder, targetNode);
      return;
    }
  }

  /// Fix: `iterable.map((e) => expr).toList()` → `[for (final e in iterable) expr]`
  Future<void> _fixMapToList(ChangeBuilder builder, MethodInvocation toListNode) async {
    final mapCall = toListNode.target;
    if (mapCall is! MethodInvocation) return;

    final source = _mapSource(mapCall);
    if (source == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(toListNode),
        '[for (final ${source.parameter} in ${source.iterable}) ${source.expression}]',
      );
    });
  }

  /// Fix: `[..., ...iterable.map((e) => expr), ...]` → replace spread with for element
  Future<void> _fixSpreadMap(ChangeBuilder builder, SpreadElement spread) async {
    var expr = spread.expression;

    // Unwrap optional .toList()
    if (expr is MethodInvocation && expr.methodName.name == 'toList') {
      expr = expr.target!;
    }

    if (expr is! MethodInvocation) return;

    final source = _mapSource(expr);
    if (source == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(spread),
        'for (final ${source.parameter} in ${source.iterable}) ${source.expression}',
      );
    });
  }

  /// Fix: `List.generate(n, (i) => expr)` → `[for (var i = 0; i < n; i++) expr]`
  Future<void> _fixListGenerate(ChangeBuilder builder, MethodInvocation node) async {
    final source = _generateSource(node.argumentList);
    if (source == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(node),
        '[for (var ${source.parameter} = 0; ${source.parameter} < ${source.count}; ${source.parameter}++) ${source.expression}]',
      );
    });
  }

  /// Fix: `List<T>.generate(n, (i) => expr)` → `[for (var i = 0; i < n; i++) expr]`
  Future<void> _fixListGenerateInstance(
    ChangeBuilder builder,
    InstanceCreationExpression node,
  ) async {
    final source = _generateSource(node.argumentList);
    if (source == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(node),
        '[for (var ${source.parameter} = 0; ${source.parameter} < ${source.count}; ${source.parameter}++) ${source.expression}]',
      );
    });
  }

  static _MapSource? _mapSource(MethodInvocation node) {
    final iterable = node.target;
    if (iterable == null) return null;

    final callback = node.argumentList.arguments.firstOrNull;
    final source = _callbackSource(callback, fallbackParameter: '_');
    if (source == null) return null;

    return (
      iterable: iterable.toSource(),
      parameter: source.parameter,
      expression: source.expression,
    );
  }

  static _GenerateSource? _generateSource(ArgumentList argumentList) {
    final args = argumentList.arguments;
    if (args.length < 2) return null;

    final source = _callbackSource(args[1], fallbackParameter: 'i');
    if (source == null) return null;

    return (
      count: args.first.toSource(),
      parameter: source.parameter,
      expression: source.expression,
    );
  }

  static ({String parameter, String expression})? _callbackSource(
    Argument? callback, {
    required String fallbackParameter,
  }) {
    if (callback is! FunctionExpression) return null;
    final parameter = callback.parameters?.parameters.firstOrNull;
    if (parameter == null) return null;
    final body = maybeGetSingleReturnExpression(callback.body);
    if (body == null) return null;
    return (parameter: parameter.name?.lexeme ?? fallbackParameter, expression: body.toSource());
  }

  /// Fix: `iterable.fold([], (list, e) { ... })` → `[for (final e in iterable) ...]`
  /// Note: fold patterns are complex; only fix simple cases.
  Future<void> _fixFold(ChangeBuilder builder, MethodInvocation node) async {
    final iterable = node.target;
    if (iterable == null) return;

    final args = node.argumentList.arguments;
    if (args.length < 2) return;

    final callback = args[1];
    if (callback is! FunctionExpression) return;

    final params = callback.parameters?.parameters;
    if (params == null || params.length < 2) return;

    final elementParam = params[1];
    final elementName = elementParam.name?.lexeme ?? '_';
    final iterableSource = iterable.toSource();

    // Try to extract the expression being added
    final addExpr = _extractFoldAddExpression(callback.body);
    if (addExpr == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(node),
        '[for (final $elementName in $iterableSource) $addExpr]',
      );
    });
  }

  /// Tries to extract the expression from a fold callback body like:
  /// `(list, e) { list.add(Expr(e)); return list; }`
  /// Returns the source of the expression added, or null.
  static String? _extractFoldAddExpression(FunctionBody body) {
    if (body is! BlockFunctionBody) return null;

    final statements = body.block.statements;
    // Expect exactly: list.add(expr); return list;
    if (statements.length != 2) return null;

    final addStatement = statements.first;
    if (addStatement is! ExpressionStatement) return null;
    final addCall = addStatement.expression;
    if (addCall is! MethodInvocation) return null;
    if (addCall.methodName.name != 'add') return null;
    if (addCall.argumentList.arguments.length != 1) return null;

    final addedExpr = addCall.argumentList.arguments.first;
    return addedExpr.toSource();
  }
}
