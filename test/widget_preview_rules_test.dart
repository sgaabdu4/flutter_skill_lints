import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/widget_preview_rules.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_WidgetPreviewImportLeakTest>(
    'WidgetPreviewImportLeakTest',
    _WidgetPreviewImportLeakTest.new,
    _WidgetPreviewImportLeakTest._allCases,
  );
  analysisRuleSuite<_WidgetPreviewPlatformDependencyTest>(
    'WidgetPreviewPlatformDependencyTest',
    _WidgetPreviewPlatformDependencyTest.new,
    _WidgetPreviewPlatformDependencyTest._allCases,
  );
  analysisRuleSuite<_WidgetPreviewScreenTest>(
    'WidgetPreviewScreenTest',
    _WidgetPreviewScreenTest.new,
    _WidgetPreviewScreenTest._allCases,
  );
}

abstract class _WidgetPreviewRuleTest extends AnalysisRuleTest {
  String get widgetsPath => '$testPackageLibPath/features/orders/presentation/widgets';

  @override
  void setUp() {
    newPackage('flutter')
      ..addFile('lib/widgets.dart', r'''
class BuildContext {}
class Widget {
  const Widget();
}
abstract class StatelessWidget extends Widget {
  const StatelessWidget();
  Widget build(BuildContext context);
}
abstract class State<T> {}
''')
      ..addFile('lib/widget_previews.dart', r'''
base class Preview {
  const Preview({String? name});
}
''')
      ..addFile('lib/services.dart', r'''
export 'src/services/platform_channel.dart';
''')
      ..addFile('lib/src/services/platform_channel.dart', r'''
class MethodChannel {
  const MethodChannel(String name);
  Future<T?> invokeMethod<T>(String method) async => null;
}
''');
    newPackage('dio').addFile('lib/dio.dart', r'''
class Dio {
  Future<void> get(String path) async {}
}
''');
    newPackage('hive_ce').addFile('lib/hive.dart', r'''
class Box<T> {
  int get length => 0;
}
abstract final class Hive {
  static Box<T> box<T>(String name) => Box<T>();
}
''');
    super.setUp();
  }

  Future<void> assertFileDiagnostics(String path, String source, List<String> needles) async {
    newFile(path, source);
    await assertDiagnosticsInFile(path, [
      for (final needle in needles) lint(source.indexOf(needle), needle.length),
    ]);
  }
}

final class _WidgetPreviewImportLeakTest extends _WidgetPreviewRuleTest {
  static Map<String, Future<void> Function(_WidgetPreviewImportLeakTest)> get _allCases =>
      caseSet<_WidgetPreviewImportLeakTest>(
        parent: const {},
        own: {
          'test_severityIsError': (t) => t._severityIsError(),
          'test_allowsPreviewOnlyFile': (t) => t._allowsPreviewOnlyFile(),
          'test_reportsImportInProductionWidgetFile': (t) =>
              t._reportsImportInProductionWidgetFile(),
          'test_reportsPreviewNextToProductionWidget': (t) =>
              t._reportsPreviewNextToProductionWidget(),
        },
      );

  @override
  void setUp() {
    rule = WidgetPreviewImportLeak();
    super.setUp();
  }

  Future<void> _severityIsError() async {
    expect(WidgetPreviewImportLeak.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> _allowsPreviewOnlyFile() async {
    final path = '$widgetsPath/order_card_preview.dart';
    newFile(path, r'''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

@Preview(name: 'Order card')
Widget orderCardPreview() => const Widget();
''');

    await assertNoDiagnosticsInFile(path);
  }

  Future<void> _reportsImportInProductionWidgetFile() async {
    await assertFileDiagnostics(
      '$widgetsPath/order_card.dart',
      r'''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

class OrderCard extends StatelessWidget {
  const OrderCard();

  static const preview = Preview(name: 'leak');

  @override
  Widget build(BuildContext context) => const Widget();
}
''',
      ["'package:flutter/widget_previews.dart'"],
    );
  }

  Future<void> _reportsPreviewNextToProductionWidget() async {
    await assertFileDiagnostics(
      '$widgetsPath/order_card.dart',
      r'''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

class OrderCard extends StatelessWidget {
  const OrderCard();

  @override
  Widget build(BuildContext context) => const Widget();
}

@Preview(name: 'Order card')
Widget orderCardPreview() => const OrderCard();
''',
      ["'package:flutter/widget_previews.dart'"],
    );
  }
}

final class _WidgetPreviewPlatformDependencyTest extends _WidgetPreviewRuleTest {
  static Map<String, Future<void> Function(_WidgetPreviewPlatformDependencyTest)> get _allCases =>
      caseSet<_WidgetPreviewPlatformDependencyTest>(
        parent: const {},
        own: {
          'test_severityIsError': (t) => t._severityIsError(),
          'test_reportsIoHiveDioAndChannels': (t) => t._reportsIoHiveDioAndChannels(),
          'test_allowsFakesInPreview': (t) => t._allowsFakesInPreview(),
          'test_allowsPlatformUseOutsidePreview': (t) => t._allowsPlatformUseOutsidePreview(),
        },
      );

  @override
  void setUp() {
    rule = WidgetPreviewPlatformDependency();
    super.setUp();
  }

  Future<void> _severityIsError() async {
    expect(WidgetPreviewPlatformDependency.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> _reportsIoHiveDioAndChannels() async {
    await assertFileDiagnostics(
      '$widgetsPath/order_card_preview.dart',
      r'''
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_ce/hive.dart';

@Preview(name: 'Order card')
Widget orderCardPreview() {
  final exists = File('x.txt').existsSync();
  final box = Hive.box<String>('orders');
  Dio().get('https://example.com');
  const MethodChannel('orders').invokeMethod<void>('load');
  return Widget();
}
''',
      ['File', 'Hive', 'Dio', 'MethodChannel'],
    );
  }

  Future<void> _allowsFakesInPreview() async {
    final path = '$widgetsPath/order_card_preview.dart';
    newFile(path, r'''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

class FakeOrderRepository {
  const FakeOrderRepository();
}

@Preview(name: 'Order card')
Widget orderCardPreview() {
  const repository = FakeOrderRepository();
  return const Widget();
}
''');

    await assertNoDiagnosticsInFile(path);
  }

  Future<void> _allowsPlatformUseOutsidePreview() async {
    final path = '$testPackageLibPath/features/orders/data/order_datasource.dart';
    newFile(path, r'''
import 'package:dio/dio.dart';

class OrderDatasource {
  Future<void> load() => Dio().get('/orders');
}
''');

    await assertNoDiagnosticsInFile(path);
  }
}

final class _WidgetPreviewScreenTest extends _WidgetPreviewRuleTest {
  static Map<String, Future<void> Function(_WidgetPreviewScreenTest)> get _allCases =>
      caseSet<_WidgetPreviewScreenTest>(
        parent: const {},
        own: {
          'test_severityIsError': (t) => t._severityIsError(),
          'test_reportsPreviewDeclaredInScreensLibrary': (t) =>
              t._reportsPreviewDeclaredInScreensLibrary(),
          'test_reportsPreviewConstructingScreen': (t) => t._reportsPreviewConstructingScreen(),
          'test_allowsPreviewOfPresentationWidget': (t) => t._allowsPreviewOfPresentationWidget(),
        },
      );

  String get screenPath =>
      '$testPackageLibPath/features/orders/presentation/screens/orders_screen.dart';

  @override
  void setUp() {
    rule = WidgetPreviewScreen();
    super.setUp();
  }

  Future<void> _severityIsError() async {
    expect(WidgetPreviewScreen.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> _reportsPreviewDeclaredInScreensLibrary() async {
    await assertFileDiagnostics(
      screenPath,
      r'''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen();

  @override
  Widget build(BuildContext context) => const Widget();
}

@Preview(name: 'Orders screen')
Widget ordersScreenPreview() => const OrdersScreen();
''',
      ["@Preview(name: 'Orders screen')"],
    );
  }

  Future<void> _reportsPreviewConstructingScreen() async {
    newFile(screenPath, r'''
import 'package:flutter/widgets.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen();

  @override
  Widget build(BuildContext context) => const Widget();
}
''');

    await assertFileDiagnostics(
      '$widgetsPath/orders_screen_preview.dart',
      r'''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:test/features/orders/presentation/screens/orders_screen.dart';

@Preview(name: 'Orders screen')
Widget ordersScreenPreview() => const OrdersScreen();
''',
      ['OrdersScreen'],
    );
  }

  Future<void> _allowsPreviewOfPresentationWidget() async {
    newFile('$widgetsPath/order_card.dart', r'''
import 'package:flutter/widgets.dart';

class OrderCard extends StatelessWidget {
  const OrderCard();

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
    final path = '$widgetsPath/order_card_preview.dart';
    newFile(path, r'''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:test/features/orders/presentation/widgets/order_card.dart';

@Preview(name: 'Order card')
Widget orderCardPreview() => const OrderCard();
''');

    await assertNoDiagnosticsInFile(path);
  }
}
