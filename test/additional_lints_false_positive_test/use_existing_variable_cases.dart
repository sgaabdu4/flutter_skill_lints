// ignore_for_file: non_constant_identifier_names

part of '../additional_lints_false_positive_test.dart';

@reflectiveTest
final class UseExistingVariableFalsePositiveTest extends _AdditionalLintRuleTest {
  Future<void> test_allowsIndependentAllocations() async {
    for (final (index, expression) in ['Completer<int>()', 'Box()', 'Box.create()'].indexed) {
      final path = '$testPackageLibPath/creation_$index.dart';
      newFile(path, '''
${index == 0 ? "import 'dart:async';" : ''}
class Box { Box(); factory Box.create() => Box(); }
void run() {
  final first = $expression;
  final second = $expression;
  print(first);
  print(second);
}
''');
      await assertNoDiagnosticsInFile(path);
    }
  }

  Future<void> test_allowsIndependentShorthandAllocations() async {
    await assertNoDiagnostics(r'''
class Box { Box(); }
void run() {
  final Box first = .new();
  final Box second = .new();
  print(first);
  print(second);
}
''');
  }

  Future<void> test_constantCreationStillReports() async {
    const source = r'''
class Box { const Box(); }
void run() {
  final first = const Box();
  final second = const Box();
  print(first);
  print(second);
}
''';
    await assertDiagnostics(source, [lint(source.lastIndexOf('const Box()'), 11)]);
  }

  @override
  void setUp() {
    rule = UseExistingVariable();
    super.setUp();
  }

  Future<void> test_writeTargetsAreNotRepeatedReads() async {
    for (final (index, assignment) in [
      'box.value = 2',
      'box.value += 2',
      'box.value++',
      '++box.value',
    ].indexed) {
      final path = '$testPackageLibPath/assignment_$index.dart';
      newFile(path, '''
class Box { int value = 1; }
void run(Box box) {
  final previous = box.value;
  $assignment;
  print(previous);
}
''');
      await assertNoDiagnosticsInFile(path);
    }
  }

  Future<void> test_indexAssignmentIsNotRepeatedRead() async {
    await assertNoDiagnostics(r'''
void run(Map<String, int> cache) {
  final previous = cache['key'];
  cache['key'] = 2;
  print(previous);
}
''');
  }

  Future<void> test_nullAssertedReadStillReports() async {
    const source = r'''
class Box { int? value; }
void run(Box box) {
  final previous = box.value;
  final repeated = box.value!;
  print(previous);
  print(repeated);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('box.value!'), 9)]);
  }

  Future<void> test_assignmentRightHandReadStillReports() async {
    const source = r'''
class Box { int value = 1; }
void run(Box box) {
  final previous = box.value;
  box.value = box.value + 1;
  print(previous);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('box.value +'), 9)]);
  }

  Future<void> test_allowsRepeatedEffectfulReads() async {
    await assertNoDiagnostics(r'''
class Container {
  Object read(Object provider) => Object();
}

final provider = Object();

void run(Container container) {
  final initial = container.read(provider);
  final duplicate = container.read(provider);
  print(initial);
  print(duplicate);
}
''');
  }

  Future<void> test_allowsRepeatedStatefulGettersAndIndexReads() async {
    await assertNoDiagnostics(r'''
class Counter {
  int value = 0;
  int get next => ++value;
  int operator [](int index) => ++value;
}
void run(Counter counter) {
  final first = counter.next;
  final second = counter.next;
  final indexedFirst = counter[0];
  final indexedSecond = counter[0];
  print((first, second, indexedFirst, indexedSecond));
}
''');
  }

  Future<void> test_allowsRepeatedUnqualifiedGetterReads() async {
    await assertNoDiagnostics(r'''
int counter = 0;
int get value => ++counter;
void run() {
  final first = value + 1;
  final second = value + 1;
  print((first, second));
}
''');
  }

  Future<void> test_allowsRepeatedOverloadedOperators() async {
    await assertNoDiagnostics(r'''
class Counter {
  int calls = 0;
  Counter operator +(Counter other) {
    calls++;
    return this;
  }
}
void run(Counter value, Counter other) {
  final first = value + other;
  final second = value + other;
  print((first, second));
}
''');
  }

  Future<void> test_reportsPureBuiltInBooleanAndNullCoalescingDuplicates() async {
    const source = r'''
void run(bool x, bool y, String? text, String fallback) {
  final first = x && y;
  final second = x && y;
  final third = text ?? fallback;
  final fourth = text ?? fallback;
  final fifth = x || y;
  final sixth = x || y;
  print((first, second, third, fourth, fifth, sixth));
}
''';
    await assertDiagnostics(source, [
      lint(source.lastIndexOf('x && y'), 6),
      lint(source.lastIndexOf('text ?? fallback'), 16),
      lint(source.lastIndexOf('x || y'), 6),
    ]);
  }

  Future<void> test_allowsRepeatedOverloadedUnaryOperators() async {
    await assertNoDiagnostics(r'''
class Counter {
  int calls = 0;
  int operator -() {
    calls++;
    return calls;
  }
  int operator ~() {
    calls++;
    return calls;
  }
}
void run(Counter value) {
  final first = -value + 1;
  final second = -value + 1;
  final third = ~value + 1;
  final fourth = ~value + 1;
  print((first, second, third, fourth));
}
''');
  }

  Future<void> test_allowsFreshReadAfterAwaitInInitializer() async {
    await assertNoDiagnostics(r'''
class Container {
  int value = 0;
  int read() => ++value;
}

Future<void> run(Container container) async {
  final initial = container.read();
  final result = await Future<int>.value(1);
  final after = container.read();
  print((initial, result, after));
}
''');
  }

  Future<void> test_allowsReadAfterEffectWithinInitializer() async {
    await assertNoDiagnostics(r'''
class Counter {
  int value = 0;
  int bump() => ++value;
}
void run(Counter counter) {
  final initial = counter.value + 1;
  final after = counter.bump() + counter.value + 1;
  print((initial, after));
}
''');
  }

  Future<void> test_reportsPureReadBeforeEffectWithinInitializer() async {
    const source = r'''
int increment() => 1;
void run(int left, int right) {
  final cached = left + right;
  final result = (left + right) + increment();
  print((cached, result));
}
''';
    await assertDiagnostics(source, [lint(source.lastIndexOf('left + right'), 12)]);
  }

  Future<void> test_awaitOrderPreservesFreshReads() async {
    const source = r'''
class Counter { int value = 0; }
Future<void> before(Counter counter) async {
  final cached = counter.value + 1;
  final result = (counter.value + 1) + await Future<int>.value(2);
  print((cached, result));
}
Future<void> after(Counter counter) async {
  final cached = counter.value + 1;
  final result = await Future<int>.value(2) + (counter.value + 1);
  print((cached, result));
}
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('counter.value + 1', source.indexOf('final result')), 17),
    ]);
  }

  Future<void> test_expressionArgumentOrderRespectsMutation() async {
    const source = r'''
class Counter { int value = 0; }
int mutate(Counter counter) => ++counter.value;
void sink(int first, int second) {}
void unsafe(Counter counter, int right) {
  final cached = counter.value + right;
  sink(mutate(counter), counter.value + right);
  print(cached);
}
void safe(Counter counter, int right) {
  final cached = counter.value + right;
  sink(counter.value + right, mutate(counter));
  print(cached);
}
''';
    await assertDiagnostics(source, [lint(source.lastIndexOf('counter.value + right'), 21)]);
  }

  Future<void> test_assignmentOrderRespectsMutation() async {
    const source = r'''
class Counter { int value = 0; }
void sink(int first, int second) {}
void stale(Counter counter, int right) {
  final cached = counter.value + right;
  sink(counter.value = 9, counter.value + right);
  print(cached);
}
void safe(Counter counter, int right) {
  final cached = counter.value + right;
  sink(counter.value + right, counter.value = 9);
  print(cached);
}
void declarations(Counter counter, int right) {
  final cached = counter.value + right;
  final changed = counter.value = 9, later = counter.value + right;
  print((cached, changed, later));
}
''';
    await assertDiagnostics(source, [
      lint(source.lastIndexOf('counter.value + right', source.indexOf('void declarations')), 21),
    ]);
  }

  Future<void> test_multipleDeclarationsDoNotReuseValueAcrossEffect() async {
    await assertNoDiagnostics(r'''
class Counter {
  int value = 0;
  int bump() => ++value;
}
void run(Counter counter) {
  final first = counter.value + 1, changed = counter.bump();
  final after = counter.value + 1;
  print((first, changed, after));
}
''');
  }

  Future<void> test_reportsPureDuplicateExpression() async {
    const source = r'''
void run(int value) {
  final initial = value + 1;
  final duplicate = value + 1;
  print((initial, duplicate));
}
''';
    await assertDiagnostics(source, [lint(source.lastIndexOf('value + 1'), 9)]);
  }

  Future<void> test_allowsDuplicateExpressionAfterMutation() async {
    await assertNoDiagnostics(r'''
class Container {
  Object read(Object provider) => Object();
}

class Notifier {
  void updateSet(Object value) {}
}

final provider = Object();

void run(Container container, Notifier notifier) {
  final initial = container.read(provider);
  notifier.updateSet(initial);
  final afterUpdate = container.read(provider);
  print(afterUpdate);
}
''');
  }

  Future<void> test_allowsFreshCollectionRecorders() async {
    await assertNoDiagnostics(r'''
void run() {
  final deletedIds = <String>[];
  final createdRows = <Map<String, Object?>>[];
  final permissions = <List<String>>[];
  deletedIds.add('one');
  createdRows.add({'id': 'row-1'});
  permissions.add(['read']);
}
''');
  }
}
