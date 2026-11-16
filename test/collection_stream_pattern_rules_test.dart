import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_collection_mutating_methods.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unassigned_stream_subscriptions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_wildcard_pattern.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidCollectionMutatingMethodsStaticTest>(
    'AvoidCollectionMutatingMethodsStaticTest',
    AvoidCollectionMutatingMethodsStaticTest.new,
    {
      'reportsStaticFieldMutation': (t) => t.reportsStaticFieldMutation(),
      'reportsTopLevelVariableMutation': (t) => t.reportsTopLevelVariableMutation(),
      'reportsParameterMutationThroughCascade': (t) => t.reportsParameterMutationThroughCascade(),
      'acceptsInstanceFieldsAndLocals': (t) => t.acceptsInstanceFieldsAndLocals(),
      'acceptsStaticFieldsOfOtherClasses': (t) => t.acceptsStaticFieldsOfOtherClasses(),
      'acceptsNonMutatingMethods': (t) => t.acceptsNonMutatingMethods(),
    },
  );
  analysisRuleSuite<AvoidUnassignedStreamSubscriptionsTest>(
    'AvoidUnassignedStreamSubscriptionsTest',
    AvoidUnassignedStreamSubscriptionsTest.new,
    {
      'reportsDiscardedSubscription': (t) => t.reportsDiscardedSubscription(),
      'acceptsAssignedSubscription': (t) => t.acceptsAssignedSubscription(),
      'acceptsListenLookalikes': (t) => t.acceptsListenLookalikes(),
    },
  );
  analysisRuleSuite<PreferWildcardPatternTest>(
    'PreferWildcardPatternTest',
    PreferWildcardPatternTest.new,
    {
      'reportsObjectPatternInSwitchExpression': (t) => t.reportsObjectPatternInSwitchExpression(),
      'reportsObjectPatternInSwitchStatement': (t) => t.reportsObjectPatternInSwitchStatement(),
      'reportsObjectPatternInIfCase': (t) => t.reportsObjectPatternInIfCase(),
      'reportsObjectPatternInsideLogicalOr': (t) => t.reportsObjectPatternInsideLogicalOr(),
      'reportsObjectPatternInsideLogicalAnd': (t) => t.reportsObjectPatternInsideLogicalAnd(),
      'acceptsWildcardAndOtherObjectPatterns': (t) => t.acceptsWildcardAndOtherObjectPatterns(),
    },
  );
}

final class AvoidCollectionMutatingMethodsStaticTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCollectionMutatingMethods();
    super.setUp();
  }

  Future<void> reportsStaticFieldMutation() async {
    const source = '''
class Registry {
  static final items = <int>[];
}

void register() {
  Registry.items.add(1);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('add(1)'), 'add'.length)]);
  }

  Future<void> reportsTopLevelVariableMutation() async {
    const source = '''
final seen = <int>{};

void record() {
  seen.add(1);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('add(1)'), 'add'.length)]);
  }

  Future<void> reportsParameterMutationThroughCascade() async {
    const source = '''
void fill(List<int> target) {
  target..add(1);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('add(1)'), 'add'.length)]);
  }

  Future<void> acceptsInstanceFieldsAndLocals() => assertNoDiagnostics('''
class Holder {
  final items = <int>[];

  void add() {
    items.add(1);
    final local = <int>[];
    local.add(2);
  }
}
''');

  Future<void> acceptsStaticFieldsOfOtherClasses() => assertNoDiagnostics('''
class Registry {
  static final items = <int>[];
  static final names = <String>[];
}

class Other {
  final items = <int>[];
}

void register(Other other) {
  other.items.add(1);
}
''');

  Future<void> acceptsNonMutatingMethods() => assertNoDiagnostics('''
class Registry {
  static final items = <int>[];
}

int count(List<int> values) => values.length + Registry.items.length + values.first;
''');
}

final class AvoidUnassignedStreamSubscriptionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnassignedStreamSubscriptions();
    super.setUp();
  }

  Future<void> reportsDiscardedSubscription() async {
    const source = '''
import 'dart:async';

void watch(Stream<int> stream) {
  stream.listen((value) {});
}
''';
    const call = 'stream.listen((value) {})';
    await assertDiagnostics(source, [lint(source.indexOf(call), call.length)]);
  }

  Future<void> acceptsAssignedSubscription() => assertNoDiagnostics('''
import 'dart:async';

StreamSubscription<int>? stored;

void watch(Stream<int> stream) {
  final local = stream.listen((value) {});
  stored = stream.listen((value) {});
}
''');

  Future<void> acceptsListenLookalikes() => assertNoDiagnostics('''
class Radio {
  void listen() {}
}

void tune(Radio radio) {
  radio.listen();
}
''');
}

final class PreferWildcardPatternTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferWildcardPattern();
    super.setUp();
  }

  Future<void> _expectReported(String source) =>
      assertDiagnostics(source, [lint(source.indexOf('Object()'), 'Object()'.length)]);

  Future<void> reportsObjectPatternInSwitchExpression() => _expectReported('''
String f(int v) => switch (v) {
  1 => 'one',
  Object() => 'other',
};
''');

  Future<void> reportsObjectPatternInSwitchStatement() => _expectReported('''
void f(int v) {
  switch (v) {
    case 1:
      break;
    case Object():
      break;
  }
}
''');

  Future<void> reportsObjectPatternInIfCase() => _expectReported('''
void f(int v) {
  if (v case Object()) {}
}
''');

  Future<void> reportsObjectPatternInsideLogicalOr() => _expectReported('''
void f(int? v) {
  if (v case null || Object()) {}
}
''');

  Future<void> reportsObjectPatternInsideLogicalAnd() => _expectReported('''
void f(int? v) {
  if (v case Object() && final x) {}
}
''');

  Future<void> acceptsWildcardAndOtherObjectPatterns() => assertNoDiagnostics('''
String f(Object v) => switch (v) {
  int() => 'int',
  Object(hashCode: 1) => 'one',
  _ => 'other',
};
''');
}
