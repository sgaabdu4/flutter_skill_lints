import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_incorrect_image_opacity_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_incorrect_image_opacity.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<AvoidIncorrectImageOpacityTest>(
    'AvoidIncorrectImageOpacityTest',
    AvoidIncorrectImageOpacityTest.new,
    {
      'reportsOpacityAroundImage': (t) => t.reportsOpacityAroundImage(),
      'ignoresOpacityAroundText': (t) => t.ignoresOpacityAroundText(),
      'ignoresOpacityWithoutChild': (t) => t.ignoresOpacityWithoutChild(),
      'movesOpacityIntoImage': (t) => t.movesOpacityIntoImage(),
      'addsOpacityToImageWithoutArguments': (t) => t.addsOpacityToImageWithoutArguments(),
      'keepsImageThatHasOpacity': (t) => t.keepsImageThatHasOpacity(),
      'ignoresChildThatIsNotAWidgetCall': (t) => t.ignoresChildThatIsNotAWidgetCall(),
    },
  );
}

final class AvoidIncorrectImageOpacityTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = AvoidIncorrectImageOpacity();
    super.setUp();
  }

  static const _wrapped = '''
import 'package:flutter/widgets.dart';

Widget build() => Opacity(opacity: 0.5, child: Image.network('a'));
''';

  Future<void> reportsOpacityAroundImage() =>
      assertDiagnostics(_wrapped, [lint(_wrapped.indexOf('Opacity('), 'Opacity'.length)]);

  Future<void> ignoresOpacityAroundText() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Opacity(opacity: 0.5, child: Text('a'));
''');

  Future<void> ignoresOpacityWithoutChild() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Opacity(opacity: 0.5);
''');

  Future<void> movesOpacityIntoImage() => expectFix(
    _wrapped,
    (context) => AvoidIncorrectImageOpacityFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => Image.network('a', opacity: AlwaysStoppedAnimation(0.5));
''',
  );

  Future<void> addsOpacityToImageWithoutArguments() => expectFix(
    '''
import 'package:flutter/widgets.dart';

Widget build() => Opacity(opacity: 0.25, child: Image());
''',
    (context) => AvoidIncorrectImageOpacityFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => Image(opacity: AlwaysStoppedAnimation(0.25));
''',
  );

  Future<void> keepsImageThatHasOpacity() => expectNoFix('''
import 'package:flutter/widgets.dart';

Widget build() => Opacity(
  opacity: 0.5,
  child: Image(opacity: AlwaysStoppedAnimation(0.9)),
);
''', (context) => AvoidIncorrectImageOpacityFix(context: context));

  Future<void> ignoresChildThatIsNotAWidgetCall() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build(Widget other) => Opacity(opacity: 0.5, child: other);
''');
}
