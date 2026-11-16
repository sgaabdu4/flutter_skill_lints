part of '../flutter_skill_rules_test.dart';

final class _UseSealedFreezedClassesTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_UseSealedFreezedClassesTest)> get _allCases =>
      caseSet<_UseSealedFreezedClassesTest>(
        parent: const {},
        own: {
          'test_reportsAbstractFreezed': (t) => t._reportsAbstractFreezed(),
          'test_allowsSealedFreezed': (t) => t._allowsSealedFreezed(),
          'test_reportsPlainFreezedClass': (t) => t._reportsPlainFreezedClass(),
          'test_ignoresSameNamedNonFreezedAnnotation': (t) =>
              t._ignoresSameNamedNonFreezedAnnotation(),
        },
      );

  @override
  void setUp() {
    rule = UseSealedFreezedClasses();
    super.setUp();
  }

  Future<void> _reportsAbstractFreezed() async {
    const source = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
abstract class User {}
''';
    await assertDiagnostics(source, [lintFor(source, 'abstract')]);
  }

  Future<void> _allowsSealedFreezed() async {
    await assertNoDiagnostics(r'''
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class User {}
''');
  }

  Future<void> _reportsPlainFreezedClass() async {
    const source = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

@Freezed()
class WorkoutSet {
  const WorkoutSet();
}
''';
    await assertDiagnostics(source, [lintFor(source, 'class')]);
  }

  Future<void> _ignoresSameNamedNonFreezedAnnotation() async {
    await assertNoDiagnostics(r'''
class Freezed {
  const Freezed();
}

const freezed = Freezed();

@freezed
class User {}
''');
  }
}

final class _AvoidRouteParamThrowInBuildTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_AvoidRouteParamThrowInBuildTest)> get _allCases =>
      caseSet<_AvoidRouteParamThrowInBuildTest>(
        parent: const {},
        own: {
          'test_reportsFirstWhereThrowInBuild': (t) => t._reportsFirstWhereThrowInBuild(),
          'test_allowsFallbackValue': (t) => t._allowsFallbackValue(),
          'test_reportsDirectThrowAndUnguardedFirstWhereInBuild': (t) =>
              t._reportsDirectThrowAndUnguardedFirstWhereInBuild(),
          'test_allowsThrowInsideBuildClosure': (t) => t._allowsThrowInsideBuildClosure(),
          'test_allowsThrowInNonWidgetBuild': (t) => t._allowsThrowInNonWidgetBuild(),
          'test_allowsSameNamedFirstWhereOnNonIterable': (t) =>
              t._allowsSameNamedFirstWhereOnNonIterable(),
        },
      );

  @override
  void setUp() {
    rule = AvoidRouteParamThrowInBuild();
    super.setUp();
  }

  Future<void> _reportsFirstWhereThrowInBuild() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Screen extends StatelessWidget {
  const Screen();

  @override
  Widget build(BuildContext context) {
    final items = <String>[];
    final item = items.firstWhere(
      (candidate) => candidate == 'missing',
      orElse: () => throw 'missing',
    );
    return Text(item);
  }
}
''';
    await assertDiagnostics(source, [lintFor(source, 'firstWhere')]);
  }

  Future<void> _allowsFallbackValue() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Screen extends StatelessWidget {
  const Screen();

  @override
  Widget build(BuildContext context) {
    final items = <String>[];
    final item = items.firstWhere(
      (candidate) => candidate == 'missing',
      orElse: () => 'fallback',
    );
    return Text(item);
  }
}
''');
  }

  Future<void> _reportsDirectThrowAndUnguardedFirstWhereInBuild() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class ProductMissingScreen extends StatelessWidget {
  const ProductMissingScreen({required this.productId, required this.names});

  final String productId;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    if (!names.contains(productId)) {
      throw ArgumentError('missing $productId');
    }
    final name = names.firstWhere((n) => n == productId);
    return Text(name);
  }
}
''';
    await assertDiagnostics(source, [
      lintFor(source, r"throw ArgumentError('missing $productId')"),
      lintFor(source, 'firstWhere'),
    ]);
  }

  Future<void> _allowsThrowInsideBuildClosure() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Screen extends StatelessWidget {
  const Screen();

  @override
  Widget build(BuildContext context) {
    final onUnsupported = () => throw UnsupportedError('tap');
    return Text('$onUnsupported');
  }
}
''');
  }

  Future<void> _allowsThrowInNonWidgetBuild() async {
    await assertNoDiagnostics(r'''
class ReportBuilder {
  String build(List<String> lines) {
    if (lines.isEmpty) throw ArgumentError('empty');
    return lines.firstWhere((line) => line.isNotEmpty);
  }
}
''');
  }

  Future<void> _allowsSameNamedFirstWhereOnNonIterable() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Lookup {
  String firstWhere(bool Function(String) test) => '';
}

class Screen extends StatelessWidget {
  const Screen(this.lookup);

  final Lookup lookup;

  @override
  Widget build(BuildContext context) => Text(lookup.firstWhere((value) => value.isEmpty));
}
''');
  }
}

void _defineFlutterSkillRulesPart01BTests() {
  analysisRuleSuite<_UseSealedFreezedClassesTest>(
    'UseSealedFreezedClassesTest',
    _UseSealedFreezedClassesTest.new,
    _UseSealedFreezedClassesTest._allCases,
  );
  analysisRuleSuite<_AvoidRouteParamThrowInBuildTest>(
    'AvoidRouteParamThrowInBuildTest',
    _AvoidRouteParamThrowInBuildTest.new,
    _AvoidRouteParamThrowInBuildTest._allCases,
  );
}
