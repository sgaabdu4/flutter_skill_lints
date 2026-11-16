import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_collection_methods_with_unrelated_types.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidCollectionMethodsWithUnrelatedTypesTest>(
    'AvoidCollectionMethodsWithUnrelatedTypesTest',
    AvoidCollectionMethodsWithUnrelatedTypesTest.new,
    {
      'reportsListContainsWithUnrelatedType': (t) => t.reportsListContainsWithUnrelatedType(),
      'reportsSetRemoveWithUnrelatedType': (t) => t.reportsSetRemoveWithUnrelatedType(),
      'reportsMapContainsKeyWithUnrelatedType': (t) => t.reportsMapContainsKeyWithUnrelatedType(),
      'reportsMapContainsValueWithUnrelatedType': (t) =>
          t.reportsMapContainsValueWithUnrelatedType(),
      'reportsMapRemoveWithUnrelatedKey': (t) => t.reportsMapRemoveWithUnrelatedKey(),
      'reportsMapIndexWithUnrelatedKey': (t) => t.reportsMapIndexWithUnrelatedKey(),
      'acceptsRelatedTypes': (t) => t.acceptsRelatedTypes(),
      'acceptsDynamicAndGenericArguments': (t) => t.acceptsDynamicAndGenericArguments(),
      'acceptsNullableOfSameType': (t) => t.acceptsNullableOfSameType(),
      'acceptsUnrelatedMethodNames': (t) => t.acceptsUnrelatedMethodNames(),
      'acceptsListIndexAndNoArguments': (t) => t.acceptsListIndexAndNoArguments(),
      'reportsOnMapSubclass': (t) => t.reportsOnMapSubclass(),
    },
  );
}

final class AvoidCollectionMethodsWithUnrelatedTypesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCollectionMethodsWithUnrelatedTypes();
    super.setUp();
  }

  Future<void> _expectReported(String params, String expression) async {
    final source = 'void f($params) {\n  $expression;\n}\n';
    await assertDiagnostics(source, [lint(source.indexOf(expression), expression.length)]);
  }

  Future<void> reportsListContainsWithUnrelatedType() =>
      _expectReported('List<int> a', "a.contains('x')");

  Future<void> reportsSetRemoveWithUnrelatedType() =>
      _expectReported('Set<String> a', 'a.remove(1)');

  Future<void> reportsMapContainsKeyWithUnrelatedType() =>
      _expectReported('Map<String, int> a', 'a.containsKey(1)');

  Future<void> reportsMapContainsValueWithUnrelatedType() =>
      _expectReported('Map<String, int> a', "a.containsValue('x')");

  Future<void> reportsMapRemoveWithUnrelatedKey() =>
      _expectReported('Map<String, int> a', 'a.remove(1)');

  Future<void> reportsMapIndexWithUnrelatedKey() => _expectReported('Map<String, int> a', 'a[1]');

  Future<void> reportsOnMapSubclass() async {
    const source = '''
class Cache extends MapBase<String, int> {}

class MapBase<K, V> implements Map<K, V> {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void f(Cache c) {
  c.containsKey(1);
}
''';
    const call = 'c.containsKey(1)';
    await assertDiagnostics(source, [lint(source.indexOf(call), call.length)]);
  }

  Future<void> acceptsRelatedTypes() => assertNoDiagnostics('''
void f(List<num> a, Map<String, int> m, Set<Object> s) {
  a.contains(1);
  m.containsKey('k');
  m.containsValue(2);
  m['k'];
  s.remove('x');
}
''');

  Future<void> acceptsDynamicAndGenericArguments() => assertNoDiagnostics('''
void f<T>(List<int> a, dynamic d, T t, Map<String, int> m) {
  a.contains(d);
  a.contains(t);
  m.containsKey(d);
}
''');

  Future<void> acceptsNullableOfSameType() => assertNoDiagnostics('''
void f(List<int> a, int? x) {
  a.contains(x);
}
''');

  Future<void> acceptsUnrelatedMethodNames() => assertNoDiagnostics('''
void f(List<int> a, Map<String, int> m) {
  a.indexOf(1);
  m.putIfAbsent('k', () => 1);
  a.add(1);
}
''');

  Future<void> acceptsListIndexAndNoArguments() => assertNoDiagnostics('''
void f(List<int> a, String s) {
  a[0];
  a.clear();
  s.contains('x');
}
''');
}
