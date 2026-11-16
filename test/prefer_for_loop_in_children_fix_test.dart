import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_for_loop_in_children_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_for_loop_in_children.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<PreferForLoopInChildrenFixTest>(
    'PreferForLoopInChildrenFixTest',
    PreferForLoopInChildrenFixTest.new,
    {
      'rewritesMapToList': (t) => t.rewritesMapToList(),
      'rewritesSpreadOfMap': (t) => t.rewritesSpreadOfMap(),
      'rewritesSpreadOfMapToList': (t) => t.rewritesSpreadOfMapToList(),
      'rewritesListGenerate': (t) => t.rewritesListGenerate(),
      'rewritesTypedListGenerate': (t) => t.rewritesTypedListGenerate(),
      'rewritesAppendOnceFold': (t) => t.rewritesAppendOnceFold(),
      'keepsMapWithStatementBody': (t) => t.keepsMapWithStatementBody(),
      'keepsGenerateWithStatementBody': (t) => t.keepsGenerateWithStatementBody(),
      'keepsCascadeFold': (t) => t.keepsCascadeFold(),
      'keepsBlockReturnCascadeFold': (t) => t.keepsBlockReturnCascadeFold(),
    },
  );
}

final class PreferForLoopInChildrenFixTest extends FixRuleTest {
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

  Future<void> rewritesMapToList() => _expectRewrite(
    "List<Widget> build(List<int> v) => v.map((n) => Text('\$n')).toList();",
    "List<Widget> build(List<int> v) => [for (final n in v) Text('\$n')];",
  );

  Future<void> rewritesSpreadOfMap() => _expectRewrite(
    "List<Widget> build(List<int> v) => <Widget>[...v.map((n) => Text('\$n'))];",
    "List<Widget> build(List<int> v) => <Widget>[for (final n in v) Text('\$n')];",
  );

  Future<void> rewritesSpreadOfMapToList() => _expectRewrite(
    "List<Widget> build(List<int> v) => <Widget>[...v.map((n) => Text('\$n')).toList()];",
    "List<Widget> build(List<int> v) => <Widget>[for (final n in v) Text('\$n')];",
  );

  Future<void> rewritesListGenerate() => _expectRewrite(
    "List<Widget> build() => List.generate(3, (i) => Text('\$i'));",
    "List<Widget> build() => [for (var i = 0; i < 3; i++) Text('\$i')];",
  );

  Future<void> rewritesTypedListGenerate() => _expectRewrite(
    "List<Widget> build(int count) => List<Widget>.generate(count, (index) => Text('\$index'));",
    "List<Widget> build(int count) => [for (var index = 0; index < count; index++) Text('\$index')];",
  );

  Future<void> rewritesAppendOnceFold() => _expectRewrite('''
List<Widget> build(List<int> v) => v.fold<List<Widget>>(<Widget>[], (items, n) {
  items.add(Text('\$n'));
  return items;
});''', "List<Widget> build(List<int> v) => [for (final n in v) Text('\$n')];");

  Future<void> keepsMapWithStatementBody() => _expectUnchanged('''
List<Widget> build(List<int> v) => v.map((n) {
  final label = '\$n';
  return Text(label);
}).toList();''');

  Future<void> keepsGenerateWithStatementBody() => _expectUnchanged('''
List<Widget> build() => List.generate(3, (i) {
  final label = '\$i';
  return Text(label);
});''');

  Future<void> keepsCascadeFold() => _expectUnchanged(
    "List<Widget> build(List<int> v) => v.fold<List<Widget>>(<Widget>[], (items, n) => items..add(Text('\$n')));",
  );

  Future<void> keepsBlockReturnCascadeFold() => _expectUnchanged('''
List<Widget> build(List<int> v) => v.fold<List<Widget>>(<Widget>[], (items, n) {
  return items..add(Text('\$n'));
});''');
}
