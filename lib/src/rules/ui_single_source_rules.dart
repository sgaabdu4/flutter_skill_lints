import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> uiSingleSourceRules = [
  /// Base controls belong to the shared UI library, lib/core/widgets/.
  scannerRule(
    code: const LintCode(
      'ui_base_control_outside_library',
      'Base controls belong to the shared UI library.',
      correctionMessage: 'Make it a part of the shared library and use that part',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags input controls (a widget a person presses, types in, picks or toggles, and the dialogs and sheets that ask the person to choose) built outside lib/core/widgets/.',
    scan: (reporter, context) {
      if (!context.path.startsWith('lib/') || context.isTestFile) return;

      final visitor = _BaseControlVisitor();
      context.unit.accept(visitor);
      if (visitor.offsets.isEmpty || context.isUiLibraryFile) return;
      for (final offset in visitor.offsets) {
        reporter.reportOffset(context, offset);
      }
    },
  ),
];

const uiBaseControlClasses = {
  'ExpandIcon',
  'TextSelectionToolbarTextButton',
  'DesktopTextSelectionToolbarButton',
  'CupertinoTextSelectionToolbarButton',
  'CupertinoDesktopTextSelectionToolbarButton',
  'AboutDialog',
  'CupertinoActionSheet',
  'CupertinoActionSheetAction',
  'CupertinoDialogAction',
  'SimpleDialogOption',
  'CupertinoContextMenuAction',
  'CupertinoNavigationBarBackButton',
  'ActionChip',
  'ChoiceChip',
  'FilterChip',
  'InputChip',
  'RawChip',
  'CheckboxMenuButton',
  'RadioMenuButton',
  'CupertinoDatePicker',
  'CupertinoTimerPicker',
  'CupertinoPicker',
  'CalendarDatePicker',
  'YearPicker',
  'InputDatePickerFormField',
  'RawRadio',
  'EditableText',
  'SnackBarAction',
  'CupertinoMenuItem',
  'ElevatedButton',
  'FilledButton',
  'OutlinedButton',
  'TextButton',
  'IconButton',
  'MaterialButton',
  'BackButton',
  'CloseButton',
  'DrawerButton',
  'EndDrawerButton',
  'RawMaterialButton',
  'Autocomplete',
  'RawAutocomplete',
  'FloatingActionButton',
  'SegmentedButton',
  'ToggleButtons',
  'MenuItemButton',
  'SubmenuButton',
  'CupertinoSegmentedControl',
  'CupertinoSlidingSegmentedControl',
  'CupertinoButton',
  'TextField',
  'TextFormField',
  'CupertinoTextField',
  'CupertinoTextFormFieldRow',
  'DropdownButton',
  'DropdownButtonFormField',
  'DropdownMenu',
  'DropdownMenuFormField',
  'PopupMenuButton',
  'AlertDialog',
  'SimpleDialog',
  'DatePickerDialog',
  'TimePickerDialog',
  'DateRangePickerDialog',
  'Dialog',
  'CupertinoAlertDialog',
  'SearchBar',
  'SearchAnchor',
  'Checkbox',
  'CheckboxListTile',
  'Radio',
  'RadioListTile',
  'Switch',
  'SwitchListTile',
  'Slider',
  'RangeSlider',
  'CupertinoCheckbox',
  'CupertinoRadio',
  'CupertinoSwitch',
  'CupertinoSlider',
  'CupertinoSearchTextField',
};

const uiConditionalControlClasses = {'Chip': 'onDeleted'};

final class _BaseControlVisitor extends RecursiveAstVisitor<void> {
  final offsets = <int>[];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (_isBaseControl(type) || _isConditionalControl(type, node.argumentList)) {
      offsets.add(node.constructorName.offset);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitDotShorthandConstructorInvocation(DotShorthandConstructorInvocation node) {
    final type = node.staticType;
    if (_isBaseControl(type) || _isConditionalControl(type, node.argumentList)) {
      offsets.add(node.offset);
    }
    super.visitDotShorthandConstructorInvocation(node);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    if (_isControlClass(node.superclass.type)) offsets.add(node.superclass.offset);
    super.visitExtendsClause(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    if (_isControlClass(node.superclass.type)) offsets.add(node.superclass.offset);
    super.visitClassTypeAlias(node);
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    final type = node.staticType;
    if (type is FunctionType && _isControlClass(type.returnType)) {
      offsets.add(node.constructorName.offset);
    }
    super.visitConstructorReference(node);
  }

  static bool _isConditionalControl(DartType? type, ArgumentList arguments) {
    final element = type is InterfaceType ? type.element : null;
    final callback = element == null ? null : uiConditionalControlClasses[element.name];
    final uri = element?.library.identifier;
    if (callback == null || uri == null || !isFlutterUiLibraryUri(uri)) return false;
    return arguments.arguments.whereType<NamedArgument>().any(
      (argument) => argument.name.lexeme == callback && argument.argumentExpression is! NullLiteral,
    );
  }

  static bool _isControlClass(DartType? type) {
    final element = type is InterfaceType ? type.element : null;
    return _isBaseControl(type) ||
        (element != null &&
            uiConditionalControlClasses.containsKey(element.name) &&
            isFlutterUiLibraryUri(element.library.identifier));
  }

  static bool _isBaseControl(DartType? type) {
    final element = type is InterfaceType ? type.element : null;
    final uri = element?.library.identifier;
    return element != null &&
        uiBaseControlClasses.contains(element.name) &&
        uri != null &&
        isFlutterUiLibraryUri(uri);
  }
}
