import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_container_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_container.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_PreferContainerTest>('PreferContainerTest', _PreferContainerTest.new, {
    'reportsThreeNestedWidgets': (t) => t._reportsThreeNestedWidgets(),
    'ignoresTwoNestedWidgets': (t) => t._ignoresTwoNestedWidgets(),
    'ignoresRepeatedContainerParameter': (t) => t._ignoresRepeatedContainerParameter(),
    'reportsOnlyOutermostWidget': (t) => t._reportsOnlyOutermostWidget(),
    'ignoresNonFlutterWidgetsWithSameNames': (t) => t._ignoresNonFlutterWidgetsWithSameNames(),
    'mergesChainIntoContainer': (t) => t._mergesChainIntoContainer(),
    'centerBecomesCenterAlignment': (t) => t._centerBecomesCenterAlignment(),
    'keepsFirstKey': (t) => t._keepsFirstKey(),
    'mapsSizedBoxDimensions': (t) => t._mapsSizedBoxDimensions(),
  });
}

final class _PreferContainerTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = PreferContainer();
    super.setUp();
  }

  static const _chain = r'''
import 'package:flutter/widgets.dart';

Widget build() => Padding(
  padding: EdgeInsets.all(8),
  child: ColoredBox(
    color: Color(1),
    child: Align(child: Text('a')),
  ),
);
''';

  Future<void> _reportsThreeNestedWidgets() async {
    await assertDiagnostics(_chain, [lint(_chain.indexOf('Padding('), 'Padding'.length)]);
  }

  Future<void> _ignoresTwoNestedWidgets() => assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => Padding(
  padding: EdgeInsets.all(8),
  child: ColoredBox(color: Color(1), child: Text('a')),
);
''');

  Future<void> _ignoresRepeatedContainerParameter() => assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => Padding(
  padding: EdgeInsets.all(8),
  child: Padding(
    padding: EdgeInsets.all(4),
    child: ColoredBox(color: Color(1), child: Text('a')),
  ),
);
''');

  Future<void> _reportsOnlyOutermostWidget() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => Align(
  child: Padding(
    padding: EdgeInsets.all(8),
    child: ColoredBox(
      color: Color(1),
      child: Opacity(opacity: 0.5, child: Text('a')),
    ),
  ),
);
''';
    await assertDiagnostics(source, [lint(source.indexOf('Align('), 'Align'.length)]);
  }

  Future<void> _ignoresNonFlutterWidgetsWithSameNames() => assertNoDiagnostics(r'''
class Padding {
  const Padding({Object? child});
}

class Align {
  const Align({Object? child});
}

class ColoredBox {
  const ColoredBox({Object? child});
}

Object build() => Padding(child: Align(child: ColoredBox()));
''');

  Future<void> _mergesChainIntoContainer() => expectFix(
    _chain,
    (context) => PreferContainerFix(context: context),
    expected: r'''
import 'package:flutter/widgets.dart';

Widget build() => Container(padding: EdgeInsets.all(8), color: Color(1), child: Text('a'), );
''',
  );

  Future<void> _centerBecomesCenterAlignment() => expectFix(
    r'''
import 'package:flutter/widgets.dart';

Widget build() => Center(
  child: Padding(
    padding: EdgeInsets.all(8),
    child: ColoredBox(color: Color(1), child: Text('a')),
  ),
);
''',
    (context) => PreferContainerFix(context: context),
    expected: r'''
import 'package:flutter/widgets.dart';

Widget build() => Container(alignment: Alignment.center, padding: EdgeInsets.all(8), color: Color(1), child: Text('a'), );
''',
  );

  Future<void> _keepsFirstKey() => expectFix(
    r'''
import 'package:flutter/widgets.dart';

Widget build() => Padding(
  key: Key('outer'),
  padding: EdgeInsets.all(8),
  child: ColoredBox(
    key: Key('inner'),
    color: Color(1),
    child: Align(child: Text('a')),
  ),
);
''',
    (context) => PreferContainerFix(context: context),
    expected: r'''
import 'package:flutter/widgets.dart';

Widget build() => Container(key: Key('outer'), padding: EdgeInsets.all(8), color: Color(1), child: Text('a'), );
''',
  );

  Future<void> _mapsSizedBoxDimensions() => expectFix(
    r'''
import 'package:flutter/widgets.dart';

Widget build() => SizedBox(
  width: 10,
  height: 20,
  child: Padding(
    padding: EdgeInsets.all(8),
    child: ColoredBox(color: Color(1), child: Text('a')),
  ),
);
''',
    (context) => PreferContainerFix(context: context),
    expected: r'''
import 'package:flutter/widgets.dart';

Widget build() => Container(width: 10, height: 20, padding: EdgeInsets.all(8), color: Color(1), child: Text('a'), );
''',
  );
}
