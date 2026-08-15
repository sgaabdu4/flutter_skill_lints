import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:flutter_skill_lints/src/additional_lints/flutter_widget_helpers.dart';
import 'package:flutter_skill_lints/src/additional_lints/widget_sequence.dart';

/// Fix that merges a sequence of nested widgets into a single Container.
class PreferContainerFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.preferContainer',
    DartFixKindPriority.standard,
    'Replace with Container',
  );

  PreferContainerFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  /// Maps widget names to the Container parameter names they contribute.
  static const _widgetParamMapping = <String, List<String>>{
    'Padding': ['padding'],
    'Align': ['alignment'],
    'Center': [], // Center contributes alignment: Alignment.center implicitly
    'ColoredBox': ['color'],
    'DecoratedBox': ['decoration'],
    'ConstrainedBox': ['constraints'],
    'SizedBox': ['width', 'height'],
    'Transform': ['transform'],
    'ClipRRect': ['clipBehavior'],
    'ClipOval': ['clipBehavior'],
    'ClipPath': ['clipBehavior'],
    'FractionallySizedBox': ['widthFactor', 'heightFactor', 'alignment'],
    'Opacity': ['opacity'],
    'IntrinsicHeight': [],
    'IntrinsicWidth': [],
    'LimitedBox': ['maxWidth', 'maxHeight'],
  };

  static const _containerArgumentMapping = <String, Map<String, String>>{
    'Padding': {'padding': 'padding'},
    'Align': {
      'alignment': 'alignment',
      'widthFactor': 'widthFactor',
      'heightFactor': 'heightFactor',
    },
    'Center': {'alignment': 'alignment'},
    'ColoredBox': {'color': 'color'},
    'DecoratedBox': {'decoration': 'decoration', 'position': 'foregroundDecoration'},
    'ConstrainedBox': {'constraints': 'constraints'},
    'SizedBox': {'width': 'width', 'height': 'height'},
    'Transform': {'transform': 'transform', 'alignment': 'transformAlignment'},
    'ClipRRect': {'clipBehavior': 'clipBehavior'},
    'ClipOval': {'clipBehavior': 'clipBehavior'},
    'ClipPath': {'clipBehavior': 'clipBehavior'},
    'FractionallySizedBox': {'alignment': 'alignment'},
  };

  /// Widget names that are container-compatible.
  static const _containerCompatibleWidgets = {
    'Padding',
    'Align',
    'Center',
    'ColoredBox',
    'DecoratedBox',
    'ConstrainedBox',
    'SizedBox',
    'Transform',
    'ClipRRect',
    'ClipOval',
    'ClipPath',
    'FractionallySizedBox',
    'Opacity',
    'IntrinsicHeight',
    'IntrinsicWidth',
    'LimitedBox',
  };

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    // Find the outermost widget expression
    final Expression outerWidget;
    if (targetNode is ConstructorName) {
      final parent = targetNode.parent;
      if (parent is! InstanceCreationExpression) return;
      outerWidget = parent;
    } else if (targetNode is SimpleIdentifier && targetNode.parent is MethodInvocation) {
      outerWidget = targetNode.parent! as MethodInvocation;
    } else {
      return;
    }

    // Collect the sequence of widgets
    final sequence = collectWidgetSequence(outerWidget, _getWidgetInfo);
    if (sequence.length < 3) return;

    // Build the Container replacement
    final replacement = _buildContainerReplacement(sequence);
    if (replacement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(outerWidget), replacement);
    });
  }

  static WidgetInfo? _getWidgetInfo(Expression expr) {
    final name = allowedWidgetName(expr, _containerCompatibleWidgets);
    if (expr is InstanceCreationExpression) {
      if (name == null) return null;
      return (name: name, argumentList: expr.argumentList, node: expr);
    }
    if (expr is MethodInvocation) {
      if (name == null) return null;
      return (name: name, argumentList: expr.argumentList, node: expr);
    }
    return null;
  }

  /// Builds the Container replacement string from the widget sequence.
  static String? _buildContainerReplacement(List<WidgetInfo> sequence) {
    final parts = _collectContainerParts(sequence);
    if (parts == null) return null;

    final buffer = StringBuffer('Container(');
    if (parts.keySource != null) buffer.write('key: ${parts.keySource}, ');
    for (final param in parts.params) {
      buffer.write('$param, ');
    }
    if (parts.childSource != null) buffer.write('child: ${parts.childSource}, ');
    buffer.write(')');
    return buffer.toString();
  }

  static ({String? childSource, String? keySource, List<String> params})? _collectContainerParts(
    List<WidgetInfo> sequence,
  ) {
    final params = <String>[];
    String? keySource;

    for (final widget in sequence) {
      if (_widgetParamMapping[widget.name] == null) return null;
      final widgetParts = _collectWidgetParts(widget);
      keySource ??= widgetParts.keySource;
      params.addAll(widgetParts.params);
    }

    final innermost = sequence.last;
    final innerChild = getWidgetChildExpression(innermost.argumentList);
    return (keySource: keySource, params: params, childSource: innerChild?.toSource());
  }

  static ({String? keySource, List<String> params}) _collectWidgetParts(WidgetInfo widget) {
    String? keySource;
    final params = <String>[];
    for (final arg in widget.argumentList.arguments.whereType<NamedArgument>()) {
      final argName = arg.name.lexeme;
      if (argName == 'key') {
        keySource ??= arg.argumentExpression.toSource();
        continue;
      }
      if (argName == 'child') continue;
      final containerParam = _mapArgToContainerParam(widget.name, argName);
      if (containerParam != null) {
        params.add('$containerParam: ${arg.argumentExpression.toSource()}');
      }
    }
    if (widget.name == 'Center' &&
        !widget.argumentList.arguments.whereType<NamedArgument>().any(
          (argument) => argument.name.lexeme == 'alignment',
        )) {
      params.add('alignment: Alignment.center');
    }
    return (keySource: keySource, params: params);
  }

  /// Maps a widget's argument name to the corresponding Container parameter.
  static String? _mapArgToContainerParam(String widgetName, String argName) {
    return _containerArgumentMapping[widgetName]?[argName];
  }
}
