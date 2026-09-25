// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

abstract class _NetworkRuleTest extends _DataCrashRuleTest {
  @override
  void setUp() {
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
abstract class AnyNotifier<StateT> {
  StateT get state => throw 0;
  set state(StateT value) {}
}

abstract class Notifier<StateT> extends AnyNotifier<StateT> {
  StateT build();
}
''');
    newPackage('dio').addFile('lib/dio.dart', r'''
class BaseOptions {
  BaseOptions({String? baseUrl, Map<String, Object?>? headers});
}

class Options {
  Options({Map<String, Object?>? headers});
}

class Response<T> {
  T? data;
  int? statusCode;
}

class DioException implements Exception {
  Response<Object?>? response;
}

abstract class Dio {
  factory Dio([BaseOptions? options]) => throw 0;
  Future<Response<T>> get<T>(String path, {Options? options});
}
''');
    newPackage('http').addFile('lib/http.dart', r'''
class ClientException implements Exception {}

abstract class BaseResponse {
  int get statusCode => 0;
}

class Response extends BaseResponse {}

class Client {
  Future<Response> get(Uri url) async => Response();
}

Future<Response> get(Uri url) async => Response();
''');
    super.setUp();
    // The analyzer mock SDK omits dart:io HTTP types; add the real signatures.
    final io = sdkRoot.getFile('lib/io/io.dart');
    io.writeAsStringSync('''
${io.readAsStringSync()}
abstract interface class HttpClientResponse {
  int get statusCode;
}

abstract interface class HttpClientRequest {
  Future<HttpClientResponse> close();
}

abstract interface class HttpClient {
  factory HttpClient() => throw 0;
  Future<HttpClientRequest> getUrl(Uri url);
}

class SocketException implements Exception {}

class HttpException implements Exception {}
''');
  }

  @override
  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}

abstract class Widget {
  const Widget();
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget();
  Widget build(BuildContext context);
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget();
}

abstract class State<T extends StatefulWidget> {
  Widget build(BuildContext context);
}

class Text extends StatelessWidget {
  const Text(String data);
  @override
  Widget build(BuildContext context) => this;
}
''');
  }

  String get httpServicePath => '$testPackageLibPath/core/network/http_service.dart';

  /// The skill's IHttpService boundary with a Dio-backed implementation.
  void addHttpService() {
    newFile(httpServicePath, r'''
import 'package:dio/dio.dart';

abstract interface class IHttpService {
  Future<Object?> getJson(Uri uri);
}

class HttpService implements IHttpService {
  HttpService(this._dio);

  final Dio _dio;

  @override
  Future<Object?> getJson(Uri uri) async => (await _dio.get<Object?>('$uri')).data;
}
''');
  }

  /// The skill's datasource and repository chain on top of [addHttpService].
  void addProductChain() {
    addHttpService();
    newFile('$testPackageLibPath/features/products/data/product_remote_datasource.dart', r'''
import 'package:test/core/network/http_service.dart';

abstract interface class IProductRemoteDatasource {
  Future<List<Object?>> fetchAll();
}

class ProductRemoteDatasource implements IProductRemoteDatasource {
  const ProductRemoteDatasource(this._http);

  final IHttpService _http;

  @override
  Future<List<Object?>> fetchAll() async => switch (await _http.getJson(Uri(path: '/p'))) {
        List<Object?> items => items,
        _ => throw FormatException(),
      };
}
''');
    newFile('$testPackageLibPath/features/products/data/product_repository.dart', r'''
import 'package:test/features/products/data/product_remote_datasource.dart';

abstract interface class IProductRepository {
  Future<List<Object?>> fetchAll();
}

class ProductRepository implements IProductRepository {
  const ProductRepository(this._remote);

  final IProductRemoteDatasource _remote;

  @override
  Future<List<Object?>> fetchAll() => _remote.fetchAll();
}
''');
  }
}

@reflectiveTest
final class NetworkHttpCallInWidgetOrNotifierTest extends _NetworkRuleTest {
  @override
  String get ruleName => 'network_http_call_in_widget_or_notifier';
  @override
  String get needle => "Dio().get<Object?>('/x')";
  @override
  String get path =>
      '$testPackageLibPath/features/products/presentation/screens/product_screen.dart';
  @override
  String get source => r'''
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen();

  @override
  Widget build(BuildContext context) {
    Future<void> load() => Dio().get<Object?>('/x');
    return const Text('products');
  }
}
''';

  Future<void> test_reportsNotifierClientCalls() async {
    const source = r'''
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod/riverpod.dart';

class ProductNotifier extends Notifier<int> {
  final Dio _dio = Dio();

  @override
  int build() => 0;

  Future<void> load() async {
    await _dio.get<Object?>('/x');
    await http.get(Uri(path: '/y'));
    await HttpClient().getUrl(Uri(path: '/z'));
  }
}
''';
    final notifierPath = '$testPackageLibPath/features/products/presentation/product_notifier.dart';
    newFile(notifierPath, source);

    await assertDiagnosticsInFile(notifierPath, [
      compatLint(source, "_dio.get<Object?>('/x')", ruleName),
      compatLint(source, "http.get(Uri(path: '/y'))", ruleName),
      compatLint(source, "HttpClient().getUrl(Uri(path: '/z'))", ruleName),
    ]);
  }

  Future<void> test_reportsStateCallOnHttpServiceWrapper() async {
    addHttpService();
    const source = r'''
import 'package:flutter/widgets.dart';
import 'package:test/core/network/http_service.dart';

final IHttpService httpService = throw 0;

class ProductPanel extends StatefulWidget {
  const ProductPanel();
}

class _ProductPanelState extends State<ProductPanel> {
  Future<void> load() => httpService.getJson(Uri(path: '/p'));

  @override
  Widget build(BuildContext context) => const Text('panel');
}
''';
    final panelPath = '$testPackageLibPath/features/products/presentation/product_panel.dart';
    newFile(panelPath, source);

    await assertDiagnosticsInFile(panelPath, [
      compatLint(source, "httpService.getJson(Uri(path: '/p'))", ruleName),
    ]);
  }

  Future<void> test_allowsRepositoryDatasourceHttpChain() async {
    addProductChain();
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';
import 'package:test/features/products/data/product_repository.dart';

final IProductRepository repository = throw 0;

class ProductNotifier extends AnyNotifier<int> {
  Future<void> load() async {
    state = (await repository.fetchAll()).length;
  }
}
''', path: '$testPackageLibPath/features/products/presentation/product_notifier.dart');
    await assertNoDiagnosticsInFile(httpServicePath);
    await assertNoDiagnosticsInFile(
      '$testPackageLibPath/features/products/data/product_remote_datasource.dart',
    );
  }
}

@reflectiveTest
final class DatasourceConcreteHttpClientTest extends _NetworkRuleTest {
  @override
  String get ruleName => 'datasource_concrete_http_client';
  @override
  String get needle => 'Dio _dio;';
  @override
  String get path => '$testPackageLibPath/features/products/data/product_remote_datasource.dart';
  @override
  String get source => r'''
import 'package:dio/dio.dart';

class ProductRemoteDatasource {
  ProductRemoteDatasource(this._dio);

  final Dio _dio;
}
''';

  Future<void> test_reportsConcreteClientsAndWrappers() async {
    addHttpService();
    const source = r'''
import 'package:http/http.dart' as http;
import 'package:test/core/network/http_service.dart';

abstract interface class IOrderRemoteDataSource {}

class OrderApi implements IOrderRemoteDataSource {
  OrderApi(http.Client client, this._http);

  final HttpService _http;
}
''';
    final datasourcePath = '$testPackageLibPath/features/orders/data/order_api.dart';
    newFile(datasourcePath, source);

    await assertDiagnosticsInFile(datasourcePath, [
      compatLint(source, 'http.Client client', ruleName),
      compatLint(source, 'HttpService _http;', ruleName),
    ]);
  }

  Future<void> test_allowsHttpServiceInterface() async {
    addProductChain();
    await assertNoDiagnosticsInFile(
      '$testPackageLibPath/features/products/data/product_remote_datasource.dart',
    );
    await assertNoDiagnosticsInFile(httpServicePath);
  }
}

@reflectiveTest
final class NetworkFailureNullFallbackTest extends _NetworkRuleTest {
  @override
  void setUp() {
    newPackage('hive_ce').addFile('lib/hive_ce.dart', r'''
abstract class Box<E> {
  Iterable<E> get values;
}
''');
    super.setUp();
    addProductChain();
  }

  @override
  String get ruleName => 'network_failure_null_fallback';
  @override
  String get needle => 'return null;';
  @override
  String get path => '$testPackageLibPath/features/products/data/product_lookup_repository.dart';
  @override
  String get source => r'''
import 'package:test/features/products/data/product_remote_datasource.dart';

class ProductLookupRepository {
  ProductLookupRepository(this._remote);

  final IProductRemoteDatasource _remote;

  Future<Object?> first() async {
    try {
      return (await _remote.fetchAll()).first;
    } on Object {
      return null;
    }
  }
}
''';

  Future<void> test_reportsEmptyCollectionFallbacks() async {
    const source = r'''
import 'package:dio/dio.dart';
import 'package:test/core/network/http_service.dart';

class OrderRemoteDatasource {
  OrderRemoteDatasource(this._http);

  final IHttpService _http;

  Future<List<Object?>> all() async {
    try {
      return [await _http.getJson(Uri(path: '/orders'))];
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, Object?>> byId() async {
    try {
      return {'order': await _http.getJson(Uri(path: '/orders/1'))};
    } on DioException {
      return {};
    }
  }
}
''';
    final datasourcePath = '$testPackageLibPath/features/orders/data/order_remote_datasource.dart';
    newFile(datasourcePath, source);

    await assertDiagnosticsInFile(datasourcePath, [
      compatLint(source, 'return const [];', ruleName),
      compatLint(source, 'return {};', ruleName),
    ]);
  }

  Future<void> test_allowsTypedAbsenceAndClassifiedStatus() async {
    await assertAllows(r'''
import 'package:dio/dio.dart';
import 'package:test/features/products/data/product_remote_datasource.dart';

class NotFoundException implements Exception {}

class ProductLookupRepository {
  ProductLookupRepository(this._remote);

  final IProductRemoteDatasource _remote;

  Future<Object?> first() async {
    try {
      return (await _remote.fetchAll()).first;
    } on NotFoundException {
      return null;
    }
  }

  Future<Object?> maybeFirst() async {
    try {
      return (await _remote.fetchAll()).first;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
''', path: path);
  }

  Future<void> test_allowsLocalPersistenceRecovery() async {
    await assertAllows(r'''
import 'package:hive_ce/hive_ce.dart';

class ProductLocalDatasource {
  ProductLocalDatasource(this._box);

  final Box<Object?> _box;

  List<Object?> readAll() {
    try {
      return _box.values.toList();
    } catch (_) {
      return [];
    }
  }
}
''', path: '$testPackageLibPath/features/products/data/product_local_datasource.dart');
  }
}

@reflectiveTest
final class NetworkSecretInWidgetTest extends _NetworkRuleTest {
  @override
  String get ruleName => 'network_secret_in_widget';
  @override
  String get needle => "'Bearer fixture'";
  @override
  String get path => '$testPackageLibPath/features/products/presentation/widgets/product_card.dart';
  @override
  String get source => r'''
import 'package:flutter/widgets.dart';

class ProductCard extends StatelessWidget {
  const ProductCard();

  static const _token = 'Bearer fixture';

  @override
  Widget build(BuildContext context) => const Text(_token);
}
''';

  Future<void> test_reportsAuthorizationHeaderAndBaseUrlInState() async {
    const source = r'''
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

class ProductPanel extends StatefulWidget {
  const ProductPanel();
}

class _ProductPanelState extends State<ProductPanel> {
  final String credentials = 'fixture';

  Dio client() => Dio(BaseOptions(
    baseUrl: 'https://api.example.test',
    headers: {'Authorization': 'Basic $credentials'},
  ));

  @override
  Widget build(BuildContext context) => const Text('panel');
}
''';
    final panelPath = '$testPackageLibPath/features/products/presentation/product_panel.dart';
    newFile(panelPath, source);

    await assertDiagnosticsInFile(panelPath, [
      compatLint(source, "baseUrl: 'https://api.example.test'", ruleName),
      compatLint(source, "'Authorization': 'Basic ", ruleName),
      compatLint(source, "'Basic ", ruleName),
    ]);
  }

  Future<void> test_allowsInfrastructureAuthAndPlainWidgetLinks() async {
    await assertAllows(r'''
import 'package:dio/dio.dart';

class HttpService {
  HttpService(String token)
    : _dio = Dio(BaseOptions(
        baseUrl: 'https://api.example.test',
        headers: {'Authorization': 'Bearer $token'},
      ));

  final Dio _dio;
}
''', path: '$testPackageLibPath/core/network/http_service.dart');
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

class HelpLink extends StatelessWidget {
  const HelpLink();

  @override
  Widget build(BuildContext context) => const Text('https://example.test/help');
}
''', path: '$testPackageLibPath/features/help/presentation/widgets/help_link.dart');
  }
}

@reflectiveTest
final class NetworkRawHttpFailureInWidgetOrNotifierTest extends _NetworkRuleTest {
  @override
  String get ruleName => 'network_raw_http_failure_in_widget_or_notifier';
  @override
  String get needle => 'on DioException catch (_)';
  @override
  String get path => '$testPackageLibPath/features/products/presentation/product_notifier.dart';
  @override
  String get source => r'''
import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

final Future<void> Function() load = throw 0;

class ProductNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> refresh() async {
    try {
      await load();
      state = 1;
    } on DioException catch (_) {
      state = -1;
    }
  }
}
''';

  Future<void> test_reportsStatusReadsAndRawTypeTests() async {
    const source = r'''
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod/riverpod.dart';

class ProductNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void apply(Response<Object?> response, http.Response legacy, Object error) {
    if (response.statusCode == 404) state = -1;
    if (legacy.statusCode == 401) state = -2;
    if (error is SocketException) state = -3;
  }

  Future<void> retry(Future<void> Function() load) async {
    try {
      await load();
    } on http.ClientException {
      state = -4;
    }
  }
}

class ProductPanel extends StatefulWidget {
  const ProductPanel();
}

class _ProductPanelState extends State<ProductPanel> {
  bool missing(DioException error) => error.response?.statusCode == 404;

  @override
  Widget build(BuildContext context) => const Text('panel');
}
''';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      compatLint(source, 'response.statusCode == 404', ruleName),
      compatLint(source, 'legacy.statusCode == 401', ruleName),
      compatLint(source, 'error is SocketException', ruleName),
      compatLint(source, 'on http.ClientException', ruleName),
      compatLint(source, 'error.response?.statusCode', ruleName),
    ]);
  }

  Future<void> test_allowsTypedFailuresAndDatasourceClassification() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

class AppException implements Exception {}

final Future<void> Function() load = throw 0;

class ProductNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> refresh() async {
    try {
      await load();
    } on AppException {
      state = -1;
    } on Exception {
      state = -2;
    }
  }
}
''', path: path);
    await assertAllows(r'''
import 'package:dio/dio.dart';

class AppException implements Exception {}

class ProductRemoteDatasource {
  Future<Object?> read(Future<Response<Object?>> Function() get) async {
    try {
      final response = await get();
      if (response.statusCode == 404) return null;
      return response.data;
    } on DioException {
      throw AppException();
    }
  }
}
''', path: '$testPackageLibPath/features/products/data/product_remote_datasource.dart');
  }
}
