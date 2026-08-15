// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_context_is_current_modal_route.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(UseContextIsCurrentModalRouteTest));
}

@reflectiveTest
class UseContextIsCurrentModalRouteTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseContextIsCurrentModalRoute();
    super.setUp();
  }

  T lintFor<T>(String source, String needle) {
    final offset = source.indexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    return lint(offset, needle.length) as T;
  }

  T lintForLast<T>(String source, String needle) {
    final offset = source.lastIndexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    return lint(offset, needle.length) as T;
  }

  Future<void> test_directStaticCheck_lint() async {
    const source = r'''
class ModalRoute {
  static bool? isCurrentOf(Object context) => true;
}

bool isVisible(Object context) => ModalRoute.isCurrentOf(context) ?? true;
''';

    await assertDiagnostics(source, [lintFor(source, 'ModalRoute.isCurrentOf(context)')]);
  }

  Future<void> test_directLookupPropertyCheck_lint() async {
    const source = r'''
class ModalRoute {
  static ModalRoute? of(Object context) => ModalRoute();
  bool get isCurrent => true;
}

bool isVisible(Object context) => ModalRoute.of(context)!.isCurrent;
''';

    await assertDiagnostics(source, [lintForLast(source, 'isCurrent')]);
  }

  Future<void> test_localRoutePropertyCheck_lint() async {
    const source = r'''
class ModalRoute {
  static ModalRoute? of(Object context) => ModalRoute();
  bool get isCurrent => true;
}

bool isVisible(Object context) {
  final route = ModalRoute.of(context);
  if (route == null) return true;
  return route.isCurrent;
}
''';

    await assertDiagnostics(source, [lintForLast(source, 'isCurrent')]);
  }

  Future<void> test_nonCurrentModalRouteUse_noLint() async {
    await assertNoDiagnostics(r'''
class RouteSettings {
  const RouteSettings({this.name});
  final String? name;
}

class ModalRoute {
  final settings = const RouteSettings(name: 'home');
  static ModalRoute? of(Object context) => ModalRoute();
}

String? routeName(Object context) {
  final route = ModalRoute.of(context);
  return route?.settings.name;
}
''');
  }

  Future<void> test_contextExtensionOwner_noLint() async {
    final filePath = '$testPackageLibPath/core/extensions/context_extensions.dart';
    newFile(filePath, r'''
class ModalRoute {
  static bool? isCurrentOf(Object context) => true;
}

extension ContextExtensions on Object {
  bool get isCurrentModalRoute {
    final isCurrent = ModalRoute.isCurrentOf(this);
    if (isCurrent == null) return true;
    return isCurrent;
  }
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}
