import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Fix that converts a StatefulWidget to a StatelessWidget by inlining the
/// build method and removing the State class.
class AvoidUnnecessaryStatefulWidgetsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.convertStatefulToStatelessWidget',
    DartFixKindPriority.standard,
    'Convert to StatelessWidget',
  );

  AvoidUnnecessaryStatefulWidgetsFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final target = _targetWidget(node);
    if (target == null) return;
    final unit = target.widgetClass.parent;
    if (unit is! CompilationUnit) return;
    final stateClass = findStateClass(
      unit.declarations.whereType<ClassDeclaration>(),
      target.widgetName,
    );
    if (stateClass == null) return;
    final newClass = _statelessClassSource(target.widgetClass, stateClass);
    if (newClass == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(target.widgetClass), newClass);
      _deleteStateClass(builder, stateClass, unitResult.content);
    });
  }

  static ({ClassDeclaration widgetClass, String widgetName})? _targetWidget(AstNode targetNode) {
    if (targetNode is! SimpleIdentifier || targetNode.parent is! ClassDeclaration) return null;
    final widgetClass = targetNode.parent! as ClassDeclaration;
    if (widgetClass.extendsClause?.superclass == null) return null;
    return (widgetClass: widgetClass, widgetName: targetNode.name);
  }

  static String? _statelessClassSource(ClassDeclaration widgetClass, ClassDeclaration stateClass) {
    final widgetBody = widgetClass.body;
    final stateBody = stateClass.body;
    if (widgetBody is! BlockClassBody || stateBody is! BlockClassBody) return null;
    final buildMethod = stateBody.members.whereType<MethodDeclaration>().firstWhereOrNull(
      (member) => member.name.lexeme == 'build',
    );
    if (buildMethod == null) return null;
    final members = <String>[..._widgetMembers(widgetBody), ..._stateMembers(stateBody)];
    members.add(buildMethod.toSource());
    final annotations = widgetClass.metadata.map((metadata) => metadata.toSource()).join('\n');
    final prefix = annotations.isEmpty ? '' : '$annotations\n';
    final abstractKeyword = widgetClass.abstractKeyword == null ? '' : 'abstract ';
    return '$prefix${abstractKeyword}class ${widgetClass.namePart.typeName.lexeme} '
        'extends StatelessWidget {\n  ${members.join('\n\n  ')}\n}';
  }

  static Iterable<String> _widgetMembers(BlockClassBody body) sync* {
    for (final member in body.members) {
      if (member is MethodDeclaration && member.name.lexeme == 'createState') continue;
      yield member.toSource();
    }
  }

  static Iterable<String> _stateMembers(BlockClassBody body) sync* {
    const lifecycleMethods = {
      'initState',
      'dispose',
      'didChangeDependencies',
      'didUpdateWidget',
      'deactivate',
      'activate',
      'reassemble',
      'createState',
      'build',
    };
    for (final member in body.members) {
      if (member is MethodDeclaration && lifecycleMethods.contains(member.name.lexeme)) continue;
      if (member is MethodDeclaration || member is FieldDeclaration) yield member.toSource();
    }
  }

  static void _deleteStateClass(
    DartFileEditBuilder builder,
    ClassDeclaration stateClass,
    String content,
  ) {
    var deleteStart = stateClass.offset;
    while (deleteStart > 0 && content[deleteStart - 1] == '\n') {
      deleteStart--;
    }
    if (deleteStart < stateClass.offset) deleteStart++;
    var deleteEnd = stateClass.end;
    while (deleteEnd < content.length && content[deleteEnd] == '\n') {
      deleteEnd++;
    }
    builder.addDeletion(range.startOffsetEndOffset(deleteStart, deleteEnd));
  }
}
