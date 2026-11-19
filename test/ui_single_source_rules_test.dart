import 'dart:math' as math;

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/ui_project_paths.dart';
import 'package:flutter_skill_lints/src/rules/ui_single_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/ui_source_rules.dart';
import 'package:test/test.dart';

void main() {
  test('base controls and raw values outside the library and theme are reported', () async {
    await _run(_BaseControlsTest.new, (t) => t.reportsOutsideTheDefaultLibrary());
    await _run(_BaseControlsTest.new, (t) => t.allowsInsideTheDefaultLibrary());
    await _run(_BaseControlsTest.new, (t) => t.reportsControlsWithTypeArguments());
    await _run(_BaseControlsTest.new, (t) => t.reportsOnlyFlutterControls());
    await _run(_BaseControlsTest.new, (t) => t.reportsTheWholeButtonFamily());
    await _run(_BaseControlsTest.new, (t) => t.reportsTogglesAndSliders());
    await _run(_BaseControlsTest.new, (t) => t.reportsAControlInferredFromAnotherFile());
    await _run(_BaseControlsTest.new, (t) => t.reportsAControlBuiltThroughAnAlias());
    await _run(_BaseControlsTest.new, (t) => t.ignoresAShorthandOnAnotherType());
    await _run(_BaseControlsTest.new, (t) => t.readsLibraryPathsFromTheGatesFile());
    await _run(_BaseControlsTest.new, (t) => t.readsCharacterSetsInLibraryPaths('[u]', true));
    await _run(_BaseControlsTest.new, (t) => t.readsCharacterSetsInLibraryPaths('[!u]', false));
    await _run(_BaseControlsTest.new, (t) => t.fallsBackWhenTheKeyIsMissing());
    for (final value in ['[]', '[1]', '["lib/ui/*", 2]', '"lib/ui/*"']) {
      await _run(_BaseControlsTest.new, (t) => t.fallsBackWhenTheListIsEmptyOrInvalid(value));
    }
    await _run(_RawTokenTest.new, (t) => t.reportsRawValuesOutsideThemeFiles());
    await _run(_RawTokenTest.new, (t) => t.allowsRawValuesInThemeFiles());
    await _run(_RawTextStyleTest.new, (t) => t.reportsAndAllowsDotShorthandTextStyle());
  });

  test('a changed or removed gates file is seen after the cache warmed', () {
    final provider = MemoryResourceProvider();
    final gates = provider.newFile('/proj/hard-eng.gates.json', _gatesWith('lib/a/*'));
    final source = provider.newFile('/proj/lib/a/x.dart', '');
    bool inLibrary() => resolveUiProjectPaths(source, 'lib/a/x.dart').isInLibrary;

    expect(inLibrary(), isTrue);
    expect(inLibrary(), isTrue);
    gates.writeAsStringSync(_gatesWith('lib/b/*'));
    expect(inLibrary(), isFalse);
    gates.delete();
    expect(inLibrary(), isFalse);
    expect(resolveUiProjectPaths(source, 'lib/core/widgets/x.dart').isInLibrary, isTrue);
  });
}

String _gatesWith(String entry) => '{"version": 1, "shipping": {"ui_library": ["$entry"]}}';

Future<void> _run<T extends _UiRuleTest>(T Function() create, Future<void> Function(T) body) async {
  final fixture = create()..setUp();
  try {
    await body(fixture);
  } finally {
    await fixture.tearDown();
  }
}

const _flutterLibrary = r'''
class Widget {
  const Widget();
}

class ElevatedButton extends Widget {
  const ElevatedButton();
}

class TextField extends Widget {
  const TextField();
}

class DropdownButton<T> extends Widget {
  const DropdownButton();
}

class DropdownButtonFormField<T> extends Widget {
  const DropdownButtonFormField();
}

class DropdownMenu<T> extends Widget {
  const DropdownMenu();
}

class AlertDialog extends Widget {
  const AlertDialog();
}

class SearchBar extends Widget {
  const SearchBar();
}

class FloatingActionButton extends Widget {
  const FloatingActionButton();
  const FloatingActionButton.extended();
}

class SegmentedButton<T> extends Widget {
  const SegmentedButton();
}

class ToggleButtons extends Widget {
  const ToggleButtons();
}

class MenuItemButton extends Widget {
  const MenuItemButton();
}

class SubmenuButton extends Widget {
  const SubmenuButton();
}

class PopupMenuButton<T> extends Widget {
  const PopupMenuButton();
}

class DropdownMenuFormField<T> extends Widget {
  const DropdownMenuFormField();
}

class CupertinoSegmentedControl<T> extends Widget {
  const CupertinoSegmentedControl();
}

class CupertinoSlidingSegmentedControl<T> extends Widget {
  const CupertinoSlidingSegmentedControl();
}

class Checkbox extends Widget {
  const Checkbox();
}

class CheckboxListTile extends Widget {
  const CheckboxListTile();
}

class Radio<T> extends Widget {
  const Radio();
}

class RadioListTile<T> extends Widget {
  const RadioListTile();
}

class Switch extends Widget {
  const Switch();
  const Switch.adaptive();
}

class SwitchListTile extends Widget {
  const SwitchListTile();
}

class Slider extends Widget {
  const Slider();
}

class RangeSlider extends Widget {
  const RangeSlider();
}

class CupertinoCheckbox extends Widget {
  const CupertinoCheckbox();
}

class CupertinoRadio<T> extends Widget {
  const CupertinoRadio();
}

class CupertinoSwitch extends Widget {
  const CupertinoSwitch();
}

class CupertinoSlider extends Widget {
  const CupertinoSlider();
}

class Icon extends Widget {
  const Icon();
}

class TextStyle {
  const TextStyle({double? fontSize});
}

class EdgeInsets {
  const EdgeInsets.symmetric({double vertical = 0, double horizontal = 0});
}

class Pill extends Widget {
  const Pill({double? fontSize});
}
''';

const _import = "import 'package:flutter/material.dart';";

abstract class _UiRuleTest extends AnalysisRuleTest {
  String get ruleName;

  @override
  void setUp() {
    rule = uiSingleSourceRules
        .followedBy(uiSourceRules)
        .singleWhere((rule) => rule.name == ruleName);
    newPackage('flutter').addFile('lib/material.dart', _flutterLibrary);
    super.setUp();
  }

  String get _gatesPath => '$testPackageRootPath/hard-eng.gates.json';

  void writeGates(String body) => newFile(_gatesPath, body);

  Future<void> assertReported(
    String path,
    List<String> lines, {
    List<String>? from,
    List<String>? imports,
  }) async {
    final head = imports == null ? _import : imports.join('\n');
    final source = '$head\n\n${lines.join('\n')}\n';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [
      for (var i = 0; i < lines.length; i++) _lintAt(source, lines[i], from?[i] ?? ''),
    ]);
  }

  Future<void> assertClean(String path, List<String> lines, {bool withImport = true}) async {
    newFile(path, '${withImport ? '$_import\n\n' : ''}${lines.join('\n')}\n');
    await assertNoDiagnosticsInFile(path);
  }

  T _lintAt<T>(String source, String line, String from) {
    final start = source.indexOf(line);
    if (start < 0) throw StateError('Line not found: $line');
    final offset = start + line.indexOf(from);
    final lineEnd = source.indexOf('\n', offset);
    final end = lineEnd < 0 ? source.length : lineEnd;
    return lint(offset, math.max(1, end - offset), name: rule.name) as T;
  }
}

final class _BaseControlsTest extends _UiRuleTest {
  @override
  String get ruleName => 'ui_base_control_outside_library';

  static const _controls = [
    'Widget a = ElevatedButton();',
    'Widget b = TextField();',
    'Widget c = DropdownButton();',
    'Widget d = AlertDialog();',
    'Widget e = SearchBar();',
  ];

  Future<void> reportsOutsideTheDefaultLibrary() => assertReported(
    '$testPackageLibPath/features/home/home_screen.dart',
    _controls,
    from: ['ElevatedButton', 'TextField', 'DropdownButton', 'AlertDialog', 'SearchBar'],
  );

  Future<void> allowsInsideTheDefaultLibrary() =>
      assertClean('$testPackageLibPath/core/widgets/atoms/app_controls.dart', _controls);

  Future<void> reportsOnlyFlutterControls() async {
    await assertClean('$testPackageLibPath/features/own_search.dart', [
      'class Widget {',
      '  const Widget();',
      '}',
      'class SearchBar extends Widget {',
      '  const SearchBar();',
      '}',
      'Widget a = SearchBar();',
    ], withImport: false);
    await assertReported(
      '$testPackageLibPath/features/home/split.dart',
      ['Widget a = DropdownButton<\n  String\n>();'],
      from: ['DropdownButton'],
    );
    await assertReported(
      '$testPackageLibPath/features/home/shorthand.dart',
      ['TextField a = .new();'],
      from: ['.'],
    );
  }

  Future<void> reportsTheWholeButtonFamily() async {
    await assertReported(
      '$testPackageLibPath/features/home/family.dart',
      [
        'Widget a = FloatingActionButton();',
        'Widget b = FloatingActionButton.extended();',
        'Widget c = SegmentedButton<int>();',
        'Widget d = ToggleButtons();',
        'Widget e = MenuItemButton();',
        'Widget f = SubmenuButton();',
        'Widget g = PopupMenuButton<int>();',
        'Widget h = DropdownMenuFormField<int>();',
        'Widget i = CupertinoSlidingSegmentedControl<int>();',
        'Widget j = CupertinoSegmentedControl<int>();',
      ],
      from: [
        'FloatingActionButton',
        'FloatingActionButton.extended',
        'SegmentedButton',
        'ToggleButtons',
        'MenuItemButton',
        'SubmenuButton',
        'PopupMenuButton',
        'DropdownMenuFormField',
        'CupertinoSlidingSegmentedControl',
        'CupertinoSegmentedControl',
      ],
    );
    await assertClean('$testPackageLibPath/features/home/toggle.dart', ['Widget a = Icon();']);
  }

  Future<void> reportsTogglesAndSliders() => assertReported(
    '$testPackageLibPath/features/home/toggles.dart',
    [
      'Widget a = Checkbox();',
      'Widget b = CheckboxListTile();',
      'Widget c = Radio<int>();',
      'Widget d = RadioListTile<int>();',
      'Widget e = Switch.adaptive();',
      'Widget f = SwitchListTile();',
      'Widget g = Slider();',
      'Widget h = RangeSlider();',
      'Widget i = CupertinoCheckbox();',
      'Widget j = CupertinoRadio<int>();',
      'Widget k = CupertinoSwitch();',
      'Widget l = CupertinoSlider();',
    ],
    from: [
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
    ],
  );

  void writeFieldHelpers() => newFile('$testPackageLibPath/features/fields.dart', '''
$_import

typedef AppField = TextField;

Widget acceptField(TextField field) => field;
''');

  Future<void> reportsAControlInferredFromAnotherFile() async {
    writeFieldHelpers();
    await assertReported(
      '$testPackageLibPath/features/home/inferred.dart',
      ['Object a = acceptField(.new());'],
      imports: ["import '../fields.dart';"],
      from: ['.new'],
    );
  }

  Future<void> reportsAControlBuiltThroughAnAlias() async {
    writeFieldHelpers();
    await assertReported(
      '$testPackageLibPath/features/home/aliased.dart',
      ['Object a = AppField();'],
      imports: ["import '../fields.dart';"],
      from: ['AppField'],
    );
  }

  Future<void> ignoresAShorthandOnAnotherType() async {
    newFile('$testPackageLibPath/features/home/zero.dart', 'Duration a = .zero;\n');
    await assertNoDiagnosticsInFile('$testPackageLibPath/features/home/zero.dart');
  }

  Future<void> reportsControlsWithTypeArguments() => assertReported(
    '$testPackageLibPath/features/home/home_screen.dart',
    [
      'Widget a = DropdownButton<String>();',
      'Widget b = DropdownButtonFormField<int>();',
      'Widget c = DropdownMenu<Map<String, int>>();',
    ],
    from: ['DropdownButton', 'DropdownButtonFormField', 'DropdownMenu'],
  );

  Future<void> readsCharacterSetsInLibraryPaths(String set, bool inside) async {
    writeGates('{"version": 1, "shipping": {"ui_library": ["lib/${set}i/*"]}}');
    final path = '$testPackageLibPath/ui/app_controls.dart';
    if (inside) {
      await assertClean(path, _controls);
    } else {
      await assertReported(
        path,
        _controls,
        from: ['ElevatedButton', 'TextField', 'DropdownButton', 'AlertDialog', 'SearchBar'],
      );
    }
  }

  Future<void> readsLibraryPathsFromTheGatesFile() async {
    writeGates('{"version": 1, "shipping": {"ui_library": ["lib/ui/*"]}}');
    await assertClean('$testPackageLibPath/ui/app_controls.dart', _controls);
    await assertReported(
      '$testPackageLibPath/core/widgets/atoms/app_controls.dart',
      _controls,
      from: ['ElevatedButton', 'TextField', 'DropdownButton', 'AlertDialog', 'SearchBar'],
    );
  }

  Future<void> fallsBackWhenTheListIsEmptyOrInvalid(String value) async {
    writeGates('{"version": 1, "shipping": {"ui_library": $value}}');
    await assertClean('$testPackageLibPath/core/widgets/atoms/app_controls.dart', _controls);
  }

  Future<void> fallsBackWhenTheKeyIsMissing() async {
    writeGates('{"version": 1, "shipping": {"ui_paths": []}}');
    await assertClean('$testPackageLibPath/core/widgets/atoms/app_controls.dart', _controls);
  }
}

final class _RawTokenTest extends _UiRuleTest {
  @override
  String get ruleName => 'style_raw_token';

  static const _raw = ['EdgeInsets a = .symmetric(vertical: 2);', 'Widget b = Pill(fontSize: 13);'];

  Future<void> reportsRawValuesOutsideThemeFiles() async {
    await assertReported('$testPackageLibPath/features/home/home_screen.dart', _raw);
    await assertReported('$testPackageLibPath/features/home/theme_data.dart', _raw);
  }

  Future<void> allowsRawValuesInThemeFiles() async {
    await assertClean('$testPackageLibPath/palette/spacing.dart', _raw);
    await assertClean('$testPackageLibPath/core/theme/spacing.dart', _raw);
    await assertClean('$testPackageLibPath/features/home/app_tokens.dart', _raw);
  }
}

final class _RawTextStyleTest extends _UiRuleTest {
  @override
  String get ruleName => 'style_raw_text_style';

  Future<void> reportsAndAllowsDotShorthandTextStyle() async {
    const lines = ['TextStyle a = .new(fontSize: 18);'];
    await assertReported('$testPackageLibPath/features/home/home_screen.dart', lines, from: ['.']);
    await assertClean('$testPackageLibPath/colors/text_styles.dart', lines);
  }
}
