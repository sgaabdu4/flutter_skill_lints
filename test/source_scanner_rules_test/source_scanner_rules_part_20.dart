// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

abstract class _PresentationWidgetRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => presentationWidgetSourceRules;

  @override
  String get path => '$testPackageLibPath/features/content/presentation/widgets/content_view.dart';

  @override
  void setUp() {
    newPackage('go_router').addFile('lib/go_router.dart', r'''
import 'package:flutter/widgets.dart';

abstract class RouteData {
  const RouteData();
}

abstract class GoRouteData extends RouteData {
  const GoRouteData();
  void go(BuildContext context) {}
  Future<T?> push<T>(BuildContext context) async => null;
}

extension GoRouterHelper on BuildContext {
  void go(String location) {}
  void pop<T extends Object?>([T? result]) {}
}
''');
    newPackage('http').addFile('lib/http.dart', 'class Client {}');
    newFile(
      '$testPackageLibPath/features/content/repositories/content_repository.dart',
      'class ContentRepository {}',
    );
    super.setUp();
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
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget();
}

abstract class State<T extends StatefulWidget> {
  void setState(void Function() fn) {}
}

class Route<T> {}

class Navigator extends StatefulWidget {
  static NavigatorState of(BuildContext context) => NavigatorState();
  static Future<T?> push<T extends Object?>(BuildContext context, Route<T> route) async => null;
  static void pop<T extends Object?>(BuildContext context, [T? result]) {}
  static Future<bool> maybePop<T extends Object?>(BuildContext context, [T? result]) async => true;
}

class NavigatorState extends State<Navigator> {
  Future<T?> push<T extends Object?>(Route<T> route) async => null;
  void pop<T extends Object?>([T? result]) {}
  Future<bool> maybePop<T extends Object?>([T? result]) async => true;
}
''');
  }
}

@reflectiveTest
final class PresentationWidgetNavigationForbiddenTest extends _PresentationWidgetRuleTest {
  @override
  String get ruleName => 'presentation_widget_navigation_forbidden';
  @override
  String get needle => 'Navigator.push<void>(context, route)';
  @override
  String get source => r'''
import 'package:flutter/widgets.dart';

void open(BuildContext context, Route<void> route) {
  Navigator.push<void>(context, route);
}
''';

  Future<void> test_reportsGoRouterImports() async {
    final analyzedSource = _analyzedSource(
      "import 'package:go_router/go_router.dart';",
      addIgnorePrefix: addIgnorePrefix,
    );
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, "import 'package:go_router/go_router.dart'", ruleName),
    ]);
  }

  Future<void> test_reportsGenericNavigatorPushes() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:flutter/widgets.dart';

void open(BuildContext context, Route<void> route) {
  Navigator.of(context).push<void>(route);
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'Navigator.of(context).push<void>(route)', ruleName),
    ]);
  }

  Future<void> test_reportsTypedRouteNavigation() async {
    newFile('$testPackageLibPath/features/orders/orders_destination.dart', r'''
import 'package:go_router/go_router.dart';

class OrdersRoute extends GoRouteData {
  const OrdersRoute();
}
''');
    final analyzedSource = _analyzedSource(r'''
import 'package:flutter/widgets.dart';
import 'package:test/features/orders/orders_destination.dart';

void open(BuildContext context) {
  const OrdersRoute().push<void>(context);
  const OrdersRoute().go(context);
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'const OrdersRoute().push<void>(context)', ruleName),
      compatLint(analyzedSource, 'const OrdersRoute().go(context)', ruleName),
    ]);
  }

  Future<void> test_reportsGoRouterContextNavigation() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void close(BuildContext context) {
  context.pop();
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, "import 'package:go_router/go_router.dart'", ruleName),
      compatLint(analyzedSource, 'context.pop()', ruleName),
    ]);
  }

  Future<void> test_reportsWorkAfterModalPop() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:flutter/widgets.dart';

void close(BuildContext context, void Function() onClosed) {
  Navigator.of(context).pop();
  onClosed();
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'Navigator.of(context).pop()', ruleName),
    ]);
  }

  Future<void> test_allowsLocalModalDismissal() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

enum CreateChoice { exercise }

final class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog();

  void confirm(BuildContext context) => Navigator.of(context).pop(true);
  void cancel(BuildContext context) => Navigator.pop(context, false);
  void dismiss(BuildContext context) => Navigator.of(context).maybePop();

  Future<void> _onCreateTapped(BuildContext context) async {
    Navigator.of(context).pop(CreateChoice.exercise);
  }

  void close(BuildContext context, bool canClose) {
    if (canClose) {
      Navigator.pop(context);
      return;
    }
  }
}
''', path: path);
  }

  Future<void> test_allowsTypedCallbacks() async {
    await assertAllows(r'''
final class ContentView extends StatelessWidget {
  const ContentView({required this.onBack, required this.onItemTap});

  final VoidCallback onBack;
  final ValueChanged<Entity> onItemTap;
}
''', path: path);
  }

  Future<void> test_allowsNavigationInScreens() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

void open(BuildContext context, Route<void> route) {
  Navigator.push<void>(context, route);
}
''', path: '$testPackageLibPath/features/content/presentation/screens/content_screen.dart');
  }
}

@reflectiveTest
final class PresentationWidgetControllerStateTest extends _PresentationWidgetRuleTest {
  static const _header = r'''
import 'package:flutter/widgets.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/features/content/domain/entity.dart';

class ContentView extends StatefulWidget {}
''';

  @override
  String get ruleName => 'presentation_widget_controller_state';
  @override
  String get needle => 'final List<Entity> _pageStack';
  @override
  String get source =>
      '''
$_header
class _ContentViewState extends State<ContentView> {
  final List<Entity> _pageStack = [];
}
''';

  @override
  void setUp() {
    newPackage('riverpod').addFile('lib/riverpod.dart', 'class AsyncValue<T> {}');
    newFile('$testPackageLibPath/features/content/domain/entity.dart', 'class Entity {}');
    super.setUp();
  }

  Future<void> test_reportsDomainRecordUnderAnyName() async {
    final analyzedSource = _analyzedSource('''
$_header
class _ContentViewState extends State<ContentView> {
  Entity? _current;
  final Map<String, Entity> _index = {};
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'Entity? _current', ruleName),
      compatLint(analyzedSource, 'final Map<String, Entity> _index', ruleName),
    ]);
  }

  Future<void> test_reportsProviderSnapshot() async {
    final analyzedSource = _analyzedSource('''
$_header
class _ContentViewState extends State<ContentView> {
  AsyncValue<int>? _snapshot;
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'AsyncValue<int>? _snapshot', ruleName),
    ]);
  }

  Future<void> test_reportsAsyncWorkflowFlag() async {
    final analyzedSource = _analyzedSource('''
$_header
class _ContentViewState extends State<ContentView> {
  bool _busy = false;

  Future<void> load(Future<void> Function() fetch) async {
    setState(() => _busy = true);
    await fetch();
    setState(() => _busy = false);
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'bool _busy', ruleName)]);
  }

  Future<void> test_allowsUiLifecycleState() async {
    await assertAllows('''
$_header
class _ContentViewState extends State<ContentView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _animationController;
  Timer? _debounceTimer;
  final List<String> _labels = [];
  bool _expanded = false;
  bool _revealed = false;

  void toggle() => setState(() => _expanded = !_expanded);

  Future<void> reveal(Future<void> Function() animate) async {
    await animate();
    setState(() => _revealed = true);
  }
}
''', path: path);
  }

  Future<void> test_allowsControllerStateInScreens() async {
    await assertAllows('''
$_header
class _ContentScreenState extends State<ContentView> {
  final List<Entity> _pageStack = [];
  Entity? _selected;
}
''', path: '$testPackageLibPath/features/content/presentation/screens/content_screen.dart');
  }
}

@reflectiveTest
final class PresentationWidgetInfrastructureDependencyTest extends _PresentationWidgetRuleTest {
  @override
  String get ruleName => 'presentation_widget_infrastructure_dependency';
  @override
  String get needle => "import 'package:http/http.dart'";
  @override
  String get source => r'''
import 'package:http/http.dart';

final client = Client();
''';

  Future<void> test_reportsRepositoryImports() async {
    final analyzedSource = _analyzedSource(r'''
import '../../repositories/content_repository.dart';

final ContentRepository repository = ContentRepository();
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, "import '../../repositories/content_repository.dart'", ruleName),
    ]);
  }

  Future<void> test_reportsStorageSdkImports() async {
    final analyzedSource = _analyzedSource(r'''
// ignore_for_file: uri_does_not_exist
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, "import 'dart:io'", ruleName),
      compatLint(analyzedSource, "import 'package:flutter_secure_storage/", ruleName),
      compatLint(analyzedSource, "import 'package:path_provider/", ruleName),
    ]);
  }

  Future<void> test_reportsProviderReads() async {
    final analyzedSource = _analyzedSource(r'''
void build(WidgetRef ref) {
  ref.read(contentNotifierProvider.notifier).save();
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'ref.read', ruleName)]);
  }

  Future<void> test_allowsInfrastructureInScreens() async {
    await assertAllows(r'''
void build(WidgetRef ref) {
  ref.read(contentNotifierProvider.notifier).save();
}
''', path: '$testPackageLibPath/features/content/presentation/screens/content_screen.dart');
  }
}

@reflectiveTest
final class NotifierLocalDependencyCacheTest extends _NotifierRuleTest {
  @override
  void setUp() {
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
abstract class ProviderListenable<T extends Object> {}

class Provider<T extends Object> extends ProviderListenable<T> {
  Provider(this.value);
  final T value;
}

class Ref {
  T read<T extends Object>(ProviderListenable<T> provider) => throw UnimplementedError();
}

class Notifier<T> {
  Ref get ref => Ref();
  T? state;
}
''');
    super.setUp();
  }

  @override
  String get ruleName => 'notifier_local_dependency_cache';
  @override
  String get needle => '_repository';
  @override
  String get source => r'''
class Notifier<T> {}

abstract interface class IThingRepository {}

class ThingNotifier extends Notifier<int> {
  IThingRepository? _repository;

  int build() => 0;
}
''';

  Future<void> test_reportsServiceCache() async {
    const source = r'''
class Notifier<T> {}

abstract interface class IThingService {}

class ThingNotifier extends Notifier<int> {
  late final IThingService _service;

  int build() => 0;
}
''';

    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '_service', ruleName)]);
  }

  Future<void> test_allowsStatelessProviderHelper() async {
    await assertAllows(r'''
class Ref {
  T read<T>(Object provider) => throw UnimplementedError();
}

abstract interface class IThingRepository {}
final thingRepositoryProvider = Object();

IThingRepository readThingRepository(Ref ref) => ref.read(thingRepositoryProvider);

class ThingNotifier {
  int build() => 0;
}
''');
  }

  /// async-mutations.md:45: an inferred or lazily assigned provider read is a cache too.
  Future<void> test_reportsInferredAndAssignedProviderReads() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class ProductRepository {}
class BackendHttpClient {}

final productRepositoryProvider = Provider<ProductRepository>(ProductRepository());
final httpClientProvider = Provider<BackendHttpClient>(BackendHttpClient());

class ProductNotifier extends Notifier<int> {
  late final _repo = ref.read(productRepositoryProvider);
  BackendHttpClient? _client;

  int build() => 0;

  void connect() {
    _client ??= ref.read(httpClientProvider);
  }
}
''';

    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '_repo =', ruleName),
      compatLint(analyzedSource, '_client;', ruleName),
    ]);
  }

  Future<void> test_allowsValueReadsConstructedClientsAndRefFields() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

class BackendHttpClient {}

final limitProvider = Provider<int>(20);

class ProductNotifier extends Notifier<int> {
  late final int _limit = ref.read(limitProvider);
  late final Ref _savedRef = ref;
  BackendHttpClient? _client;

  int build() => _limit;

  void connect() {
    _client ??= BackendHttpClient();
  }
}
''');
  }

  Future<void> test_allowsLifecycleResourceField() async {
    await assertAllows(r'''
class Notifier<T> {}
class Timer {}

class ThingNotifier extends Notifier<int> {
  Timer? _timer;

  int build() => 0;
}
''');
  }
}
