import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_accessing_collections_by_constant_index.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidAccessingCollectionsByConstantIndexTest>(
    'AvoidAccessingCollectionsByConstantIndexTest',
    AvoidAccessingCollectionsByConstantIndexTest.new,
    {
      'reportsLiteralIndexInForLoop': (t) => t.reportsLiteralIndexInForLoop(),
      'reportsLiteralIndexInWhileLoop': (t) => t.reportsLiteralIndexInWhileLoop(),
      'reportsConstantVariableIndex': (t) => t.reportsConstantVariableIndex(),
      'reportsStaticConstantFieldIndex': (t) => t.reportsStaticConstantFieldIndex(),
      'acceptsLoopDependentIndex': (t) => t.acceptsLoopDependentIndex(),
      'acceptsIndexOutsideLoops': (t) => t.acceptsIndexOutsideLoops(),
      'acceptsIndexInsideNestedClosure': (t) => t.acceptsIndexInsideNestedClosure(),
      'acceptsNonConstantVariableIndex': (t) => t.acceptsNonConstantVariableIndex(),
      'reportsDoWhileLoop': (t) => t.reportsDoWhileLoop(),
    },
  );
}

final class AvoidAccessingCollectionsByConstantIndexTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidAccessingCollectionsByConstantIndex();
    super.setUp();
  }

  Future<void> reportsLiteralIndexInForLoop() async {
    const source = '''
void f(List<int> a) {
  for (var i = 0; i < 3; i++) {
    print(a[0]);
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('a[0]'), 'a[0]'.length)]);
  }

  Future<void> reportsLiteralIndexInWhileLoop() async {
    const source = '''
void f(List<int> a) {
  while (a.isNotEmpty) {
    print(a[1]);
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('a[1]'), 'a[1]'.length)]);
  }

  Future<void> reportsDoWhileLoop() async {
    const source = '''
void f(List<int> a) {
  do {
    print(a[2]);
  } while (a.isEmpty);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('a[2]'), 'a[2]'.length)]);
  }

  Future<void> reportsConstantVariableIndex() async {
    const source = '''
const first = 0;

void f(List<int> a) {
  for (final x in a) {
    print(a[first] + x);
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('a[first]'), 'a[first]'.length)]);
  }

  Future<void> reportsStaticConstantFieldIndex() async {
    const source = '''
class K {
  static const slot = 2;
}

void f(List<int> a) {
  for (var i = 0; i < 3; i++) {
    print(a[K.slot]);
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('a[K.slot]'), 'a[K.slot]'.length)]);
  }

  Future<void> acceptsLoopDependentIndex() => assertNoDiagnostics('''
void f(List<int> a) {
  for (var i = 0; i < a.length; i++) {
    print(a[i]);
    print(a[i + 1 < a.length ? i + 1 : i]);
  }
}
''');

  Future<void> acceptsIndexOutsideLoops() => assertNoDiagnostics('''
void f(List<int> a) {
  print(a[0]);
}
''');

  Future<void> acceptsIndexInsideNestedClosure() => assertNoDiagnostics('''
void f(List<int> a) {
  for (var i = 0; i < 3; i++) {
    void read() => print(a[0]);
    read();
  }
}
''');

  Future<void> acceptsNonConstantVariableIndex() => assertNoDiagnostics('''
void f(List<int> a, int slot) {
  for (var i = 0; i < 3; i++) {
    print(a[slot]);
  }
}
''');
}
