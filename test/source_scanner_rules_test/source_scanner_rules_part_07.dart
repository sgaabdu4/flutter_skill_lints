// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class DateTimeNowRequiresTimezoneIntentTest extends _UiRuleTest {
  @override
  String get ruleName => 'datetime_now_requires_timezone_intent';
  @override
  String get needle => 'DateTime.now()';
  @override
  String get source => 'final now = DateTime.now();';

  Future<void> test_reportsUtcIntentOutsideExtensionBoundary() async {
    final analyzedSource = _analyzedSource(
      'final savedAt = DateTime.now().toUtc();',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.now()', ruleName),
    ]);
  }

  Future<void> test_reportsTimestampOutsideExtensionBoundary() async {
    final analyzedSource = _analyzedSource(
      'final savedAt = DateTime.timestamp();',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.timestamp()', ruleName),
    ]);
  }

  Future<void> test_reportsLocalIntentAcrossLinesOutsideExtensionBoundary() async {
    final analyzedSource = _analyzedSource(r'''
final today = DateTime.now()
    .toLocal();
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.now()', ruleName),
    ]);
  }

  Future<void> test_allowsDateTimeXNowUtcForPersistedTimestamp() async {
    await assertAllows('final savedAt = DateTimeX.nowUtc();');
  }

  Future<void> test_reportsLocalNowForPersistedTimestamp() async {
    final analyzedSource = _analyzedSource(r'''
class ItemLog {
  const ItemLog({required this.timestamp});
  final Object timestamp;
}

final log = ItemLog(timestamp: DateTimeX.nowLocal());
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> test_reportsMultilineLocalNowForPersistedTimestamp() async {
    final analyzedSource = _analyzedSource(r'''
class ItemLog {
  const ItemLog({required this.timestamp});
  final Object timestamp;
}

final log = ItemLog(
  timestamp:
      DateTimeX.nowLocal(),
);
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> test_reportsDateTimeNowToLocalForPersistedTimestamp() async {
    final analyzedSource = _analyzedSource(r'''
class SquadCheckIn {
  const SquadCheckIn({required this.checkedInAt});
  final Object checkedInAt;
}

final checkIn = SquadCheckIn(checkedInAt: DateTime.now().toLocal());
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.now().toLocal()', ruleName),
    ]);
  }

  Future<void> test_reportsInlineCurrentDayBoundary() async {
    final analyzedSource = _analyzedSource(
      'final today = DateTimeX.nowLocal().startOfDay;',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> test_reportsInlineCurrentUtcDayBoundary() async {
    final analyzedSource = _analyzedSource(
      'final today = DateTimeX.nowUtc().startOfDay;',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowUtc()', ruleName),
    ]);
  }

  Future<void> test_allowsNamedCurrentDayBoundaryHelper() async {
    await assertAllows('final today = DateTimeX.nowLocalStartOfDay();');
  }

  Future<void> test_reportsInlineCurrentDateWindow() async {
    final analyzedSource = _analyzedSource(
      'final since = DateTimeX.nowLocal().daysBefore(60);',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> test_reportsInlineCurrentCalendarDateWindow() async {
    final analyzedSource = _analyzedSource(
      'final since = DateTimeX.nowLocal().calendarDaysBefore(60);',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> test_reportsMultilineInlineCurrentDateWindow() async {
    final analyzedSource = _analyzedSource(r'''
final since = DateTimeX.nowLocal()
    .daysBefore(60);
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> test_reportsInlineCurrentDateWindowFromStartOfDay() async {
    final analyzedSource = _analyzedSource(
      'final cutoff = DateTimeX.nowLocal().startOfDay.daysBefore(30);',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> test_reportsEpochIntentOutsideExtensionBoundary() async {
    final analyzedSource = _analyzedSource(
      'final id = DateTime.now().millisecondsSinceEpoch.toString();',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.now()', ruleName),
    ]);
  }

  Future<void> test_reportsInterpolatedEpochIntentOutsideExtensionBoundary() async {
    final analyzedSource = _analyzedSource(
      r"final id = 'draft-${DateTime.now().millisecondsSinceEpoch}';",
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.now()', ruleName),
    ]);
  }

  Future<void> test_allowsRawStringThatMentionsDateTimeNow() async {
    final analyzedSource = _analyzedSource(
      r"final sample = r'${DateTime.now()}';",
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertNoDiagnostics(analyzedSource);
  }

  Future<void> test_allowsDateTimeXEpochIntent() async {
    await assertAllows('final id = DateTimeX.nowUtc().millisecondsSinceEpoch.toString();');
  }

  Future<void> test_allowsDateTimeExtensionCurrentBoundary() async {
    final filePath = '$testPackageLibPath/core/extensions/date_time_extensions.dart';
    newFile(
      filePath,
      _analyzedSource(r'''
extension DateTimeX on DateTime {
  static DateTime nowUtc() => DateTime.timestamp();
  static DateTime nowLocal() => nowUtc().toLocal();
}
''', addIgnorePrefix: addIgnorePrefix),
    );

    await assertNoDiagnosticsInFile(filePath);
  }

  // Row 27: the skill's canonical DateTimeX (primitive-formatting.md).
  Future<void> test_allowsSkillDateTimeXStaticNowHelpers() async {
    final filePath = '$testPackageLibPath/core/extensions/date_time_extensions.dart';
    newFile(
      filePath,
      _analyzedSource(r'''
extension DateTimeX on DateTime {
  static DateTime nowUtc() => DateTime.now().toUtc();
  static DateTime nowLocal() => DateTime.now();

  DateTime get asLocal => toLocal();
}
''', addIgnorePrefix: addIgnorePrefix),
    );

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsStaticNowOutsideDateTimeExtension() async {
    final filePath = '$testPackageLibPath/core/extensions/date_time_extensions.dart';
    final analyzedSource = _analyzedSource(r'''
extension StringClockX on String {
  static DateTime stringNow() => DateTime.now();
}

abstract final class Clock {
  static DateTime classNow() {
    return DateTime.now();
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(filePath, analyzedSource);

    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, 'DateTime.now();\n}\n\nabstract', ruleName),
      compatLint(analyzedSource, 'DateTime.now();\n  }', ruleName),
    ]);
  }

  Future<void> test_reportsRawNowInsideDateTimeExtensionHelper() async {
    final filePath = '$testPackageLibPath/core/extensions/date_time_extensions.dart';
    final analyzedSource = _analyzedSource(r'''
extension DateTimeExtensions on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return identical(now, now);
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(filePath, analyzedSource);

    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, 'DateTime.now()', ruleName),
    ]);
  }

  Future<void> test_allowsTests() async {
    final filePath = '$testPackageRootPath/test/widgets/date_time_test.dart';
    newFile(
      filePath,
      _analyzedSource('final now = DateTime.now();', addIgnorePrefix: addIgnorePrefix),
    );

    await assertNoDiagnosticsInFile(filePath);
  }
}

// primitive-formatting.md:33/:60: ad-hoc DateFormat/NumberFormat is forbidden
// at call sites; the DateTimeX/NumX extensions own intl formatting.
@reflectiveTest
final class AdHocIntlFormatTest extends _UiRuleTest {
  @override
  void setUp() {
    newPackage('intl').addFile('lib/intl.dart', r'''
class DateFormat {
  DateFormat([String? pattern, String? locale]);
  DateFormat.yMMMd([String? locale]);
  String format(DateTime date) => '';
}
class NumberFormat {
  NumberFormat([String? pattern, String? locale]);
  factory NumberFormat.currency({String? locale, String? symbol}) => NumberFormat();
  String format(Object number) => '';
}
''');
    super.setUp();
  }

  @override
  String get ruleName => 'ad_hoc_intl_format';
  @override
  String get needle => "DateFormat('yyyy-MM-dd')";
  @override
  String get path => '$testPackageLibPath/features/orders/presentation/widgets/order_row.dart';
  @override
  String get source => r'''
import 'package:intl/intl.dart';

String placedLabel(DateTime placedAt) => DateFormat('yyyy-MM-dd').format(placedAt);
''';

  Future<void> test_reportsNumberFormatInWidgetMethod() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:intl/intl.dart';

final class OrderRow {
  String priceLabel(double price) => NumberFormat.currency(locale: 'en', symbol: r'$').format(price);
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'NumberFormat.currency(', ruleName),
    ]);
  }

  Future<void> test_reportsDateFormatInNonPrimitiveExtension() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:intl/intl.dart';

final class Order {
  const Order(this.placedAt);
  final DateTime placedAt;
}

extension OrderX on Order {
  String get placedLabel => DateFormat.yMMMd().format(placedAt);
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'DateFormat.yMMMd()', ruleName),
    ]);
  }

  Future<void> test_allowsSkillPrimitiveExtensions() async {
    await assertAllows(r'''
import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  String formatShortDate(AppLocalizations l10n) {
    return DateFormat.yMMMd(l10n.localeName).format(toLocal());
  }
}

extension NumX on num {
  String asCurrency(AppLocalizations l10n, {String? symbol}) {
    return NumberFormat.currency(locale: l10n.localeName, symbol: symbol).format(this);
  }
}
''', path: '$testPackageLibPath/core/extensions/primitive_extensions.dart');
  }

  Future<void> test_allowsNonIntlFormatter() async {
    await assertAllows(r'''
final class DateFormat {
  const DateFormat(String pattern);
}

const isoDate = DateFormat('yyyy-MM-dd');
''', path: path);
  }

  Future<void> test_allowsTests() async {
    await assertAllows(r'''
import 'package:intl/intl.dart';

String expectedLabel(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
''', path: '$testPackageRootPath/test/features/orders/order_row_test.dart');
  }
}

// primitive-formatting.md:60: inline `.clamp(...)` is forbidden at call sites;
// NumX.clamped owns it.
@reflectiveTest
final class InlineNumClampTest extends _UiRuleTest {
  @override
  String get ruleName => 'inline_num_clamp';
  @override
  String get needle => 'clamp(0, 10)';
  @override
  String get path => '$testPackageLibPath/features/cart/presentation/widgets/cart_badge.dart';
  @override
  String get source => 'int visibleCount(int count) => count.clamp(0, 10);';

  // lists-forms-workflows.md:258 shows this batch bound; :60 forbids it.
  Future<void> test_reportsBatchBoundClamp() async {
    final analyzedSource = _analyzedSource(r'''
Iterable<List<T>> batches<T>(List<T> items, int batchSize) sync* {
  for (var i = 0; i < items.length; i += batchSize) {
    final end = (i + batchSize).clamp(0, items.length);
    yield items.sublist(i, end);
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    final filePath = '$testPackageLibPath/core/utils/batch_utils.dart';
    newFile(filePath, analyzedSource);

    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, 'clamp(0, items.length)', ruleName),
    ]);
  }

  Future<void> test_allowsSkillNumExtension() async {
    await assertAllows(r'''
extension NumX on num {
  num clamped(num min, num max) => clamp(min, max);
}
''', path: '$testPackageLibPath/core/extensions/num_extensions.dart');
  }

  Future<void> test_allowsNonNumClamp() async {
    await assertAllows(r'''
final class TextScaler {
  const TextScaler();
  TextScaler clamp({double maxScaleFactor = 1}) => this;
}

TextScaler bounded(TextScaler scaler) => scaler.clamp(maxScaleFactor: 2);
''', path: path);
  }

  Future<void> test_allowsTests() async {
    await assertAllows(
      'final bounded = 12.clamp(0, 10);',
      path: '$testPackageRootPath/test/features/cart/cart_badge_test.dart',
    );
  }
}

@reflectiveTest
final class PerfBuildWorkTest extends _UiRuleTest {
  @override
  String get ruleName => 'perf_build_work';
  @override
  String get needle => 'items.sort()';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
import 'package:flutter/widgets.dart';

class Screen extends Widget {
  Widget build(BuildContext context) {
    final items = <int>[2, 1];
    items.sort();
    return Widget();
  }
}
''';

  // performance.md:289 WRONG "sorts on every rebuild", in a State build and
  // in a `Widget build(BuildContext ...)` on a custom view base class.
  Future<void> test_reportsSkillSortInWidgetAndStateBuild() async {
    final source = _analyzedSource(r'''
import 'package:flutter/widgets.dart';

class Product {
  const Product(this.name);
  final String name;
}

class ProductsScreen extends StatefulWidget {}

class ProductsScreenState extends State<ProductsScreen> {
  List<Product> items = const [];

  Widget build(BuildContext context) {
    final sorted = items.toList()..sort((a, b) => a.name.compareTo(b.name));
    return Widget();
  }
}

abstract class AppView {}

class ProductsView extends AppView {
  Widget build(BuildContext context, List<Product> items) {
    final ordered = items.toList()..sort((a, b) => a.name.compareTo(b.name));
    return Widget();
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(source, [
      compatLint(source, 'final sorted', ruleName, lineStart: true),
      compatLint(source, 'final ordered', ruleName, lineStart: true),
    ]);
  }

  // riverpod-codegen.md:335-346: a Riverpod Notifier build computes provider
  // state, where performance.md:5 sends collection work.
  Future<void> test_allowsNotifierBuild() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Todo {
  Todo.fromJson(Map<String, Object?> json);
}

abstract class _$TodosNotifier {}

@Riverpod(keepAlive: true)
class TodosNotifier extends _$TodosNotifier {
  List<Todo> build() {
    final decoded = <Object?>[];
    return decoded.map((item) => Todo.fromJson(item as Map<String, Object?>)).toList();
  }
}
''', path: '$testPackageLibPath/features/todos/presentation/notifiers/todos_notifier.dart');
  }
}

@reflectiveTest
final class PerfListviewChildrenTest extends _UiRuleTest {
  @override
  String get ruleName => 'perf_listview_children';
  @override
  String get needle => 'ListView(children';
  @override
  String get source => r'''
class ListView {
  ListView({List<Object> children = const []});
}
ListView list(List<String> items) => ListView(children: items.map((item) => item).toList());
''';

  Future<void> test_reportsWrappedDynamicChildren() async {
    final analyzedSource = _analyzedSource(r'''
class ListView {
  ListView({List<Object> children = const []});
}
ListView list(List<String> items) => ListView(
  children: [for (final item in items) item],
);
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'ListView(\n', ruleName)]);
  }

  Future<void> test_allowsStaticChildren() async {
    await assertAllows(r'''
class ListView {
  ListView({List<Object> children = const []});
}
const header = 'header';
ListView list() => ListView(children: const ['a', 'b']);
ListView other() => ListView(children: [header, if (header.isEmpty) 'empty']);
''');
  }
}
