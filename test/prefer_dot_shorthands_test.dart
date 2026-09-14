// ignore_for_file: non_constant_identifier_names

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_dot_shorthands_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_dot_shorthands.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferDotShorthandsTest);
  });
}

@reflectiveTest
final class PreferDotShorthandsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferDotShorthands();
    super.setUp();
  }

  Future<void> test_contextuallyTypedForms_lint() async {
    const source = r'''
enum Axis { start, center }

class Insets {
  const Insets();
  const Insets.all(int value);
  static const zero = Insets();
  static Insets compact() => const Insets();
  Insets normalized() => this;
}

void consume(Axis axis, {required Insets padding}) {}

Axis axis() => Axis.center;
Insets padding() => const Insets.all(8);

void example() {
  Axis current = Axis.start;
  current = Axis.center;
  consume(Axis.center, padding: Insets.compact());
  final values = <Axis>[Axis.start, Axis.center];
  final lookup = <Axis, Insets>{Axis.center: Insets.zero};
  final chained = <Insets>[Insets.zero.normalized()];
  if (current == Axis.center) {}
}
''';

    await assertDiagnostics(source, [
      lint(154, 14),
      lint(274, 11),
      lint(307, 19),
      lint(363, 10),
      lint(387, 11),
      lint(410, 11),
      lint(432, 16),
      lint(475, 10),
      lint(487, 11),
      lint(533, 11),
      lint(546, 11),
      lint(587, 11),
      lint(631, 11),
    ]);
  }

  Future<void> test_nullableContext_lint() async {
    const source = 'enum Axis { center }\nAxis? axis = Axis.center;';
    await assertDiagnostics(source, [lint(source.indexOf('Axis.center'), 'Axis.center'.length)]);
  }

  Future<void> test_importPrefixedType_lint() async {
    newFile('$testPackageRootPath/lib/types.dart', 'enum Axis { center }');
    const source = r'''
import 'types.dart' as types;

void consume(types.Axis axis) {}
void example() => consume(types.Axis.center);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('types.Axis.center'), 'types.Axis.center'.length),
    ]);
  }

  Future<void> test_extensionTypeStaticAndConstructor_lint() async {
    const source = r'''
extension type UserId(int value) {
  static UserId get zero => UserId(0);
}
void consume(UserId id) {}
void example() {
  consume(UserId.zero);
  consume(UserId(1));
}
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('UserId(0)'), 'UserId(0)'.length),
      lint(source.indexOf('UserId.zero'), 'UserId.zero'.length),
      lint(source.lastIndexOf('UserId(1)'), 'UserId(1)'.length),
    ]);
  }

  Future<void> test_conditionalSwitchPatternAndDefault_lint() async {
    const source = r'''
enum Axis { start, center }
Axis conditional(bool value) => value ? Axis.start : Axis.center;
Axis switched(bool value) => switch (value) {
  true => Axis.start,
  false => Axis.center,
};
bool isCenter(Axis axis) => switch (axis) {
  Axis.center => true,
  _ => false,
};
void consume([Axis axis = Axis.center]) {}
''';
    const targets = [
      'Axis.start',
      'Axis.center',
      'Axis.start',
      'Axis.center',
      'Axis.center',
      'Axis.center',
    ];
    var cursor = 0;
    final diagnostics = targets.map((target) {
      final offset = source.indexOf(target, cursor);
      cursor = offset + target.length;
      return lint(offset, target.length);
    }).toList();
    await assertDiagnostics(source, diagnostics);
  }

  Future<void> test_inferredOrWrongNamespace_noLint() async {
    await assertNoDiagnostics(r'''
enum Axis { center }
class Color { const Color(); }
abstract final class Palette { static const red = Color(); }

final inferred = Axis.center;
Color color = Palette.red;
''');
  }

  Future<void> test_namedExtensionStaticHelpers_noLint() async {
    await assertNoDiagnostics(r'''
extension DateTimeX on DateTime {
  static DateTime nowUtc() => throw 0;
}
extension ChoiceMapping on Choice {
  static Choice fromDbInt(int value) => throw 0;
}
enum Choice { one }

DateTime now() => DateTimeX.nowUtc();
Choice choice() => ChoiceMapping.fromDbInt(1);
''');
  }

  Future<void> test_inferredGenericArgument_noLint() async {
    await assertNoDiagnostics(r'''
enum Choice { one }
class Key<T> {
  const Key(T value);
}
class Navigator {
  void pop<T>(T? value) {}
}
void consume<T>(T value, {T? named}) {}

void example(Navigator navigator) {
  consume(Choice.one);
  consume(0, named: Choice.one);
  navigator.pop(Choice.one);
  const Key(Choice.one);
}
''');
  }

  Future<void> test_narrowerExplicitGenericConstructor_noLint() async {
    await assertNoDiagnostics(r'''
class Box<T> {
  const Box();
}
Box<num> value = const Box<int>();
''');
  }

  Future<void> test_explicitGenericArgument_lint() async {
    const source = r'''
enum Choice { one }
class Key<T> {
  const Key(T value);
}
class Navigator {
  void pop<T>(T? value) {}
}
void consume<T>(T value) {}

void example(Navigator navigator) {
  consume<Choice>(Choice.one);
  navigator.pop<Choice>(Choice.one);
  const Key<Choice>(Choice.one);
}
''';
    final targets = _targetRanges(source, const ['Choice.one', 'Choice.one', 'Choice.one']);
    await assertDiagnostics(source, targets.map((target) => lint(target.$1, target.$2)).toList());
  }

  Future<void> test_asyncReturn_usesFlattenedValueContext() async {
    const source = r'''
import 'dart:async';

enum Axis { start, center }

Future<Axis> expression() async => Axis.center;
FutureOr<Axis> futureOr() async => Axis.start;
Future<Axis> block() async {
  return Axis.center;
}
Future<Axis> alreadyFuture() async => Future<Axis>.error(0);
''';
    final targets = _targetRanges(source, const ['Axis.center', 'Axis.start', 'Axis.center']);
    await assertDiagnostics(source, targets.map((target) => lint(target.$1, target.$2)).toList());
  }

  Future<void> test_subtypeStaticNamespace_noLint() async {
    await assertNoDiagnostics(r'''
class Base {
  const Base();
}
class Derived extends Base {
  const Derived();
  static const value = Derived();
}
Base value = Derived.value;
''');
  }

  Future<void> test_selectorChainWithContextNamespace_lint() async {
    const source = r'''
class Item {
  static Builder builder() => .new();
}
class Builder {
  Item build() => .new();
}
Item item = Item.builder().build();
''';
    const target = 'Item.builder()';
    await assertDiagnostics(source, [lint(source.indexOf(target), target.length)]);
  }

  Future<void> test_fix_constructorForms_areValid() async {
    const source = r'''
class Box<T> {
  const Box();
  const Box.named();
}

Box<int> a = new Box<int>();
Box<int> b = new Box<int>.named();
Box<int> c = const Box<int>();
Box<int> d = const Box<int>.named();
Box<int> e = Box<int>();
Box<int> f = Box<int>.named();
''';
    const targets = [
      'new Box<int>()',
      'new Box<int>.named()',
      'const Box<int>()',
      'const Box<int>.named()',
      'Box<int>()',
      'Box<int>.named()',
    ];
    const expected = r'''
class Box<T> {
  const Box();
  const Box.named();
}

Box<int> a = .new();
Box<int> b = .named();
Box<int> c = const .new();
Box<int> d = const .named();
Box<int> e = .new();
Box<int> f = .named();
''';

    await _assertFixes(source, targets, expected);
  }

  Future<void> test_fix_staticGenericMethod_preservesTypeArguments() async {
    const source = r'''
class Token {
  const Token();
  static Token parse<T>(T value) => const .new();
}
Token token = Token.parse<int>(1);
''';
    const expected = r'''
class Token {
  const Token();
  static Token parse<T>(T value) => const .new();
}
Token token = .parse<int>(1);
''';
    await _assertFixes(source, const ['Token.parse<int>(1)'], expected);
  }

  Future<void> test_fix_typeAliasNamespace_isValid() async {
    const source = r'''
class Token {
  const Token();
  static const zero = Token();
}
typedef Alias = Token;
Alias token = Alias.zero;
''';
    const expected = r'''
class Token {
  const Token();
  static const zero = Token();
}
typedef Alias = Token;
Alias token = .zero;
''';
    await _assertFixes(source, const ['Alias.zero'], expected);
  }

  Future<void> test_fix_extensionTypeMembers_areValid() async {
    const source = r'''
extension type UserId(int value) {
  static UserId get zero => .new(0);
  static UserId parse(String value) => .new(0);
}
UserId zero = UserId.zero;
UserId parsed = UserId.parse('1');
UserId created = UserId(1);
''';
    const expected = r'''
extension type UserId(int value) {
  static UserId get zero => .new(0);
  static UserId parse(String value) => .new(0);
}
UserId zero = .zero;
UserId parsed = .parse('1');
UserId created = .new(1);
''';
    await _assertFixes(source, const ['UserId.zero', "UserId.parse('1')", 'UserId(1)'], expected);
  }

  Future<void> test_fix_selectorChain_isValid() async {
    const source = r'''
class Item {
  static Builder builder() => .new();
}
class Builder {
  Item build() => .new();
}
Item item = Item.builder().build();
''';
    const expected = r'''
class Item {
  static Builder builder() => .new();
}
class Builder {
  Item build() => .new();
}
Item item = .builder().build();
''';
    await _assertFixes(source, const ['Item.builder()'], expected);
  }

  Future<void> test_alreadyShorthand_noLint() async {
    await assertNoDiagnostics(r'''
enum Axis { center }
void consume(Axis axis) {}
void example() => consume(.center);
''');
  }

  Future<void> test_untypedClosureReturn_noLint() async {
    await assertNoDiagnostics(r'''
enum Axis { center }
final callback = () => Axis.center;
''');
  }

  Future<void> _assertFixes(String source, List<String> targets, String expected) async {
    final ranges = _targetRanges(source, targets);
    await assertDiagnostics(source, ranges.map((target) => lint(target.$1, target.$2)).toList());

    final unit = await getResolvedUnit(testFile);
    final library = await unit.session.getResolvedLibraryContaining(testFilePath);
    expect(library, isA<ResolvedLibraryResult>());
    final edits = <SourceEdit>[];
    for (final (offset, length) in ranges) {
      final context = CorrectionProducerContext.createResolved(
        libraryResult: library as ResolvedLibraryResult,
        unitResult: unit,
        selectionOffset: offset,
        selectionLength: length,
      );
      final builder = ChangeBuilder(session: unit.session);
      final producer = PreferDotShorthandsFix(context: context);
      expect(producer.canBeAppliedAcrossSingleFile, isTrue);
      expect(producer.multiFixKind, isNotNull);
      await producer.compute(builder);
      edits.addAll(builder.sourceChange.edits.single.edits);
    }

    edits.sort((left, right) => right.offset.compareTo(left.offset));
    final fixed = SourceEdit.applySequence(normalizeSource(source), edits);
    expect(fixed, normalizeSource(expected));
    newFile(testFilePath, fixed);
    await assertNoDiagnostics(fixed);
  }
}

List<(int, int)> _targetRanges(String source, List<String> targets) {
  var cursor = 0;
  return targets.map((target) {
    final offset = source.indexOf(target, cursor);
    expect(offset, isNonNegative, reason: 'Missing target after offset $cursor: $target');
    cursor = offset + target.length;
    return (offset, target.length);
  }).toList();
}
