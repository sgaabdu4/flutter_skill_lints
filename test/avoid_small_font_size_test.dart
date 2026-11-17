import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_small_font_size.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidSmallFontSizeTest>(
    'AvoidSmallFontSizeTest',
    _AvoidSmallFontSizeTest.new,
    {
      'reportsIntegerLiteralUnderEleven': (t) => t._reportsIntegerLiteralUnderEleven(),
      'reportsDecimalLiteralUnderEleven': (t) => t._reportsDecimalLiteralUnderEleven(),
      'reportsConstTextStyle': (t) => t._reportsConstTextStyle(),
      'reportsCopyWith': (t) => t._reportsCopyWith(),
      'reportsDotShorthandConstructor': (t) => t._reportsDotShorthandConstructor(),
      'reportsConstantSizes': (t) => t._reportsConstantSizes(),
      'reportsParenthesisedAndComputedSizes': (t) => t._reportsParenthesisedAndComputedSizes(),
      'reportsShrinkingFontSizeFactor': (t) => t._reportsShrinkingFontSizeFactor(),
      'reportsShrinkingTextScaler': (t) => t._reportsShrinkingTextScaler(),
      'reportsNoScaling': (t) => t._reportsNoScaling(),
      'allowsZeroAndGrowingScale': (t) => t._allowsZeroAndGrowingScale(),
      'reportsShrinkingFontSizeDelta': (t) => t._reportsShrinkingFontSizeDelta(),
      'allowsApplyOnNonPositiveBase': (t) => t._allowsApplyOnNonPositiveBase(),
      'allowsNoScalingComparisons': (t) => t._allowsNoScalingComparisons(),
      'allowsDeltaThatKeepsTheFloor': (t) => t._allowsDeltaThatKeepsTheFloor(),
      'allowsElevenAndLarger': (t) => t._allowsElevenAndLarger(),
      'allowsScalerComparisonAndUnknownBase': (t) => t._allowsScalerComparisonAndUnknownBase(),
      'allowsNonLiteralSizes': (t) => t._allowsNonLiteralSizes(),
      'allowsOtherNumbersInTextStyle': (t) => t._allowsOtherNumbersInTextStyle(),
      'allowsLookalikeTextStyle': (t) => t._allowsLookalikeTextStyle(),
      'skipsTestFiles': (t) => t._skipsTestFiles(),
      'skipsGeneratedFiles': (t) => t._skipsGeneratedFiles(),
    },
  );
}

const _flutterLibrary = r'''
class Color {
  const Color(this.value);
  final int value;
}

class TextStyle {
  const TextStyle({this.fontSize, this.height, this.color});
  final double? fontSize;
  final double? height;
  final Color? color;

  TextStyle copyWith({double? fontSize, double? height}) => this;
  TextStyle apply({double fontSizeFactor = 1.0, double fontSizeDelta = 0.0}) => this;
}

class TextScaler {
  const TextScaler.linear(double scale);
  static const TextScaler noScaling = TextScaler.linear(1);
}
''';

final class _AvoidSmallFontSizeTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile('lib/painting.dart', _flutterLibrary);
    rule = AvoidSmallFontSize();
    super.setUp();
  }

  Future<void> _reportsIntegerLiteralUnderEleven() async {
    const source = r'''
import 'package:flutter/painting.dart';

final style = TextStyle(fontSize: 10);
''';

    await assertDiagnostics(source, [lint(source.indexOf('10'), '10'.length)]);
  }

  Future<void> _reportsDecimalLiteralUnderEleven() async {
    const source = r'''
import 'package:flutter/painting.dart';

final small = TextStyle(fontSize: 10.9);
final tiny = TextStyle(fontSize: 0.5);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('10.9'), '10.9'.length),
      lint(source.indexOf('0.5'), '0.5'.length),
    ]);
  }

  Future<void> _reportsConstTextStyle() async {
    const source = r'''
import 'package:flutter/painting.dart';

const style = TextStyle(color: Color(0xFF000000), fontSize: 10.5);
''';

    await assertDiagnostics(source, [lint(source.indexOf('10.5'), '10.5'.length)]);
  }

  Future<void> _reportsCopyWith() async {
    const source = r'''
import 'package:flutter/painting.dart';

TextStyle shrink(TextStyle base) => base.copyWith(fontSize: 10);
''';

    await assertDiagnostics(source, [lint(source.indexOf('10'), '10'.length)]);
  }

  Future<void> _reportsDotShorthandConstructor() async {
    const source = r'''
import 'package:flutter/painting.dart';

TextStyle build() => .new(fontSize: 10);
''';

    await assertDiagnostics(source, [lint(source.indexOf('10'), '10'.length)]);
  }

  Future<void> _reportsConstantSizes() async {
    const source = r"""
import 'package:flutter/painting.dart';

const kTiny = 10.0;

abstract final class AppSizes {
  static const double caption = 10.0;
}

TextStyle a() => const TextStyle(fontSize: kTiny);
TextStyle b() => const TextStyle(fontSize: AppSizes.caption);
TextStyle c() {
  const local = 9.0;
  return TextStyle(fontSize: local);
}
""";
    await assertDiagnostics(source, [
      lint(source.indexOf('kTiny);'), 'kTiny'.length),
      lint(source.indexOf('AppSizes.caption);'), 'AppSizes.caption'.length),
      lint(source.indexOf('local);'), 'local'.length),
    ]);
  }

  Future<void> _reportsParenthesisedAndComputedSizes() async {
    const source = r"""
import 'package:flutter/painting.dart';

TextStyle a() => const TextStyle(fontSize: (10));
TextStyle b() => const TextStyle(fontSize: 5 + 5);
""";
    await assertDiagnostics(source, [
      lint(source.indexOf('(10)'), '(10)'.length),
      lint(source.indexOf('5 + 5'), '5 + 5'.length),
    ]);
  }

  Future<void> _reportsShrinkingFontSizeFactor() async {
    const source = r"""
import 'package:flutter/painting.dart';

TextStyle a() => const TextStyle(fontSize: 14).apply(fontSizeFactor: 0.5);
""";
    await assertDiagnostics(source, [lint(source.indexOf('0.5'), '0.5'.length)]);
  }

  Future<void> _reportsShrinkingTextScaler() async {
    const source = r"""
import 'package:flutter/painting.dart';

const a = TextScaler.linear(0.5);
const TextScaler b = .linear(0.8);
""";
    await assertDiagnostics(source, [
      lint(source.indexOf('0.5'), '0.5'.length),
      lint(source.indexOf('0.8'), '0.8'.length),
    ]);
  }

  Future<void> _reportsNoScaling() async {
    const source = r"""
import 'package:flutter/painting.dart';

const a = TextScaler.noScaling;
const TextScaler b = .noScaling;
""";
    await assertDiagnostics(source, [
      lint(source.indexOf('TextScaler.noScaling'), 'TextScaler.noScaling'.length),
      lint(source.indexOf('.noScaling;', source.indexOf('b =')), '.noScaling'.length),
    ]);
  }

  Future<void> _allowsZeroAndGrowingScale() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/painting.dart';

const zero = TextStyle(fontSize: 0);
TextStyle a(TextStyle base) => base.apply(fontSizeFactor: 1.2);
TextStyle b(TextStyle base) => base.apply(fontSizeDelta: -2);
const c = TextScaler.linear(1.5);
""");
  }

  Future<void> _allowsScalerComparisonAndUnknownBase() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/painting.dart';

bool plain(TextScaler scaler) => scaler == TextScaler.noScaling;
bool other(TextScaler scaler) => scaler != TextScaler.noScaling;
TextStyle unknown(TextStyle base) => base.apply(fontSizeFactor: 0.5);
TextStyle fine() => const TextStyle(fontSize: 14).apply(fontSizeFactor: 0.9);
""");
  }

  Future<void> _reportsShrinkingFontSizeDelta() async {
    const source = r"""
import 'package:flutter/painting.dart';

TextStyle a() => const TextStyle(fontSize: 14).apply(fontSizeDelta: -5);
TextStyle b() => const TextStyle(fontSize: 14).apply(fontSizeFactor: 0.9, fontSizeDelta: -3);
""";
    await assertDiagnostics(source, [
      lint(source.indexOf('-5'), '-5'.length),
      lint(source.indexOf('-3'), '-3'.length),
    ]);
  }

  Future<void> _allowsDeltaThatKeepsTheFloor() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/painting.dart';

TextStyle a() => const TextStyle(fontSize: 14).apply(fontSizeDelta: -3);
TextStyle b() => const TextStyle(fontSize: 14).apply(fontSizeFactor: 0.9, fontSizeDelta: -1);
""");
  }

  Future<void> _allowsApplyOnNonPositiveBase() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/painting.dart';

TextStyle a() => const TextStyle(fontSize: 0).apply(fontSizeFactor: 0.5);
TextStyle b() => const TextStyle(fontSize: -1).apply(fontSizeDelta: -2);
""");
  }

  Future<void> _allowsNoScalingComparisons() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/painting.dart';

bool a(TextScaler s) => identical(s, TextScaler.noScaling);
bool b(TextScaler s) => (TextScaler.noScaling) == s;
bool c(TextScaler s) => (s == (TextScaler.noScaling));
int d(TextScaler s) => switch (s) {
  TextScaler.noScaling => 1,
  _ => 2,
};
int e(TextScaler s) => switch (s) {
  == TextScaler.noScaling => 1,
  _ => 2,
};
""");
  }

  Future<void> _allowsElevenAndLarger() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';

final floor = TextStyle(fontSize: 11);
final twelve = TextStyle(fontSize: 12);

final a = TextStyle(fontSize: 14);
final b = TextStyle(fontSize: 14.0);
final c = TextStyle(fontSize: 16.5);
TextStyle grow(TextStyle base) => base.copyWith(fontSize: 18);
''');
  }

  Future<void> _allowsNonLiteralSizes() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';

TextStyle fromVariable(double size) => TextStyle(fontSize: size);
TextStyle fromNull() => const TextStyle(fontSize: null);
''');
  }

  Future<void> _allowsOtherNumbersInTextStyle() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';

TextStyle build() => const TextStyle(height: 1.2, fontSize: 15);
''');
  }

  Future<void> _allowsLookalikeTextStyle() async {
    await assertNoDiagnostics(r'''
class TextStyle {
  const TextStyle({this.fontSize});
  final double? fontSize;
  TextStyle copyWith({double? fontSize}) => this;
}

final style = TextStyle(fontSize: 10);
TextStyle shrink(TextStyle base) => base.copyWith(fontSize: 10);
''');
  }

  Future<void> _skipsTestFiles() async {
    final path = '$testPackageRootPath/test/widget_test.dart';
    newFile(path, r'''
import 'package:flutter/painting.dart';

final style = TextStyle(fontSize: 10);
''');

    await assertNoDiagnosticsInFile(path);
  }

  Future<void> _skipsGeneratedFiles() async {
    final path = '$testPackageLibPath/styles.g.dart';
    newFile(path, r'''
// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/painting.dart';

final style = TextStyle(fontSize: 10);
''');

    await assertNoDiagnosticsInFile(path);
  }
}
