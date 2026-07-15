// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

abstract class _PresentationWidgetRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => presentationWidgetSourceRules;

  @override
  String get path => '$testPackageLibPath/features/content/presentation/widgets/content_view.dart';

  @override
  void setUp() {
    newPackage('go_router').addFile('lib/go_router.dart', '');
    newPackage('http').addFile('lib/http.dart', 'class Client {}');
    newFile(
      '$testPackageLibPath/features/content/repositories/content_repository.dart',
      'class ContentRepository {}',
    );
    super.setUp();
  }
}

@reflectiveTest
final class PresentationWidgetNavigationForbiddenTest extends _PresentationWidgetRuleTest {
  @override
  String get ruleName => 'presentation_widget_navigation_forbidden';
  @override
  String get needle => 'context.pop()';
  @override
  String get source => r'''
void close(BuildContext context) {
  context.pop();
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

  Future<void> test_reportsNavigatorCalls() async {
    final analyzedSource = _analyzedSource(r'''
void close(BuildContext context) {
  Navigator.of(context).pop();
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'Navigator.of(context).pop()', ruleName),
    ]);
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
void close(BuildContext context) {
  context.pop();
}
''', path: '$testPackageLibPath/features/content/presentation/screens/content_screen.dart');
  }
}

@reflectiveTest
final class PresentationWidgetControllerStateTest extends _PresentationWidgetRuleTest {
  @override
  String get ruleName => 'presentation_widget_controller_state';
  @override
  String get needle => 'final List<Entity> _pageStack';
  @override
  String get source => r'''
class _ContentViewState extends State<ContentView> {
  final List<Entity> _pageStack = [];
}
''';

  Future<void> test_reportsSelectedDomainRecord() async {
    final analyzedSource = _analyzedSource(r'''
class _ContentViewState extends State<ContentView> {
  Entity? _selected;
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'Entity? _selected', ruleName),
    ]);
  }

  Future<void> test_reportsWorkflowStatus() async {
    final analyzedSource = _analyzedSource(r'''
class _ContentViewState extends State<ContentView> {
  bool _isSaving = false;
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'bool _isSaving', ruleName)]);
  }

  Future<void> test_allowsUiLifecycleState() async {
    await assertAllows(r'''
class _ContentViewState extends State<ContentView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _animationController;
  Timer? _debounceTimer;
}
''', path: path);
  }

  Future<void> test_allowsControllerStateInScreens() async {
    await assertAllows(r'''
class _ContentScreenState extends State<ContentScreen> {
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
