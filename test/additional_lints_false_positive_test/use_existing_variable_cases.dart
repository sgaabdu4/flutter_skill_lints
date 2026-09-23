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

  Future<void> test_reportsDuplicateExpressionWithoutInterveningSideEffect() async {
    const source = r'''
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
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('container.read(provider)', source.indexOf('duplicate')), 24),
    ]);
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
