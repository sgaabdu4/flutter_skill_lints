import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_collection_mutating_methods.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unassigned_stream_subscriptions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_wildcard_pattern.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidCollectionMutatingMethodsStaticTest>(
    'AvoidCollectionMutatingMethodsStaticTest',
    _AvoidCollectionMutatingMethodsStaticTest.new,
    {
      'reportsStaticFieldMutation': (t) => t._reportsStaticFieldMutation(),
      'reportsTopLevelVariableMutation': (t) => t._reportsTopLevelVariableMutation(),
      'reportsParameterMutationThroughCascade': (t) => t._reportsParameterMutationThroughCascade(),
      'acceptsInstanceFieldsAndLocals': (t) => t._acceptsInstanceFieldsAndLocals(),
      'acceptsStaticFieldsOfOtherClasses': (t) => t._acceptsStaticFieldsOfOtherClasses(),
      'acceptsNonMutatingMethods': (t) => t._acceptsNonMutatingMethods(),
    },
  );
  analysisRuleSuite<_AvoidUnassignedStreamSubscriptionsTest>(
    'AvoidUnassignedStreamSubscriptionsTest',
    _AvoidUnassignedStreamSubscriptionsTest.new,
    {
      'reportsDiscardedSubscription': (t) => t._reportsDiscardedSubscription(),
      'acceptsAssignedSubscription': (t) => t._acceptsAssignedSubscription(),
      'acceptsListenLookalikes': (t) => t._acceptsListenLookalikes(),
    },
  );
  analysisRuleSuite<_PreferWildcardPatternTest>(
    'PreferWildcardPatternTest',
    _PreferWildcardPatternTest.new,
    {
      'reportsObjectPatternInSwitchExpression': (t) => t._reportsObjectPatternInSwitchExpression(),
      'reportsObjectPatternInSwitchStatement': (t) => t._reportsObjectPatternInSwitchStatement(),
      'reportsObjectPatternInIfCase': (t) => t._reportsObjectPatternInIfCase(),
      'reportsObjectPatternInsideLogicalOr': (t) => t._reportsObjectPatternInsideLogicalOr(),
      'reportsObjectPatternInsideLogicalAnd': (t) => t._reportsObjectPatternInsideLogicalAnd(),
      'acceptsWildcardAndOtherObjectPatterns': (t) => t._acceptsWildcardAndOtherObjectPatterns(),
    },
  );
}

final class _AvoidCollectionMutatingMethodsStaticTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCollectionMutatingMethods();
    super.setUp();
  }

  Future<void> _reportsStaticFieldMutation() async {
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

  Future<void> _reportsTopLevelVariableMutation() async {
    const source = '''
final seen = <int>{};

void record() {
  seen.add(1);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('add(1)'), 'add'.length)]);
  }

  Future<void> _reportsParameterMutationThroughCascade() async {
    const source = '''
void fill(List<int> target) {
  target..add(1);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('add(1)'), 'add'.length)]);
  }

  Future<void> _acceptsInstanceFieldsAndLocals() => assertNoDiagnostics('''
class Holder {
  final items = <int>[];

  void add() {
    items.add(1);
    final local = <int>[];
    local.add(2);
  }
}
''');

  Future<void> _acceptsStaticFieldsOfOtherClasses() => assertNoDiagnostics('''
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

  Future<void> _acceptsNonMutatingMethods() => assertNoDiagnostics('''
class Registry {
  static final items = <int>[];
}

int count(List<int> values) => values.length + Registry.items.length + values.first;
''');
}

final class _AvoidUnassignedStreamSubscriptionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnassignedStreamSubscriptions();
    super.setUp();
  }

  Future<void> _reportsDiscardedSubscription() async {
    const source = '''
import 'dart:async';

void watch(Stream<int> stream) {
  stream.listen((value) {});
}
''';
    const call = 'stream.listen((value) {})';
    await assertDiagnostics(source, [lint(source.indexOf(call), call.length)]);
  }

  Future<void> _acceptsAssignedSubscription() => assertNoDiagnostics('''
import 'dart:async';

StreamSubscription<int>? stored;

void watch(Stream<int> stream) {
  final local = stream.listen((value) {});
  stored = stream.listen((value) {});
}
''');

  Future<void> _acceptsListenLookalikes() => assertNoDiagnostics('''
class Radio {
  void listen() {}
}

void tune(Radio radio) {
  radio.listen();
}
''');
}

final class _PreferWildcardPatternTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferWildcardPattern();
    super.setUp();
  }

  Future<void> _expectReported(String source) =>
      assertDiagnostics(source, [lint(source.indexOf('Object()'), 'Object()'.length)]);

  Future<void> _reportsObjectPatternInSwitchExpression() => _expectReported('''
String f(int v) => switch (v) {
  1 => 'one',
  Object() => 'other',
};
''');

  Future<void> _reportsObjectPatternInSwitchStatement() => _expectReported('''
void f(int v) {
  switch (v) {
    case 1:
      break;
    case Object():
      break;
  }
}
''');

  Future<void> _reportsObjectPatternInIfCase() => _expectReported('''
void f(int v) {
  if (v case Object()) {}
}
''');

  Future<void> _reportsObjectPatternInsideLogicalOr() => _expectReported('''
void f(int? v) {
  if (v case null || Object()) {}
}
''');

  Future<void> _reportsObjectPatternInsideLogicalAnd() => _expectReported('''
void f(int? v) {
  if (v case Object() && final x) {}
}
''');

  Future<void> _acceptsWildcardAndOtherObjectPatterns() => assertNoDiagnostics('''
String f(Object v) => switch (v) {
  int() => 'int',
  Object(hashCode: 1) => 'one',
  _ => 'other',
};
''');
}
