// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_dot_shorthands.dart';
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
}
