// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_magic_literals.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidMagicLiteralsTest);
  });
}

@reflectiveTest
final class AvoidMagicLiteralsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPreviewPackage();
    rule = AvoidMagicLiterals();
    super.setUp();
  }

  void _addFlutterPreviewPackage() {
    newPackage('flutter')
      ..addFile('lib/widget_previews.dart', r'''
base class Preview {
  const Preview({String? name, double? textScaleFactor});
}

abstract base class MultiPreview {
  const MultiPreview();
  List<Preview> get previews;
}
''')
      ..addFile('lib/widgets.dart', r'''
class RouteSettings {
  const RouteSettings({String? name, Object? arguments});
}
''');
  }

  static const _productPreviewBody = r'''
class Product {
  const Product({required this.id, required this.price});
  final String id;
  final int price;
}

class ProductCard {
  const ProductCard({required this.productId, required this.products});
  final String productId;
  final List<Product> products;
}
''';

  Future<void> test_severityIsError() async {
    expect(AvoidMagicLiterals.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> test_allowsSampleDataInsideResolvedPreviewFunction() async {
    await assertNoDiagnostics('''
import 'package:flutter/widget_previews.dart';

$_productPreviewBody
@Preview(name: 'Product card - in stock')
ProductCard productCardInStockPreview() {
  return ProductCard(
    productId: 'preview-1',
    products: [Product(id: 'preview-1', price: 24)],
  );
}
''');
  }

  Future<void> test_allowsSampleDataInsideResolvedPreviewMethodAndConstructor() async {
    await assertNoDiagnostics('''
import 'package:flutter/widget_previews.dart';

$_productPreviewBody
class ProductCardPreviews {
  @Preview(name: 'Static')
  static ProductCard staticPreview() => ProductCard(
    productId: 'preview-1',
    products: [Product(id: 'preview-1', price: 24)],
  );
}

class ProductCardSample extends ProductCard {
  @Preview(name: 'Constructor')
  ProductCardSample() : super(productId: 'preview-2', products: [Product(id: 'preview-2', price: 36)]);
}
''');
  }

  Future<void> test_reportsBoundaryLiteralInsideMultiPreviewClass() async {
    const source = r'''
import 'package:flutter/widget_previews.dart';

final class TextScalePreviews extends MultiPreview {
  const TextScalePreviews();

  static const _scales = {'large': 2.0, 'huge': 3.0};

  @override
  List<Preview> get previews => [
    Preview(name: 'Large', textScaleFactor: 2.5),
    Preview(name: 'Huge', textScaleFactor: _scales['huge']),
  ];
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("_scales['huge']") + '_scales['.length, "'huge'".length),
    ]);
  }

  Future<void> test_reportsSampleDataUnderLookalikePreviewAnnotation() async {
    const source =
        '''
class Preview {
  const Preview({String? name});
}

$_productPreviewBody
@Preview(name: 'Product card - in stock')
ProductCard productCardInStockPreview() {
  return ProductCard(
    productId: 'preview-1',
    products: [Product(id: 'preview-3', price: 24)],
  );
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'preview-1'"), "'preview-1'".length),
      lint(source.indexOf("'preview-3'"), "'preview-3'".length),
    ]);
  }

  Future<void> test_reportsSampleDataOutsidePreview() async {
    const source =
        '''
$_productPreviewBody
ProductCard productCard() {
  return ProductCard(
    productId: 'preview-1',
    products: [Product(id: 'preview-3', price: 24)],
  );
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'preview-1'"), "'preview-1'".length),
      lint(source.indexOf("'preview-3'"), "'preview-3'".length),
    ]);
  }

  Future<void> test_reportsRawNumberLiteral() async {
    const source = r'''
class RecentSessions {
  void take(int count) {}
}

void recent(RecentSessions values) => values.take(60);
''';

    await assertDiagnostics(source, [lint(source.indexOf('60'), 2)]);
  }

  Future<void> test_reportsNumericComparisonBoundaries() async {
    const source = r'''
bool isKilometer(double distanceMeters) => distanceMeters >= 1000;
bool isLastCalendarRow(int row) => row < 6;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('1000'), 4),
      lint(source.indexOf('6'), 1),
    ]);
  }

  Future<void> test_allowsStatusCodeComparisonsForDedicatedRule() async {
    await assertNoDiagnostics(r'''
bool notFound(int? code) => code == 404;
bool failed(Response response) => response.statusCode >= 500;

class Response {
  Response(this.statusCode);

  final int statusCode;
}
''');
  }

  Future<void> test_reportsGeneratedLiteralAppeasementConstants() async {
    const source = r'''
const int _kInt_404 = 404;
const String _kStringActiveWorkout = 'active-workout';
const int analyticsText35 = 35;
const int calendarRows6 = 6;
final retryDelayMs250 = 250;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('_kInt_404'), '_kInt_404'.length),
      lint(source.indexOf('_kStringActiveWorkout'), '_kStringActiveWorkout'.length),
      lint(source.indexOf('analyticsText35'), 'analyticsText35'.length),
      lint(source.indexOf('calendarRows6'), 'calendarRows6'.length),
      lint(source.indexOf('retryDelayMs250'), 'retryDelayMs250'.length),
    ]);
  }

  Future<void> test_allowsVersionAndProtocolNumbersInNames() async {
    await assertNoDiagnostics(r'''
const int apiV2 = 2;
const int headingH2Level = 2;
const int utf8BitsPerByte = 8;
const int sha256Bits = 256;
''');
  }

  Future<void> test_allowsDedicatedErrorCodeOwnerClasses() async {
    await assertNoDiagnostics(r'''
abstract final class AppwriteErrorCodes {
  static const int tooManyRequests429 = 429;
  static const int serviceUnavailable503 = 503;
  static const int notFound404 = 404;
}
''');
  }

  Future<void> test_allowsDedicatedErrorCodeOwnerFiles() async {
    final filePath = '$testPackageLibPath/core/services/appwrite_error_codes.dart';
    newFile(filePath, r'''
abstract final class AppwriteCodes {
  static const int tooManyRequests429 = 429;
  static const int serviceUnavailable503 = 503;
  static const int notFound404 = 404;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsCommonNumericSentinelComparisons() async {
    await assertNoDiagnostics(r'''
bool hasDistance(double distanceMeters) => distanceMeters > 0;
bool hasPrevious(int index) => index > -1;
bool hasSingleItem(int count) => count == 1;
''');
  }

  Future<void> test_reportsRawStringLiteral() async {
    const source = r'''
Object? read(Map<String, Object?> data) => data['active-workout'];
''';

    await assertDiagnostics(source, [lint(source.indexOf("'active-workout'"), 16)]);
  }

  Future<void> test_allowsUserFeedbackThroughWidgetCallbacks() async {
    await assertNoDiagnostics(r'''
class Widget {
  void Function(String) onError = (_) {};
  void Function(String) onSuccess = (_) {};
}
void save(Widget widget) {
  widget.onError('Please choose a time first');
  widget.onSuccess('Schedule saved successfully');
}
''');
  }

  Future<void> test_reportsProtocolHeaderKeyBesideCallbackProse() async {
    const source = r'''
class Widget { void Function(String) onError = (_) {}; }
void save(Widget widget, Map<String, String> headers) {
  widget.onError('Please choose a time first');
  headers['Authorization'] = 'token';
}
''';
    await assertDiagnostics(source, [
      lint(source.indexOf("'Authorization'"), "'Authorization'".length),
    ]);
  }

  Future<void> test_reportsInlineDateFormatPatternArgument() async {
    const source = r'''
class DateLike {
  String formatted({required String pattern}) => pattern;
}

String label(DateLike timestamp) => timestamp.formatted(pattern: 'MM/dd');
''';

    await assertDiagnostics(source, [lint(source.indexOf("'MM/dd'"), 7)]);
  }

  Future<void> test_reportsInlineDateFormatConstructorPattern() async {
    const source = r'''
class DateFormat {
  DateFormat(String pattern);
}

DateFormat formatter() => DateFormat('MM/dd');
''';

    await assertDiagnostics(source, [lint(source.indexOf("'MM/dd'"), 7)]);
  }

  Future<void> test_reportsNamedDateFormatPatternReference() async {
    const source = r'''
const memberHistoryDatePattern = 'MM/dd';

class DateLike {
  String formatted({required String pattern}) => pattern;
}

String label(DateLike timestamp) => timestamp.formatted(pattern: memberHistoryDatePattern);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('memberHistoryDatePattern);'), 'memberHistoryDatePattern'.length),
    ]);
  }

  Future<void> test_reportsNamedDateFormatConstructorPatternReference() async {
    const source = r'''
const memberHistoryDatePattern = 'MM/dd';

class DateFormat {
  DateFormat(String pattern);
}

DateFormat formatter() => DateFormat(memberHistoryDatePattern);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('memberHistoryDatePattern);'), 'memberHistoryDatePattern'.length),
    ]);
  }

  Future<void> test_reportsStringInterpolationWithRawText() async {
    const source = r'''
class File {
  const File(String path);
}

File makeFile(String base, String name) => File('$base/$name');
''';

    await assertDiagnostics(source, [lint(source.indexOf(r"'$base/"), 13)]);
  }

  Future<void> test_allowsNamedConstDefinitionsAndReferences() async {
    await assertNoDiagnostics(r'''
const maxRecentSessions = 60;
const activeWorkoutKey = 'active-workout';

class RecentSessions {
  void take(int count) {}
}

void recent(RecentSessions values) => values.take(maxRecentSessions);

void track(Object value) {}

void save() {
  track(activeWorkoutKey);
}
''');
  }

  Future<void> test_allowsCommonSentinelNumbers() async {
    await assertNoDiagnostics(r'''
void use(Object value) {}

void update() {
  use(-1);
  use(0);
  use(1);
}
''');
  }

  Future<void> test_allowsImportsAndAnnotations() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

Timer? timer;

class Route {
  const Route({required String path});
}

@Route(path: '/home')
class HomeRoute {}
''');
  }

  Future<void> test_allowsConstantRegistryFiles() async {
    final filePath = '$testPackageLibPath/core/constants/app_strings.dart';
    newFile(filePath, r'''
final activeWorkoutKey = 'active-workout';
final maxRecentSessions = 60;
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsJsonKeysInModelCodecOwner() async {
    await assertNoDiagnostics(r'''
class ProductModel {
  const ProductModel({required this.id, required this.name});

  factory ProductModel.fromJson(Map<String, Object?> json) =>
      ProductModel(id: json['id'] as String, name: json['name'] as String);

  final String id;
  final String name;

  Map<String, Object?> toNameOnlyRequestBody() => {
    'id': id,
    'name': name,
  };
}
''');
  }

  Future<void> test_allowsJsonKeysInDataModelsFile() async {
    final filePath = '$testPackageLibPath/features/products/data/models/product_json.dart';
    newFile(filePath, r'''
Map<String, Object?> productRequestBody(String id, String name) => {
  'id': id,
  'name': name,
};
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsNumericThresholdInModelCodecOwner() async {
    const source = r'''
class ProductModel {
  const ProductModel(this.price);
  final int price;

  bool get isPremium => price > 1000;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('1000'), '1000'.length)]);
  }

  Future<void> test_reportsJsonKeysOutsideCodecOwner() async {
    const source = r'''
class ProductRepository {
  Map<String, Object?> requestBody(String id) => {'id': id};
}

class ItemsNotifier {
  Object? total(Map<String, Object?> json) => json['total'];
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'id'"), "'id'".length),
      lint(source.indexOf("'total'"), "'total'".length),
    ]);
  }

  Future<void> test_allowsStorageKeysAndApiPathsOwners() async {
    final storageKeysPath = '$testPackageLibPath/core/constants/storage_keys.dart';
    newFile(storageKeysPath, _storageKeysOwnerBody);
    final apiPathsPath = '$testPackageLibPath/core/constants/api_paths.dart';
    newFile(apiPathsPath, r'''
String joinPath({required String path}) => path;

abstract final class ApiPaths {
  static const products = '/products';
  static String productsPath() => joinPath(path: '/products');
}
''');

    await assertNoDiagnosticsInFile(storageKeysPath);
    await assertNoDiagnosticsInFile(apiPathsPath);
  }

  Future<void> test_reportsStorageKeysOwnerBodyOutsideOwnerPath() async {
    final filePath = '$testPackageLibPath/features/todos/data/todo_store.dart';
    newFile(filePath, _storageKeysOwnerBody);

    await assertDiagnosticsInFile(filePath, [
      lint(_storageKeysOwnerBody.indexOf("'todos']"), "'todos'".length),
    ]);
  }

  static const _storageKeysOwnerBody = r'''
abstract final class StorageKeys {
  static const todos = 'todos';
  static Object? readTodos(Map<String, Object?> box) => box['todos'];
}
''';

  Future<void> test_allowsResolvedRouteNameAndFlutterRouteSettingsName() async {
    final filePath = '$testPackageLibPath/features/create/presentation/screens/create_screen.dart';
    newFile(filePath, r'''
import 'package:flutter/widgets.dart';

Future<T?> showAppSheet<T>({required String routeName}) async => null;

Future<void> openCreateSheet(String id) async {
  await showAppSheet<int>(routeName: 'create-sheet');
  await showAppSheet<int>(routeName: 'create-sheet-$id');
  const RouteSettings(name: 'create-sheet');
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsKeyAndLookalikeRouteSettingsName() async {
    final filePath = '$testPackageLibPath/features/create/presentation/screens/create_screen.dart';
    const source = r'''
class RouteSettings {
  const RouteSettings({String? name});
}

Object? lookup({required String key}) => null;

void openCreateSheet() {
  lookup(key: 'create-sheet');
  const RouteSettings(name: 'create-route');
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      lint(source.indexOf("'create-sheet'"), "'create-sheet'".length),
      lint(source.indexOf("'create-route'"), "'create-route'".length),
    ]);
  }

  Future<void> test_allowsTestFiles() async {
    final filePath = '$testPackageRootPath/test/widget_test.dart';
    newFile(filePath, r'''
void main() {
  final value = 'active-workout';
  final count = 60;
  value;
  count;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}
