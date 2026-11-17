import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_small_font_size.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidSmallFontSizeTest>(
    'AvoidSmallFontSizeTest',
    _AvoidSmallFontSizeTest.new,
    {
      'reportsIntegerLiteralUnderFourteen': (t) => t._reportsIntegerLiteralUnderFourteen(),
      'reportsDecimalLiteralUnderFourteen': (t) => t._reportsDecimalLiteralUnderFourteen(),
      'reportsConstTextStyle': (t) => t._reportsConstTextStyle(),
      'reportsCopyWith': (t) => t._reportsCopyWith(),
      'reportsDotShorthandConstructor': (t) => t._reportsDotShorthandConstructor(),
      'allowsFourteenAndLarger': (t) => t._allowsFourteenAndLarger(),
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
}
''';

final class _AvoidSmallFontSizeTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile('lib/painting.dart', _flutterLibrary);
    rule = AvoidSmallFontSize();
    super.setUp();
  }

  Future<void> _reportsIntegerLiteralUnderFourteen() async {
    const source = r'''
import 'package:flutter/painting.dart';

final style = TextStyle(fontSize: 12);
''';

    await assertDiagnostics(source, [lint(source.indexOf('12'), '12'.length)]);
  }

  Future<void> _reportsDecimalLiteralUnderFourteen() async {
    const source = r'''
import 'package:flutter/painting.dart';

final small = TextStyle(fontSize: 13.9);
final tiny = TextStyle(fontSize: 0.5);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('13.9'), '13.9'.length),
      lint(source.indexOf('0.5'), '0.5'.length),
    ]);
  }

  Future<void> _reportsConstTextStyle() async {
    const source = r'''
import 'package:flutter/painting.dart';

const style = TextStyle(color: Color(0xFF000000), fontSize: 11);
''';

    await assertDiagnostics(source, [lint(source.indexOf('11'), '11'.length)]);
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

TextStyle build() => .new(fontSize: 12);
''';

    await assertDiagnostics(source, [lint(source.indexOf('12'), '12'.length)]);
  }

  Future<void> _allowsFourteenAndLarger() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';

final a = TextStyle(fontSize: 14);
final b = TextStyle(fontSize: 14.0);
final c = TextStyle(fontSize: 16.5);
TextStyle grow(TextStyle base) => base.copyWith(fontSize: 18);
''');
  }

  Future<void> _allowsNonLiteralSizes() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';

const smallSize = 12.0;

TextStyle fromConstant() => const TextStyle(fontSize: smallSize);
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

final style = TextStyle(fontSize: 12);
TextStyle shrink(TextStyle base) => base.copyWith(fontSize: 10);
''');
  }

  Future<void> _skipsTestFiles() async {
    final path = '$testPackageRootPath/test/widget_test.dart';
    newFile(path, r'''
import 'package:flutter/painting.dart';

final style = TextStyle(fontSize: 12);
''');

    await assertNoDiagnosticsInFile(path);
  }

  Future<void> _skipsGeneratedFiles() async {
    final path = '$testPackageLibPath/styles.g.dart';
    newFile(path, r'''
// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/painting.dart';

final style = TextStyle(fontSize: 12);
''');

    await assertNoDiagnosticsInFile(path);
  }
}
