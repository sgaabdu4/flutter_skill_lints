import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_incorrect_image_opacity_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_incorrect_image_opacity.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_AvoidIncorrectImageOpacityTest>(
    'AvoidIncorrectImageOpacityTest',
    _AvoidIncorrectImageOpacityTest.new,
    {
      'reportsOpacityAroundImage': (t) => t._reportsOpacityAroundImage(),
      'ignoresOpacityAroundText': (t) => t._ignoresOpacityAroundText(),
      'ignoresOpacityWithoutChild': (t) => t._ignoresOpacityWithoutChild(),
      'movesOpacityIntoImage': (t) => t._movesOpacityIntoImage(),
      'addsOpacityToImageWithoutArguments': (t) => t._addsOpacityToImageWithoutArguments(),
      'keepsImageThatHasOpacity': (t) => t._keepsImageThatHasOpacity(),
      'ignoresChildThatIsNotAWidgetCall': (t) => t._ignoresChildThatIsNotAWidgetCall(),
    },
  );
}

final class _AvoidIncorrectImageOpacityTest extends FixRuleTest {
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

  Future<void> _reportsOpacityAroundImage() =>
      assertDiagnostics(_wrapped, [lint(_wrapped.indexOf('Opacity('), 'Opacity'.length)]);

  Future<void> _ignoresOpacityAroundText() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Opacity(opacity: 0.5, child: Text('a'));
''');

  Future<void> _ignoresOpacityWithoutChild() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Opacity(opacity: 0.5);
''');

  Future<void> _movesOpacityIntoImage() => expectFix(
    _wrapped,
    (context) => AvoidIncorrectImageOpacityFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => Image.network('a', opacity: AlwaysStoppedAnimation(0.5));
''',
  );

  Future<void> _addsOpacityToImageWithoutArguments() => expectFix(
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

  Future<void> _keepsImageThatHasOpacity() => expectNoFix('''
import 'package:flutter/widgets.dart';

Widget build() => Opacity(
  opacity: 0.5,
  child: Image(opacity: AlwaysStoppedAnimation(0.9)),
);
''', (context) => AvoidIncorrectImageOpacityFix(context: context));

  Future<void> _ignoresChildThatIsNotAWidgetCall() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build(Widget other) => Opacity(opacity: 0.5, child: other);
''');
}
