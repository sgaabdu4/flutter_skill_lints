import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_for_loop_in_children_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_for_loop_in_children.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_PreferForLoopInChildrenFixTest>(
    'PreferForLoopInChildrenFixTest',
    _PreferForLoopInChildrenFixTest.new,
    {
      'rewritesMapToList': (t) => t._rewritesMapToList(),
      'rewritesSpreadOfMap': (t) => t._rewritesSpreadOfMap(),
      'rewritesSpreadOfMapToList': (t) => t._rewritesSpreadOfMapToList(),
      'rewritesListGenerate': (t) => t._rewritesListGenerate(),
      'rewritesTypedListGenerate': (t) => t._rewritesTypedListGenerate(),
      'rewritesAppendOnceFold': (t) => t._rewritesAppendOnceFold(),
      'keepsMapWithStatementBody': (t) => t._keepsMapWithStatementBody(),
      'keepsGenerateWithStatementBody': (t) => t._keepsGenerateWithStatementBody(),
      'keepsCascadeFold': (t) => t._keepsCascadeFold(),
      'keepsBlockReturnCascadeFold': (t) => t._keepsBlockReturnCascadeFold(),
    },
  );
}

final class _PreferForLoopInChildrenFixTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = PreferForLoopInChildren();
    super.setUp();
  }

  static String _source(String body) =>
      '''
import 'package:flutter/widgets.dart';

$body
''';

  Future<void> _expectRewrite(String body, String expected) => expectFix(
    _source(body),
    (context) => PreferForLoopInChildrenFix(context: context),
    expected: _source(expected),
  );

  Future<void> _expectUnchanged(String body) =>
      expectNoFix(_source(body), (context) => PreferForLoopInChildrenFix(context: context));

  Future<void> _rewritesMapToList() => _expectRewrite(
    "List<Widget> build(List<int> v) => v.map((n) => Text('\$n')).toList();",
    "List<Widget> build(List<int> v) => [for (final n in v) Text('\$n')];",
  );

  Future<void> _rewritesSpreadOfMap() => _expectRewrite(
    "List<Widget> build(List<int> v) => <Widget>[...v.map((n) => Text('\$n'))];",
    "List<Widget> build(List<int> v) => <Widget>[for (final n in v) Text('\$n')];",
  );

  Future<void> _rewritesSpreadOfMapToList() => _expectRewrite(
    "List<Widget> build(List<int> v) => <Widget>[...v.map((n) => Text('\$n')).toList()];",
    "List<Widget> build(List<int> v) => <Widget>[for (final n in v) Text('\$n')];",
  );

  Future<void> _rewritesListGenerate() => _expectRewrite(
    "List<Widget> build() => List.generate(3, (i) => Text('\$i'));",
    "List<Widget> build() => [for (var i = 0; i < 3; i++) Text('\$i')];",
  );

  Future<void> _rewritesTypedListGenerate() => _expectRewrite(
    "List<Widget> build(int count) => List<Widget>.generate(count, (index) => Text('\$index'));",
    "List<Widget> build(int count) => [for (var index = 0; index < count; index++) Text('\$index')];",
  );

  Future<void> _rewritesAppendOnceFold() => _expectRewrite('''
List<Widget> build(List<int> v) => v.fold<List<Widget>>(<Widget>[], (items, n) {
  items.add(Text('\$n'));
  return items;
});''', "List<Widget> build(List<int> v) => [for (final n in v) Text('\$n')];");

  Future<void> _keepsMapWithStatementBody() => _expectUnchanged('''
List<Widget> build(List<int> v) => v.map((n) {
  final label = '\$n';
  return Text(label);
}).toList();''');

  Future<void> _keepsGenerateWithStatementBody() => _expectUnchanged('''
List<Widget> build() => List.generate(3, (i) {
  final label = '\$i';
  return Text(label);
});''');

  Future<void> _keepsCascadeFold() => _expectUnchanged(
    "List<Widget> build(List<int> v) => v.fold<List<Widget>>(<Widget>[], (items, n) => items..add(Text('\$n')));",
  );

  Future<void> _keepsBlockReturnCascadeFold() => _expectUnchanged('''
List<Widget> build(List<int> v) => v.fold<List<Widget>>(<Widget>[], (items, n) {
  return items..add(Text('\$n'));
});''');
}
