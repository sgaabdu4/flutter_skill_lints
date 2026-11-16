part of '../source_scanner_rules_test.dart';

final class DateTimeNowRequiresTimezoneIntentTest extends _UiRuleTest {
  @override
  String get ruleName => 'datetime_now_requires_timezone_intent';
  @override
  String get needle => 'DateTime.now()';
  @override
  String get source => 'final now = DateTime.now();';

  Future<void> _reportsUtcIntentOutsideExtensionBoundary() async {
    final analyzedSource = _analyzedSource(
      'final savedAt = DateTime.now().toUtc();',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.now()', ruleName),
    ]);
  }

  Future<void> _reportsTimestampOutsideExtensionBoundary() async {
    final analyzedSource = _analyzedSource(
      'final savedAt = DateTime.timestamp();',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.timestamp()', ruleName),
    ]);
  }

  Future<void> _reportsLocalIntentAcrossLinesOutsideExtensionBoundary() async {
    final analyzedSource = _analyzedSource(r'''
final today = DateTime.now()
    .toLocal();
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.now()', ruleName),
    ]);
  }

  Future<void> _allowsDateTimeXNowUtcForPersistedTimestamp() async {
    await assertAllows('final savedAt = DateTimeX.nowUtc();');
  }

  Future<void> _reportsLocalNowForPersistedTimestamp() async {
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

  Future<void> _reportsMultilineLocalNowForPersistedTimestamp() async {
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

  Future<void> _reportsDateTimeNowToLocalForPersistedTimestamp() async {
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

  Future<void> _reportsInlineCurrentDayBoundary() async {
    final analyzedSource = _analyzedSource(
      'final today = DateTimeX.nowLocal().startOfDay;',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> _reportsInlineCurrentUtcDayBoundary() async {
    final analyzedSource = _analyzedSource(
      'final today = DateTimeX.nowUtc().startOfDay;',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowUtc()', ruleName),
    ]);
  }

  Future<void> _allowsNamedCurrentDayBoundaryHelper() async {
    await assertAllows('final today = DateTimeX.nowLocalStartOfDay();');
  }

  Future<void> _reportsInlineCurrentDateWindow() async {
    final analyzedSource = _analyzedSource(
      'final since = DateTimeX.nowLocal().daysBefore(60);',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> _reportsInlineCurrentCalendarDateWindow() async {
    final analyzedSource = _analyzedSource(
      'final since = DateTimeX.nowLocal().calendarDaysBefore(60);',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> _reportsMultilineInlineCurrentDateWindow() async {
    final analyzedSource = _analyzedSource(r'''
final since = DateTimeX.nowLocal()
    .daysBefore(60);
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> _reportsInlineCurrentDateWindowFromStartOfDay() async {
    final analyzedSource = _analyzedSource(
      'final cutoff = DateTimeX.nowLocal().startOfDay.daysBefore(30);',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> _reportsEpochIntentOutsideExtensionBoundary() async {
    final analyzedSource = _analyzedSource(
      'final id = DateTime.now().millisecondsSinceEpoch.toString();',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.now()', ruleName),
    ]);
  }

  Future<void> _reportsInterpolatedEpochIntentOutsideExtensionBoundary() async {
    final analyzedSource = _analyzedSource(
      r"final id = 'draft-${DateTime.now().millisecondsSinceEpoch}';",
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.now()', ruleName),
    ]);
  }

  Future<void> _allowsRawStringThatMentionsDateTimeNow() async {
    final analyzedSource = _analyzedSource(
      r"final sample = r'${DateTime.now()}';",
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertNoDiagnostics(analyzedSource);
  }

  Future<void> _allowsDateTimeXEpochIntent() async {
    await assertAllows('final id = DateTimeX.nowUtc().millisecondsSinceEpoch.toString();');
  }

  Future<void> _allowsDateTimeExtensionCurrentBoundary() async {
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
  Future<void> _allowsSkillDateTimeXStaticNowHelpers() async {
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

  Future<void> _reportsStaticNowOutsideDateTimeExtension() async {
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

  Future<void> _reportsRawNowInsideDateTimeExtensionHelper() async {
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

  Future<void> _allowsTests() async {
    final filePath = '$testPackageRootPath/test/widgets/date_time_test.dart';
    newFile(
      filePath,
      _analyzedSource('final now = DateTime.now();', addIgnorePrefix: addIgnorePrefix),
    );

    await assertNoDiagnosticsInFile(filePath);
  }
}

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

  Future<void> _reportsNumberFormatInWidgetMethod() async {
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

  Future<void> _reportsDateFormatInNonPrimitiveExtension() async {
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

  Future<void> _allowsSkillPrimitiveExtensions() async {
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

  Future<void> _allowsNonIntlFormatter() async {
    await assertAllows(r'''
final class DateFormat {
  const DateFormat(String pattern);
}

const isoDate = DateFormat('yyyy-MM-dd');
''', path: path);
  }

  Future<void> _allowsTests() async {
    await assertAllows(r'''
import 'package:intl/intl.dart';

String expectedLabel(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
''', path: '$testPackageRootPath/test/features/orders/order_row_test.dart');
  }
}

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
  Future<void> _reportsBatchBoundClamp() async {
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

  Future<void> _allowsSkillNumExtension() async {
    await assertAllows(r'''
extension NumX on num {
  num clamped(num min, num max) => clamp(min, max);
}
''', path: '$testPackageLibPath/core/extensions/num_extensions.dart');
  }

  Future<void> _allowsNonNumClamp() async {
    await assertAllows(r'''
final class TextScaler {
  const TextScaler();
  TextScaler clamp({double maxScaleFactor = 1}) => this;
}

TextScaler bounded(TextScaler scaler) => scaler.clamp(maxScaleFactor: 2);
''', path: path);
  }

  Future<void> _allowsTests() async {
    await assertAllows(
      'final bounded = 12.clamp(0, 10);',
      path: '$testPackageRootPath/test/features/cart/cart_badge_test.dart',
    );
  }
}

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

  Future<void> _reportsSkillSortInWidgetAndStateBuild() async {
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

  Future<void> _allowsNotifierBuild() async {
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

  Future<void> _reportsWrappedDynamicChildren() async {
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

  Future<void> _allowsStaticChildren() async {
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

void _defineSourceScannerRulesPart07Tests() {
  analysisRuleSuite<DateTimeNowRequiresTimezoneIntentTest>(
    'DateTimeNowRequiresTimezoneIntentTest',
    DateTimeNowRequiresTimezoneIntentTest.new,
    {
      'test_reportsUtcIntentOutsideExtensionBoundary': (t) =>
          t._reportsUtcIntentOutsideExtensionBoundary(),
      'test_reportsTimestampOutsideExtensionBoundary': (t) =>
          t._reportsTimestampOutsideExtensionBoundary(),
      'test_reportsLocalIntentAcrossLinesOutsideExtensionBoundary': (t) =>
          t._reportsLocalIntentAcrossLinesOutsideExtensionBoundary(),
      'test_allowsDateTimeXNowUtcForPersistedTimestamp': (t) =>
          t._allowsDateTimeXNowUtcForPersistedTimestamp(),
      'test_reportsLocalNowForPersistedTimestamp': (t) => t._reportsLocalNowForPersistedTimestamp(),
      'test_reportsMultilineLocalNowForPersistedTimestamp': (t) =>
          t._reportsMultilineLocalNowForPersistedTimestamp(),
      'test_reportsDateTimeNowToLocalForPersistedTimestamp': (t) =>
          t._reportsDateTimeNowToLocalForPersistedTimestamp(),
      'test_reportsInlineCurrentDayBoundary': (t) => t._reportsInlineCurrentDayBoundary(),
      'test_reportsInlineCurrentUtcDayBoundary': (t) => t._reportsInlineCurrentUtcDayBoundary(),
      'test_allowsNamedCurrentDayBoundaryHelper': (t) => t._allowsNamedCurrentDayBoundaryHelper(),
      'test_reportsInlineCurrentDateWindow': (t) => t._reportsInlineCurrentDateWindow(),
      'test_reportsInlineCurrentCalendarDateWindow': (t) =>
          t._reportsInlineCurrentCalendarDateWindow(),
      'test_reportsMultilineInlineCurrentDateWindow': (t) =>
          t._reportsMultilineInlineCurrentDateWindow(),
      'test_reportsInlineCurrentDateWindowFromStartOfDay': (t) =>
          t._reportsInlineCurrentDateWindowFromStartOfDay(),
      'test_reportsEpochIntentOutsideExtensionBoundary': (t) =>
          t._reportsEpochIntentOutsideExtensionBoundary(),
      'test_reportsInterpolatedEpochIntentOutsideExtensionBoundary': (t) =>
          t._reportsInterpolatedEpochIntentOutsideExtensionBoundary(),
      'test_allowsRawStringThatMentionsDateTimeNow': (t) =>
          t._allowsRawStringThatMentionsDateTimeNow(),
      'test_allowsDateTimeXEpochIntent': (t) => t._allowsDateTimeXEpochIntent(),
      'test_allowsDateTimeExtensionCurrentBoundary': (t) =>
          t._allowsDateTimeExtensionCurrentBoundary(),
      'test_allowsSkillDateTimeXStaticNowHelpers': (t) => t._allowsSkillDateTimeXStaticNowHelpers(),
      'test_reportsStaticNowOutsideDateTimeExtension': (t) =>
          t._reportsStaticNowOutsideDateTimeExtension(),
      'test_reportsRawNowInsideDateTimeExtensionHelper': (t) =>
          t._reportsRawNowInsideDateTimeExtensionHelper(),
      'test_allowsTests': (t) => t._allowsTests(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<AdHocIntlFormatTest>('AdHocIntlFormatTest', AdHocIntlFormatTest.new, {
    'test_reportsNumberFormatInWidgetMethod': (t) => t._reportsNumberFormatInWidgetMethod(),
    'test_reportsDateFormatInNonPrimitiveExtension': (t) =>
        t._reportsDateFormatInNonPrimitiveExtension(),
    'test_allowsSkillPrimitiveExtensions': (t) => t._allowsSkillPrimitiveExtensions(),
    'test_allowsNonIntlFormatter': (t) => t._allowsNonIntlFormatter(),
    'test_allowsTests': (t) => t._allowsTests(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<InlineNumClampTest>('InlineNumClampTest', InlineNumClampTest.new, {
    'test_reportsBatchBoundClamp': (t) => t._reportsBatchBoundClamp(),
    'test_allowsSkillNumExtension': (t) => t._allowsSkillNumExtension(),
    'test_allowsNonNumClamp': (t) => t._allowsNonNumClamp(),
    'test_allowsTests': (t) => t._allowsTests(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<PerfBuildWorkTest>('PerfBuildWorkTest', PerfBuildWorkTest.new, {
    'test_reportsSkillSortInWidgetAndStateBuild': (t) => t._reportsSkillSortInWidgetAndStateBuild(),
    'test_allowsNotifierBuild': (t) => t._allowsNotifierBuild(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<PerfListviewChildrenTest>(
    'PerfListviewChildrenTest',
    PerfListviewChildrenTest.new,
    {
      'test_reportsWrappedDynamicChildren': (t) => t._reportsWrappedDynamicChildren(),
      'test_allowsStaticChildren': (t) => t._allowsStaticChildren(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
}
