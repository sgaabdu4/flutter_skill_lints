import 'package:flutter_skill_lints/src/additional_lints/fixes/use_dedicated_media_query_methods_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_dedicated_media_query_methods.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<UseDedicatedMediaQueryMethodsTest>(
    'UseDedicatedMediaQueryMethodsTest',
    UseDedicatedMediaQueryMethodsTest.new,
    {
      'reportsOfWithSingleProperty': (t) => t.reportsOfWithSingleProperty(),
      'reportsMaybeOfWithSingleProperty': (t) => t.reportsMaybeOfWithSingleProperty(),
      'acceptsDedicatedMethods': (t) => t.acceptsDedicatedMethods(),
      'acceptsUnsupportedProperties': (t) => t.acceptsUnsupportedProperties(),
      'acceptsOtherReceivers': (t) => t.acceptsOtherReceivers(),
      'acceptsOtherMethods': (t) => t.acceptsOtherMethods(),
      'rewritesOfToDedicatedMethod': (t) => t.rewritesOfToDedicatedMethod(),
      'rewritesMaybeOfToDedicatedMethod': (t) => t.rewritesMaybeOfToDedicatedMethod(),
    },
  );
}

final class UseDedicatedMediaQueryMethodsTest extends FixRuleTest {
  @override
  void setUp() {
    rule = UseDedicatedMediaQueryMethods();
    super.setUp();
  }

  static const _fakes = '''
class BuildContext {}

class MediaQueryData {
  final double size = 0;
  final int orientation = 0;
  final int viewport = 0;
}

class MediaQuery {
  static MediaQueryData of(BuildContext context) => MediaQueryData();
  static MediaQueryData? maybeOf(BuildContext context) => null;
  static double sizeOf(BuildContext context) => 0;
  static double? maybeSizeOf(BuildContext context) => null;
  static int refresh(BuildContext context) => 0;
}

class Other {
  static MediaQueryData of(BuildContext context) => MediaQueryData();
}

''';

  static const _of =
      '''
${_fakes}double f(BuildContext context) => MediaQuery.of(context).size;
''';

  Future<void> reportsOfWithSingleProperty() => assertDiagnostics(_of, [
    lint(_of.indexOf('MediaQuery.of'), 'MediaQuery.of(context).size'.length),
  ]);

  Future<void> reportsMaybeOfWithSingleProperty() async {
    const source =
        '''
${_fakes}double? f(BuildContext context) => MediaQuery.maybeOf(context)?.size;
''';
    const expression = 'MediaQuery.maybeOf(context)?.size';
    await assertDiagnostics(source, [lint(source.indexOf(expression), expression.length)]);
  }

  Future<void> acceptsDedicatedMethods() => assertNoDiagnostics('''
${_fakes}double f(BuildContext context) => MediaQuery.sizeOf(context);
''');

  Future<void> acceptsUnsupportedProperties() => assertNoDiagnostics('''
${_fakes}int f(BuildContext context) => MediaQuery.of(context).viewport;
''');

  Future<void> acceptsOtherReceivers() => assertNoDiagnostics('''
${_fakes}double f(BuildContext context) => Other.of(context).size;
''');

  Future<void> acceptsOtherMethods() => assertNoDiagnostics('''
${_fakes}int f(BuildContext context) => MediaQuery.refresh(context);
''');

  Future<void> rewritesOfToDedicatedMethod() => expectFix(
    _of,
    (context) => UseDedicatedMediaQueryMethodsFix(context: context),
    expected:
        '''
${_fakes}double f(BuildContext context) => MediaQuery.sizeOf(context);
''',
  );

  Future<void> rewritesMaybeOfToDedicatedMethod() => expectFix(
    '''
${_fakes}double? f(BuildContext context) => MediaQuery.maybeOf(context)?.size;
''',
    (context) => UseDedicatedMediaQueryMethodsFix(context: context),
    expected:
        '''
${_fakes}double? f(BuildContext context) => MediaQuery.maybeSizeOf(context);
''',
  );
}
