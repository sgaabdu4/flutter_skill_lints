import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_collection_methods_with_unrelated_types.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidCollectionMethodsWithUnrelatedTypesTest>(
    'AvoidCollectionMethodsWithUnrelatedTypesTest',
    _AvoidCollectionMethodsWithUnrelatedTypesTest.new,
    {
      'reportsListContainsWithUnrelatedType': (t) => t._reportsListContainsWithUnrelatedType(),
      'reportsSetRemoveWithUnrelatedType': (t) => t._reportsSetRemoveWithUnrelatedType(),
      'reportsMapContainsKeyWithUnrelatedType': (t) => t._reportsMapContainsKeyWithUnrelatedType(),
      'reportsMapContainsValueWithUnrelatedType': (t) =>
          t._reportsMapContainsValueWithUnrelatedType(),
      'reportsMapRemoveWithUnrelatedKey': (t) => t._reportsMapRemoveWithUnrelatedKey(),
      'reportsMapIndexWithUnrelatedKey': (t) => t._reportsMapIndexWithUnrelatedKey(),
      'acceptsRelatedTypes': (t) => t._acceptsRelatedTypes(),
      'acceptsDynamicAndGenericArguments': (t) => t._acceptsDynamicAndGenericArguments(),
      'acceptsNullableOfSameType': (t) => t._acceptsNullableOfSameType(),
      'acceptsUnrelatedMethodNames': (t) => t._acceptsUnrelatedMethodNames(),
      'acceptsListIndexAndNoArguments': (t) => t._acceptsListIndexAndNoArguments(),
      'reportsOnMapSubclass': (t) => t._reportsOnMapSubclass(),
    },
  );
}

final class _AvoidCollectionMethodsWithUnrelatedTypesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCollectionMethodsWithUnrelatedTypes();
    super.setUp();
  }

  Future<void> _expectReported(String params, String expression) async {
    final source = 'void f($params) {\n  $expression;\n}\n';
    await assertDiagnostics(source, [lint(source.indexOf(expression), expression.length)]);
  }

  Future<void> _reportsListContainsWithUnrelatedType() =>
      _expectReported('List<int> a', "a.contains('x')");

  Future<void> _reportsSetRemoveWithUnrelatedType() =>
      _expectReported('Set<String> a', 'a.remove(1)');

  Future<void> _reportsMapContainsKeyWithUnrelatedType() =>
      _expectReported('Map<String, int> a', 'a.containsKey(1)');

  Future<void> _reportsMapContainsValueWithUnrelatedType() =>
      _expectReported('Map<String, int> a', "a.containsValue('x')");

  Future<void> _reportsMapRemoveWithUnrelatedKey() =>
      _expectReported('Map<String, int> a', 'a.remove(1)');

  Future<void> _reportsMapIndexWithUnrelatedKey() => _expectReported('Map<String, int> a', 'a[1]');

  Future<void> _reportsOnMapSubclass() async {
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

  Future<void> _acceptsRelatedTypes() => assertNoDiagnostics('''
void f(List<num> a, Map<String, int> m, Set<Object> s) {
  a.contains(1);
  m.containsKey('k');
  m.containsValue(2);
  m['k'];
  s.remove('x');
}
''');

  Future<void> _acceptsDynamicAndGenericArguments() => assertNoDiagnostics('''
void f<T>(List<int> a, dynamic d, T t, Map<String, int> m) {
  a.contains(d);
  a.contains(t);
  m.containsKey(d);
}
''');

  Future<void> _acceptsNullableOfSameType() => assertNoDiagnostics('''
void f(List<int> a, int? x) {
  a.contains(x);
}
''');

  Future<void> _acceptsUnrelatedMethodNames() => assertNoDiagnostics('''
void f(List<int> a, Map<String, int> m) {
  a.indexOf(1);
  m.putIfAbsent('k', () => 1);
  a.add(1);
}
''');

  Future<void> _acceptsListIndexAndNoArguments() => assertNoDiagnostics('''
void f(List<int> a, String s) {
  a[0];
  a.clear();
  s.contains('x');
}
''');
}
