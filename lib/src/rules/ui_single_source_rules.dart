import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> uiSingleSourceRules = [
  /// Base controls belong to the shared UI library listed in hard-eng.gates.json.
  scannerRule(
    code: const LintCode(
      'ui_base_control_outside_library',
      'Base controls belong to the shared UI library.',
      correctionMessage: 'Make it a part of the shared library and use that part',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags base buttons, text fields, dropdowns, dialogs and search widgets built outside the ui_library paths of hard-eng.gates.json (lib/core/widgets/ when it lists none).',
    scan: (reporter, context) {
      if (!context.path.startsWith('lib/') || context.isTestFile) return;
      if (!context.source.masked.any(_baseControlName.hasMatch)) return;

      final visitor = _BaseControlVisitor();
      context.unit.accept(visitor);
      if (visitor.offsets.isEmpty || context.isUiLibraryFile) return;
      for (final offset in visitor.offsets) {
        reporter.reportOffset(context, offset);
      }
    },
  ),
];

const _baseControls = {
  'ElevatedButton',
  'FilledButton',
  'OutlinedButton',
  'TextButton',
  'IconButton',
  'CupertinoButton',
  'TextField',
  'TextFormField',
  'CupertinoTextField',
  'CupertinoTextFormFieldRow',
  'DropdownButton',
  'DropdownButtonFormField',
  'DropdownMenu',
  'AlertDialog',
  'SimpleDialog',
  'Dialog',
  'CupertinoAlertDialog',
  'SearchBar',
  'SearchAnchor',
  'CupertinoSearchTextField',
};

final _baseControlName = RegExp('\\b(?:${_baseControls.join('|')})\\b');

final class _BaseControlVisitor extends RecursiveAstVisitor<void> {
  final offsets = <int>[];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.constructorName.type;
    final uri = type.element?.library?.identifier;
    if (_baseControls.contains(type.name.lexeme) && uri != null && isFlutterUiLibraryUri(uri)) {
      offsets.add(node.constructorName.offset);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitDotShorthandConstructorInvocation(DotShorthandConstructorInvocation node) {
    final type = node.staticType;
    final element = type is InterfaceType ? type.element : null;
    final uri = element?.library.identifier;
    if (element != null &&
        _baseControls.contains(element.name) &&
        uri != null &&
        isFlutterUiLibraryUri(uri)) {
      offsets.add(node.offset);
    }
    super.visitDotShorthandConstructorInvocation(node);
  }
}
