import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/resolve_platform_specific_implementation_before_use.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_ResolvePlatformSpecificImplementationBeforeUseTest>(
    'ResolvePlatformSpecificImplementationBeforeUseTest',
    _ResolvePlatformSpecificImplementationBeforeUseTest.new,
    _ResolvePlatformSpecificImplementationBeforeUseTest._allCases,
  );
}

class _ResolvePlatformSpecificImplementationBeforeUseTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_ResolvePlatformSpecificImplementationBeforeUseTest)>
  get _allCases => caseSet<_ResolvePlatformSpecificImplementationBeforeUseTest>(
    parent: const {},
    own: {
      'test_optionalChainedPlatformMethod_lint': (t) => t._optionalChainedPlatformMethodLint(),
      'test_nullAssertChainedPlatformMethod_lint': (t) => t._nullAssertChainedPlatformMethodLint(),
      'test_chainedPlatformProperty_lint': (t) => t._chainedPlatformPropertyLint(),
      'test_resolvedLocalWithExplicitNullCheck_noLint': (t) =>
          t._resolvedLocalWithExplicitNullCheckNoLint(),
      'test_resolutionOnly_noLint': (t) => t._resolutionOnlyNoLint(),
    },
  );

  @override
  void setUp() {
    rule = ResolvePlatformSpecificImplementationBeforeUse();
    super.setUp();
  }

  T lintForLast<T>(String source, String needle) {
    final offset = source.lastIndexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    return lint(offset, needle.length) as T;
  }

  Future<void> _optionalChainedPlatformMethodLint() async {
    const source = r'''
class FlutterLocalNotificationsPlugin {
  T? resolvePlatformSpecificImplementation<T>() => null;
}

class AndroidFlutterLocalNotificationsPlugin {
  Future<bool?> requestNotificationsPermission() async => true;
}

Future<bool> requestPermission(FlutterLocalNotificationsPlugin plugin) async {
  final granted = await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  return granted == true;
}
''';

    await assertDiagnostics(source, [lintForLast(source, 'resolvePlatformSpecificImplementation')]);
  }

  Future<void> _nullAssertChainedPlatformMethodLint() async {
    const source = r'''
class FlutterLocalNotificationsPlugin {
  T? resolvePlatformSpecificImplementation<T>() => null;
}

class AndroidFlutterLocalNotificationsPlugin {
  Future<bool?> requestNotificationsPermission() async => true;
}

Future<bool> requestPermission(FlutterLocalNotificationsPlugin plugin) async {
  final granted = await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
      .requestNotificationsPermission();
  return granted == true;
}
''';

    await assertDiagnostics(source, [lintForLast(source, 'resolvePlatformSpecificImplementation')]);
  }

  Future<void> _chainedPlatformPropertyLint() async {
    const source = r'''
class Plugin {
  T? resolvePlatformSpecificImplementation<T>() => null;
}

class PlatformPlugin {
  bool get isReady => true;
}

bool isReady(Plugin plugin) {
  return plugin.resolvePlatformSpecificImplementation<PlatformPlugin>()?.isReady == true;
}
''';

    await assertDiagnostics(source, [lintForLast(source, 'resolvePlatformSpecificImplementation')]);
  }

  Future<void> _resolvedLocalWithExplicitNullCheckNoLint() async {
    await assertNoDiagnostics(r'''
class FlutterLocalNotificationsPlugin {
  T? resolvePlatformSpecificImplementation<T>() => null;
}

class AndroidFlutterLocalNotificationsPlugin {
  Future<bool?> requestNotificationsPermission() async => true;
}

Future<bool> requestPermission(FlutterLocalNotificationsPlugin plugin) async {
  final android = plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (android == null) return false;

  final granted = await android.requestNotificationsPermission();
  return granted == true;
}
''');
  }

  Future<void> _resolutionOnlyNoLint() async {
    await assertNoDiagnostics(r'''
class Plugin {
  T? resolvePlatformSpecificImplementation<T>() => null;
}

Object? resolve(Plugin plugin) {
  return plugin.resolvePlatformSpecificImplementation<Object>();
}
''');
  }
}
