import 'package:flutter_skill_lints/src/additional_lints/assists/convert_iterable_map_to_collection_for.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_for_loop_in_children.dart';

import 'package:test/test.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<ConvertIterableMapToCollectionForTest>(
    'ConvertIterableMapToCollectionForTest',
    ConvertIterableMapToCollectionForTest.new,
    {
      'convertsMapToList': (t) => t.convertsMapToList(),
      'convertsMapToSet': (t) => t.convertsMapToSet(),
      'convertsBareMapToList': (t) => t.convertsBareMapToList(),
      'convertsParenthesizedMapWithCollect': (t) => t.convertsParenthesizedMapWithCollect(),
      'convertsFromAnyPositionInsideTheCall': (t) => t.convertsFromAnyPositionInsideTheCall(),
      'keepsCallbackWithBlockBody': (t) => t.keepsCallbackWithBlockBody(),
      'keepsMapThatIsNotOnIterable': (t) => t.keepsMapThatIsNotOnIterable(),
      'keepsOtherMethods': (t) => t.keepsOtherMethods(),
      'keepsSelectionOutsideInvocations': (t) => t.keepsSelectionOutsideInvocations(),
    },
  );
}

final class ConvertIterableMapToCollectionForTest extends FixRuleTest {
  @override
  void setUp() {
    rule = PreferForLoopInChildren();
    super.setUp();
  }

  static String _source(String expression) =>
      '''
class Mapper {
  int map(int value) => value;
}

Object f(List<int> numbers) => $expression;
''';

  Future<void> _expectConverted(String before, String after, {String at = 'map'}) async {
    final source = _source(before);
    final converted = await applyAssist(
      source,
      (context) => ConvertIterableMapToCollectionFor(context: context),
      offset: source.lastIndexOf(at),
    );
    expect(converted, _source(after));
  }

  Future<void> _expectUnchanged(String expression, {String at = 'map'}) async {
    final source = _source(expression);
    final converted = await applyAssist(
      source,
      (context) => ConvertIterableMapToCollectionFor(context: context),
      offset: source.lastIndexOf(at),
    );
    expect(converted, isNull);
  }

  Future<void> convertsMapToList() =>
      _expectConverted('numbers.map((n) => n * 2).toList()', '[for(final n in numbers) n * 2]');

  Future<void> convertsMapToSet() =>
      _expectConverted('numbers.map((n) => n * 2).toSet()', '{for(final n in numbers) n * 2}');

  Future<void> convertsBareMapToList() =>
      _expectConverted('numbers.map((n) => n * 2)', '[for(final n in numbers) n * 2]');

  Future<void> convertsParenthesizedMapWithCollect() =>
      _expectConverted('(numbers.map((n) => n * 2)).toList()', '[for(final n in numbers) n * 2]');

  Future<void> convertsFromAnyPositionInsideTheCall() => _expectConverted(
    'numbers.map((n) => n * 2).toList()',
    '[for(final n in numbers) n * 2]',
    at: 'n * 2',
  );

  Future<void> keepsCallbackWithBlockBody() =>
      _expectUnchanged('numbers.map((n) { print(n); return n; }).toList()');

  Future<void> keepsMapThatIsNotOnIterable() => _expectUnchanged('Mapper().map((n) => n)');

  Future<void> keepsOtherMethods() => _expectUnchanged('numbers.where((n) => n > 1)', at: 'where');

  Future<void> keepsSelectionOutsideInvocations() =>
      _expectUnchanged('numbers.map((n) => n * 2)', at: 'Object');
}
