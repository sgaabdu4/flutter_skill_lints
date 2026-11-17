import 'dart:math' as math;

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/ui_source_rules.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_StyleRawTokenShorthandTest>(
    'StyleRawTokenShorthandTest',
    _StyleRawTokenShorthandTest.new,
    {
      'reportsDotShorthandSpacing': (t) => t._reportsDotShorthandSpacing(),
      'reportsDotShorthandRadius': (t) => t._reportsDotShorthandRadius(),
      'reportsLiteralFontSizeOption': (t) => t._reportsLiteralFontSizeOption(),
      'reportsLiteralFontSizeOptionOnDotShorthand': (t) =>
          t._reportsLiteralFontSizeOptionOnDotShorthand(),
      'allowsTokenDotShorthandSpacing': (t) => t._allowsTokenDotShorthandSpacing(),
      'allowsTokenFontSizeOption': (t) => t._allowsTokenFontSizeOption(),
      'leavesTextStyleToItsOwnRule': (t) => t._leavesTextStyleToItsOwnRule(),
      'leavesOtherSizeOptionsToSpacingRules': (t) => t._leavesOtherSizeOptionsToSpacingRules(),
    },
  );

  analysisRuleSuite<_StyleRawTextStyleShorthandTest>(
    'StyleRawTextStyleShorthandTest',
    _StyleRawTextStyleShorthandTest.new,
    {
      'reportsDotShorthandNew': (t) => t._reportsDotShorthandNew(),
      'reportsConstDotShorthandNew': (t) => t._reportsConstDotShorthandNew(),
      'allowsDotShorthandOfOtherTypes': (t) => t._allowsDotShorthandOfOtherTypes(),
      'allowsDotShorthandTextStyleInThemeFile': (t) => t._allowsDotShorthandTextStyleInThemeFile(),
    },
  );
}

const _flutterLibrary = r'''
class Widget {
  const Widget();
}

class TextStyle {
  const TextStyle({double? fontSize});
  const TextStyle.bold({double? fontSize});
}

class EdgeInsets {
  const EdgeInsets.all(double value);
  const EdgeInsets.only({double left = 0, double top = 0, double right = 0, double bottom = 0});
  const EdgeInsets.symmetric({double vertical = 0, double horizontal = 0});
  const EdgeInsets.fromLTRB(double left, double top, double right, double bottom);
  static const EdgeInsets zero = EdgeInsets.all(0);
}

class Radius {
  const Radius.circular(double radius);
}

class BorderRadius {
  const BorderRadius.circular(double radius);
}

class SizedBox extends Widget {
  const SizedBox({double? width, double? height});
}

class Pill extends Widget {
  const Pill({double? fontSize, double? gap, double? iconSize});
  const Pill.small({double? fontSize});
}
''';

const _import = "import 'package:flutter/material.dart';";

abstract class _ShorthandRuleTest extends AnalysisRuleTest {
  String get ruleName;

  @override
  void setUp() {
    rule = uiSourceRules.singleWhere((rule) => rule.name == ruleName);
    newPackage('flutter').addFile('lib/material.dart', _flutterLibrary);
    super.setUp();
  }

  Future<void> assertReported(List<String> declarations, {String? path, String from = ''}) async {
    final source = '$_import\n\n${declarations.join('\n')}\n';
    if (path == null) {
      await assertDiagnostics(source, [
        for (final declaration in declarations) _lineAt(source, declaration, from),
      ]);
    } else {
      newFile(path, source);
      await assertDiagnosticsInFile(path, [
        for (final declaration in declarations) _lineAt(source, declaration, from),
      ]);
    }
  }

  Future<void> assertClean(List<String> declarations, {String? path}) async {
    final source = '$_import\n\n${declarations.join('\n')}\n';
    if (path == null) {
      await assertNoDiagnostics(source);
    } else {
      newFile(path, source);
      await assertNoDiagnosticsInFile(path);
    }
  }

  T _lineAt<T>(String source, String declaration, String from) {
    final start = source.indexOf(declaration);
    if (start < 0) throw StateError('Declaration not found: $declaration');
    final offset = start + declaration.indexOf(from);
    final lineEnd = source.indexOf('\n', offset);
    final end = lineEnd < 0 ? source.length : lineEnd;
    return lint(offset, math.max(1, end - offset), name: rule.name) as T;
  }
}

final class _StyleRawTokenShorthandTest extends _ShorthandRuleTest {
  @override
  String get ruleName => 'style_raw_token';

  Future<void> _reportsDotShorthandSpacing() => assertReported([
    'EdgeInsets a = .symmetric(vertical: 2);',
    'EdgeInsets b = .only(left: 4);',
    'EdgeInsets c = .all(8);',
    'EdgeInsets d = .fromLTRB(1, 2, 3, 4);',
    'const EdgeInsets e = .all(8);',
  ]);

  Future<void> _reportsDotShorthandRadius() =>
      assertReported(['BorderRadius a = .circular(8);', 'Radius b = .circular(6);']);

  Future<void> _reportsLiteralFontSizeOption() => assertReported([
    'Widget a = Pill(fontSize: 13);',
    'Widget b = const Pill.small(fontSize: 12.5);',
  ]);

  Future<void> _reportsLiteralFontSizeOptionOnDotShorthand() =>
      assertReported(['Pill a = .new(fontSize: 13);', 'Pill b = .small(fontSize: 11);']);

  Future<void> _allowsTokenDotShorthandSpacing() => assertClean([
    'abstract final class Spacing {',
    '  static const double s8 = 8;',
    '}',
    'EdgeInsets a = .symmetric(vertical: Spacing.s8);',
    'EdgeInsets b = .all(0);',
    'EdgeInsets c = .zero;',
    'BorderRadius d = .circular(Spacing.s8);',
  ]);

  Future<void> _allowsTokenFontSizeOption() => assertClean([
    'abstract final class Fonts {',
    '  static const double small = 14;',
    '}',
    'Widget a = Pill(fontSize: Fonts.small);',
    'Pill b = .new(fontSize: Fonts.small);',
    'Widget c = Pill(fontSize: 0);',
  ]);

  Future<void> _leavesTextStyleToItsOwnRule() =>
      assertClean(['TextStyle a = TextStyle(fontSize: 13);', 'TextStyle b = .new(fontSize: 13);']);

  Future<void> _leavesOtherSizeOptionsToSpacingRules() =>
      assertClean(['Widget a = Pill(gap: 8);', 'Widget b = SizedBox(width: 0);']);
}

final class _StyleRawTextStyleShorthandTest extends _ShorthandRuleTest {
  @override
  String get ruleName => 'style_raw_text_style';

  Future<void> _reportsDotShorthandNew() => assertReported([
    'TextStyle a = .new(fontSize: 18);',
    'TextStyle b = .bold(fontSize: 18);',
  ], from: '.');

  Future<void> _reportsConstDotShorthandNew() =>
      assertReported(['const TextStyle a = .new(fontSize: 18);'], from: '.');

  Future<void> _allowsDotShorthandOfOtherTypes() =>
      assertClean(['Pill a = .new(fontSize: 18);', 'EdgeInsets b = .zero;']);

  Future<void> _allowsDotShorthandTextStyleInThemeFile() => assertClean([
    'TextStyle a = .new(fontSize: 18);',
  ], path: '$testPackageLibPath/core/theme/app_theme.dart');
}
