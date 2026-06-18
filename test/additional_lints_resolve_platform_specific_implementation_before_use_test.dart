// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:flutter_skill_lints/src/additional_lints/rules/resolve_platform_specific_implementation_before_use.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(ResolvePlatformSpecificImplementationBeforeUseTest),
  );
}

@reflectiveTest
class ResolvePlatformSpecificImplementationBeforeUseTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = ResolvePlatformSpecificImplementationBeforeUse();
    super.setUp();
  }

  ExpectedDiagnostic lintForLast(String source, String needle) {
    final offset = source.lastIndexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    return lint(offset, needle.length);
  }

  Future<void> test_optionalChainedPlatformMethod_lint() async {
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

  Future<void> test_nullAssertChainedPlatformMethod_lint() async {
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

  Future<void> test_chainedPlatformProperty_lint() async {
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

  Future<void> test_resolvedLocalWithExplicitNullCheck_noLint() async {
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

  Future<void> test_resolutionOnly_noLint() async {
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
