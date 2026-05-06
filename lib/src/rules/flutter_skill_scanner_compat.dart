import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

final class FlutterSkillScannerCompat extends MultiAnalysisRule {
  FlutterSkillScannerCompat()
    : super(
        name: 'flutter_skill_scanner_compat',
        description: 'Compatibility diagnostics from the Flutter skill scanner.',
      );

  static const Map<String, LintCode> codes = {
    'riverpod_read_init_state': LintCode(
      'riverpod_read_init_state',
      'Avoid ref.read in initState.',
      correctionMessage: 'Defer reads with a post-frame callback.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'riverpod_service_locator': LintCode(
      'riverpod_service_locator',
      'Avoid service locator classes in Riverpod apps.',
      correctionMessage: 'Model dependencies with providers.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'riverpod_watch_no_select': LintCode(
      'riverpod_watch_no_select',
      'Prefer select when watching state in leaf widgets.',
      correctionMessage: 'Use ref.watch(provider.select((value) => value.field)).',
      severity: DiagnosticSeverity.WARNING,
    ),
    'riverpod_keepalive_family': LintCode(
      'riverpod_keepalive_family',
      'Avoid keepAlive family providers.',
      correctionMessage: 'Use auto-dispose families unless the cache is bounded.',
      severity: DiagnosticSeverity.WARNING,
    ),
    'dart_static_namespace': LintCode(
      'dart_static_namespace',
      'Prefer abstract final for static-only namespaces.',
      correctionMessage:
          'Replace private constructors on static-only classes with abstract final class.',
      severity: DiagnosticSeverity.WARNING,
    ),
    'freezed_per_class_explicit_to_json': LintCode(
      'freezed_per_class_explicit_to_json',
      'Do not set explicitToJson per JsonSerializable class.',
      correctionMessage: 'Set explicit_to_json: true in build.yaml.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'freezed_to_json_with_from_json': LintCode(
      'freezed_to_json_with_from_json',
      'Do not use @Freezed(toJson: true) when fromJson exists.',
      correctionMessage: 'Use plain @freezed with fromJson.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'freezed_legacy_when_map': LintCode(
      'freezed_legacy_when_map',
      'Avoid legacy Freezed when/map helpers.',
      correctionMessage: 'Use Dart pattern matching and switch expressions.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'arch_domain_import': LintCode(
      'arch_domain_import',
      'Domain code must stay pure Dart.',
      correctionMessage: 'Move Flutter/package dependencies out of domain entities.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'arch_domain_serialization': LintCode(
      'arch_domain_serialization',
      'Domain code must not own JSON serialization.',
      correctionMessage: 'Move fromJson/toJson code to data models.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'arch_interface_contract': LintCode(
      'arch_interface_contract',
      'Repositories and datasources need interface contracts.',
      correctionMessage: 'Add an abstract interface class for this layer.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'arch_concrete_dependency': LintCode(
      'arch_concrete_dependency',
      'Layer constructors should depend on interfaces.',
      correctionMessage: 'Take I*Repository/I*Datasource interfaces instead of concrete classes.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'arch_datasource_try_catch': LintCode(
      'arch_datasource_try_catch',
      'Avoid try/catch in datasources.',
      correctionMessage: 'Let errors propagate and catch once at the notifier boundary.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'arch_widget_path': LintCode(
      'arch_widget_path',
      'Feature widgets belong under presentation/widgets.',
      correctionMessage: 'Move feature widgets into the presentation layer.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'atomic_provider_access': LintCode(
      'atomic_provider_access',
      'Atomic design widgets should not access providers directly.',
      correctionMessage: 'Move provider access to the presentation boundary.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'style_raw_token': LintCode(
      'style_raw_token',
      'Avoid raw spacing, radius, size, and color tokens.',
      correctionMessage: 'Use design tokens.',
      severity: DiagnosticSeverity.WARNING,
    ),
    'style_raw_text_style': LintCode(
      'style_raw_text_style',
      'Avoid raw TextStyle construction.',
      correctionMessage: 'Use the app theme text styles.',
      severity: DiagnosticSeverity.WARNING,
    ),
    'strings_hardcoded': LintCode(
      'strings_hardcoded',
      'Avoid hardcoded UI strings.',
      correctionMessage: 'Move text into a *Strings constants class.',
      severity: DiagnosticSeverity.WARNING,
    ),
    'ui_snackbar_boundary': LintCode(
      'ui_snackbar_boundary',
      'UI widgets should not directly show snackbars.',
      correctionMessage: 'Dispatch a notifier action and let the shell own snackbar presentation.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'a11y_text_scale_clamp': LintCode(
      'a11y_text_scale_clamp',
      'Do not globally clamp text scaling.',
      correctionMessage: 'Fix responsive layout instead of clamping accessibility text size.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'perf_build_work': LintCode(
      'perf_build_work',
      'Avoid expensive work in build().',
      correctionMessage: 'Move sorting, filtering, formatting, and regex creation out of build.',
      severity: DiagnosticSeverity.WARNING,
    ),
    'perf_listview_children': LintCode(
      'perf_listview_children',
      'Prefer ListView.builder for dynamic lists.',
      correctionMessage: 'Use builder/sliver variants instead of ListView(children: ...).',
      severity: DiagnosticSeverity.WARNING,
    ),
    'state_raw_response': LintCode(
      'state_raw_response',
      'Do not store raw API responses in state.',
      correctionMessage: 'Extract the fields needed by the UI.',
      severity: DiagnosticSeverity.WARNING,
    ),
    'state_broad_invalidation': LintCode(
      'state_broad_invalidation',
      'Avoid broad invalidation before navigation-critical route changes.',
      correctionMessage: 'Persist, targeted-sync state, then navigate.',
      severity: DiagnosticSeverity.WARNING,
    ),
    'async_context_mounted_style': LintCode(
      'async_context_mounted_style',
      'Use context.mounted after async gaps in widgets.',
      correctionMessage: 'Replace mounted checks with context.mounted for BuildContext safety.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'notifier_ensure_deps': LintCode(
      'notifier_ensure_deps',
      'Mutation methods must initialize dependencies before writes.',
      correctionMessage:
          'Call an _ensure... helper before using repositories or ref.read dependencies.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'notifier_watch_method': LintCode(
      'notifier_watch_method',
      'Avoid ref.watch inside notifier methods.',
      correctionMessage: 'Use ref.read in notifier methods.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'router_string_nav': LintCode(
      'router_string_nav',
      'Avoid string route navigation.',
      correctionMessage: 'Use typed GoRouter routes.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'router_pop_then_push': LintCode(
      'router_pop_then_push',
      'Do not pop and push in the same synchronous flow.',
      correctionMessage: 'Wait for modal dismissal before pushing the next route.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'router_redirect_watch': LintCode(
      'router_redirect_watch',
      'Avoid ref.watch in router redirects.',
      correctionMessage: 'Use a read/listenable bridge for redirect state.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'router_redirect_loading_bounce': LintCode(
      'router_redirect_loading_bounce',
      'Do not redirect to loading routes while auth/router state is loading.',
      correctionMessage: 'Return null while loading to stay on the current route.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'showcase_listen_manual_handle': LintCode(
      'showcase_listen_manual_handle',
      'Store listenManual subscriptions.',
      correctionMessage: 'Keep and close the ProviderSubscription handle.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'showcase_prev_null_guard': LintCode(
      'showcase_prev_null_guard',
      'Avoid prev != null showcase replay guards.',
      correctionMessage: 'Compare previous and next values instead.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'showcase_default_scope': LintCode(
      'showcase_default_scope',
      'Avoid default ShowcaseView scope registration.',
      correctionMessage: 'Use a named ShowcaseView scope.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'showcase_dispose_on_tap': LintCode(
      'showcase_dispose_on_tap',
      'disposeOnTap requires explicit target click handling.',
      correctionMessage: 'Add onTargetClick when disposeOnTap is true.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'test_provider_container': LintCode(
      'test_provider_container',
      'Use ProviderContainer.test in tests.',
      correctionMessage: 'Replace ProviderContainer(...) with ProviderContainer.test().',
      severity: DiagnosticSeverity.ERROR,
    ),
    'test_uncontrolled_scope': LintCode(
      'test_uncontrolled_scope',
      'Use UncontrolledProviderScope in tests.',
      correctionMessage: 'Wrap test widgets with an explicit test container.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'test_create_container': LintCode(
      'test_create_container',
      'Avoid createContainer test helpers.',
      correctionMessage: 'Use ProviderContainer.test().',
      severity: DiagnosticSeverity.ERROR,
    ),
    'test_mock_concrete': LintCode(
      'test_mock_concrete',
      'Mocks should implement interfaces, not concrete classes.',
      correctionMessage: 'Mock I* contracts instead of concrete implementations.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'test_pump_and_settle': LintCode(
      'test_pump_and_settle',
      'Avoid unbounded pumpAndSettle in tests.',
      correctionMessage: 'Use explicit pumps or pass a timeout.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'test_tap_at': LintCode(
      'test_tap_at',
      'Avoid coordinate-based test taps.',
      correctionMessage: 'Use stable ValueKey finders.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'test_inline_value_key': LintCode(
      'test_inline_value_key',
      'Avoid inline ValueKey strings.',
      correctionMessage: 'Centralize widget keys in a key registry.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'test_first_match_finder': LintCode(
      'test_first_match_finder',
      'Avoid first-match widget finders in tests.',
      correctionMessage: 'Use deterministic ValueKey finders.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'service_singleton': LintCode(
      'service_singleton',
      'Avoid new singleton instance fields.',
      correctionMessage: 'Use Riverpod providers or injected services.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'mixin_mixin_class': LintCode(
      'mixin_mixin_class',
      'Avoid mixin class for capability mixins.',
      correctionMessage: 'Use mixin for reusable behavior.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'mixin_name_suffix': LintCode(
      'mixin_name_suffix',
      'Mixin names should end with Mixin.',
      correctionMessage: 'Suffix capability mixins with Mixin.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'mixin_mutable_state': LintCode(
      'mixin_mutable_state',
      'Mixins should not carry mutable state.',
      correctionMessage: 'Keep mixins stateless.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'typed_id_raw_id': LintCode(
      'typed_id_raw_id',
      'Use typed IDs for entities with multiple String IDs.',
      correctionMessage: 'Use extension types or value objects for IDs.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'records_map_return': LintCode(
      'records_map_return',
      'Avoid Map<String, dynamic> for non-data multi-value returns.',
      correctionMessage: 'Use records or typed objects.',
      severity: DiagnosticSeverity.ERROR,
    ),
    'data_log_rethrow': LintCode(
      'data_log_rethrow',
      'Avoid log-and-rethrow in data layers.',
      correctionMessage: 'Let callers log once at the boundary.',
      severity: DiagnosticSeverity.WARNING,
    ),
    'crash_possible_pii': LintCode(
      'crash_possible_pii',
      'Crash reporting may include PII.',
      correctionMessage: 'Do not send email, name, phone, token, password, address, or user IDs.',
      severity: DiagnosticSeverity.WARNING,
    ),
    'crash_unawaited_send': LintCode(
      'crash_unawaited_send',
      'Crash sends should be awaited or explicitly unawaited.',
      correctionMessage: 'Use await or unawaited for non-fatal crash sends.',
      severity: DiagnosticSeverity.WARNING,
    ),
  };

  @override
  List<DiagnosticCode> get diagnosticCodes => codes.values.toList();

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addCompilationUnit(this, _Visitor(this, context));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final FlutterSkillScannerCompat rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = _relativePath(context.definingUnit.file.path);
    final source = _CompatSource(context.definingUnit.content);
    final classes = _classes(source);
    final methods = <_MethodSpan>[];
    for (final classSpan in classes) {
      methods.addAll(_methods(source, classSpan));
    }

    _scanLineRules(path, source);
    _scanFileRules(path, source, classes, methods);
    _scanShowcaseRules(path, source);
    _scanAsyncRules(path, source, classes, methods);
    _scanNotifierRules(path, source, classes, methods);
    _scanWarningRules(path, source, methods);
  }

  void _scanLineRules(String path, _CompatSource source) {
    for (var i = 0; i < source.length; i++) {
      final line = source.masked[i];
      final code = source.code[i];

      if (_isInitStateRead(source, i)) {
        _report('riverpod_read_init_state', source, i, line.indexOf('ref.read'));
      }
      if (RegExp(r'\bclass\s+(?:ServiceFactory|ServiceLocator|BackendProvider)\b').hasMatch(line)) {
        _report('riverpod_service_locator', source, i, line.indexOf('class'));
      }
      if (RegExp(r'\bref\s*\.\s*watch\s*\(').hasMatch(line) &&
          !line.contains('.select(') &&
          !line.contains('select(')) {
        _report('riverpod_watch_no_select', source, i, line.indexOf('ref'));
      }
      if (RegExp(r'@Riverpod\s*\([^)]*keepAlive\s*:\s*true').hasMatch(line) &&
          _near(source, i, 'required ', 5)) {
        _report('riverpod_keepalive_family', source, i, line.indexOf('@Riverpod'));
      }
      if (RegExp(r'@JsonSerializable\s*\([^)]*explicitToJson\s*:\s*true').hasMatch(line)) {
        _report('freezed_per_class_explicit_to_json', source, i, line.indexOf('@JsonSerializable'));
      }
      if (RegExp(r'(?:\.|\b)(?:when|maybeWhen|maybeMap)\s*\(').hasMatch(line)) {
        _report(
          'freezed_legacy_when_map',
          source,
          i,
          line.indexOf(RegExp(r'(when|maybeWhen|maybeMap)')),
        );
      }
      if (_isDomainPath(path) &&
          RegExp(
            r'''^\s*import\s+['"](?:package:flutter|dart:ui|package:[^'"]+)''',
          ).hasMatch(code)) {
        _report('arch_domain_import', source, i, line.indexOf('import'));
      }
      if (_isDomainPath(path) &&
          RegExp(r'\b(?:fromJson|toJson|_\$\w+FromJson)\s*\(').hasMatch(line)) {
        _report('arch_domain_serialization', source, i, 0);
      }
      if (_isDatasourcePath(path) && RegExp(r'\btry\s*\{').hasMatch(line)) {
        _report('arch_datasource_try_catch', source, i, line.indexOf('try'));
      }
      if (_isFeatureWidgetWrongPath(path)) {
        _report('arch_widget_path', source, i, 0);
      }
      if (_isAtomicNoProviderPath(path) &&
          RegExp(r'\bref\s*\.\s*(?:read|watch)\s*\(').hasMatch(line)) {
        _report('atomic_provider_access', source, i, line.indexOf('ref'));
      }
      if (RegExp(r'\bTextStyle\s*\(').hasMatch(line)) {
        _report('style_raw_text_style', source, i, line.indexOf('TextStyle'));
      }
      if (_hasHardcodedUiString(code, path)) {
        _report('strings_hardcoded', source, i, 0);
      }
      if (_hasStringNavigation(code, line)) {
        _report('router_string_nav', source, i, line.indexOf('context'));
      }
      if (RegExp(r'\bcontext\s*\.\s*pop\s*\(').hasMatch(line) && _near(source, i, '.push', 4)) {
        _report('router_pop_then_push', source, i, line.indexOf('context'));
      }
      if (_isRedirectWatch(source, i)) {
        _report('router_redirect_watch', source, i, line.indexOf('ref'));
      }
      if (_isRedirectLoadingBounce(source, i, code)) {
        _report('router_redirect_loading_bounce', source, i, 0);
      }
      if (_isTestFile(path) && RegExp(r'\bProviderContainer\s*\(').hasMatch(line)) {
        _report('test_provider_container', source, i, line.indexOf('ProviderContainer'));
      }
      if (_isTestFile(path) && RegExp(r'\bcreateContainer\s*\(').hasMatch(line)) {
        _report('test_create_container', source, i, line.indexOf('createContainer'));
      }
      if (_isTestFile(path) && RegExp(r'\bProviderScope\s*\(').hasMatch(line)) {
        _report('test_uncontrolled_scope', source, i, line.indexOf('ProviderScope'));
      }
      if (_isTestFile(path) &&
          RegExp(r'class\s+Mock\w+\s+extends\s+Mock\s+implements\s+(?!I)[A-Z]\w+').hasMatch(line)) {
        _report('test_mock_concrete', source, i, line.indexOf('class'));
      }
      if (_isTestFile(path) &&
          RegExp(r'\bpumpAndSettle\s*\(').hasMatch(line) &&
          !line.contains('timeout')) {
        _report('test_pump_and_settle', source, i, line.indexOf('pumpAndSettle'));
      }
      if (_isTestFile(path) && RegExp(r'\btapAt\s*\(').hasMatch(line)) {
        _report('test_tap_at', source, i, line.indexOf('tapAt'));
      }
      if (!_isKeyRegistryFile(path) &&
          RegExp(r"""\bValueKey(?:<[^>]+>)?\s*\(\s*(?:const\s+)?["']""").hasMatch(code)) {
        _report('test_inline_value_key', source, i, line.indexOf('ValueKey'));
      }
      if (_isTestFile(path) && (line.contains('find.byIcon') || line.contains('.first'))) {
        _report('test_first_match_finder', source, i, 0);
      }
      if (RegExp(r'\bstatic\s+final\s+(?:\w+\s+)?instance\s*=').hasMatch(line)) {
        _report('service_singleton', source, i, line.indexOf('static'));
      }
      if (RegExp(r'^\s*mixin\s+class\s+\w+').hasMatch(line)) {
        _report('mixin_mixin_class', source, i, line.indexOf('mixin'));
      }
      final mixinMatch = RegExp(r'^\s*mixin(?:\s+class)?\s+(\w+)').firstMatch(line);
      if (mixinMatch != null && !(mixinMatch.group(1) ?? '').endsWith('Mixin')) {
        _report('mixin_name_suffix', source, i, mixinMatch.start);
      }
      if (_isMutableMixinField(source, i)) {
        _report('mixin_mutable_state', source, i, 0);
      }
      if (_isMapDynamicReturn(line, path)) {
        _report('records_map_return', source, i, line.indexOf('Map'));
      }
      if (_isUiFile(path) && _dispatchesSnackbarFromUi(line)) {
        _report('ui_snackbar_boundary', source, i, 0);
      }
      if (_isAppRootFile(path) && _clampsTextScaling(line)) {
        _report('a11y_text_scale_clamp', source, i, 0);
      }
    }
  }

  void _scanFileRules(
    String path,
    _CompatSource source,
    List<_ClassSpan> classes,
    List<_MethodSpan> methods,
  ) {
    final text = source.masked.join('\n');

    if (RegExp(r'@Freezed\s*\([^)]*toJson\s*:\s*true').hasMatch(text) &&
        RegExp(r'\bfactory\s+\w+(?:\.\w+)?\.fromJson\s*\(').hasMatch(text)) {
      _report('freezed_to_json_with_from_json', source, _firstLine(source, '@Freezed'), 0);
    }

    if ((_isDatasourcePath(path) || _isRepositoryPath(path)) &&
        _hasConcreteLayerClass(source) &&
        !RegExp(r'\babstract\s+interface\s+class\s+I\w+').hasMatch(text)) {
      _report('arch_interface_contract', source, 0, 0);
    }

    if (_isRepositoryPath(path) || _isDatasourcePath(path)) {
      for (var i = 0; i < source.length; i++) {
        final line = source.masked[i];
        if (_hasConcreteLayerDependencyLine(line)) {
          _report('arch_concrete_dependency', source, i, 0);
        }
      }
    }

    if (_isDomainPath(path)) {
      final idFields = <int>[];
      for (var i = 0; i < source.length; i++) {
        if (RegExp(r'\bfinal\s+String\s+\w*Id\s*;').hasMatch(source.masked[i])) {
          idFields.add(i);
        }
      }
      if (idFields.length > 1) {
        _report('typed_id_raw_id', source, idFields.first, 0);
      }
    }

    for (final classSpan in classes) {
      if (_isPrivateNamespaceConstructor(source, classSpan)) {
        _report('dart_static_namespace', source, classSpan.start, 0);
      }
    }

    for (final method in methods) {
      for (var i = method.start; i <= method.end; i++) {
        final line = source.masked[i];
        if (line.contains('if (!mounted)') && _near(source, i, 'await ', 8)) {
          _report('async_context_mounted_style', source, i, line.indexOf('mounted'));
        }
        if (line.contains('ref.invalidate(') &&
            _isMutationMethod(method.name) &&
            _near(source, i, 'go(', 8)) {
          _report('state_broad_invalidation', source, i, line.indexOf('ref'));
        }
      }
    }
  }

  void _scanShowcaseRules(String path, _CompatSource source) {
    for (var i = 0; i < source.length; i++) {
      final line = source.masked[i];
      if (line.contains('ref.listenManual') && !line.contains('=')) {
        _report('showcase_listen_manual_handle', source, i, line.indexOf('ref.listenManual'));
      }
      if (line.contains('prev != null') && _near(source, i, 'showcase', 12)) {
        _report('showcase_prev_null_guard', source, i, line.indexOf('prev'));
      }
      if (RegExp(r'\bShowcaseView\s*\.\s*register\s*\(\s*\)').hasMatch(line)) {
        _report('showcase_default_scope', source, i, line.indexOf('ShowcaseView'));
      }
      if (line.contains('disposeOnTap: true') && !_near(source, i, 'onTargetClick', 4)) {
        _report('showcase_dispose_on_tap', source, i, line.indexOf('disposeOnTap'));
      }
    }
  }

  void _scanAsyncRules(
    String path,
    _CompatSource source,
    List<_ClassSpan> classes,
    List<_MethodSpan> methods,
  ) {
    for (final method in methods) {
      final classSpan = classes.firstWhere(
        (candidate) => candidate.contains(method.start),
        orElse: () => _ClassSpan.none,
      );
      if (!classSpan.isNotifier) continue;
      for (var i = method.start; i <= method.end; i++) {
        if (!source.masked[i].contains('await ')) continue;
        if (!_hasImmediateGuard(source, i, method.end, 'ref')) {
          // The dedicated first-release rule reports a richer AST diagnostic.
          continue;
        }
      }
    }
  }

  void _scanNotifierRules(
    String path,
    _CompatSource source,
    List<_ClassSpan> classes,
    List<_MethodSpan> methods,
  ) {
    for (final classSpan in classes.where((span) => span.isNotifier)) {
      final classMethods = methods.where((method) => classSpan.contains(method.start)).toList();
      for (final method in classMethods) {
        if (method.name == 'build') continue;

        var hasWatch = false;
        var hasEnsure = false;
        var hasMutationDependency = false;
        var hasNullRepoReturn = false;
        for (var i = method.start; i <= method.end; i++) {
          final line = source.masked[i];
          if (line.contains('ref.watch(')) hasWatch = true;
          if (line.contains('_ensure')) hasEnsure = true;
          if (line.contains('_repository') ||
              line.contains('_repo') ||
              line.contains('Repository') ||
              line.contains('ref.read(')) {
            hasMutationDependency = true;
          }
          if (RegExp(
            r'if\s*\(\s*_\w*(?:repo|repository)\w*\s*==\s*null\s*\)\s*return',
          ).hasMatch(line)) {
            hasNullRepoReturn = true;
          }
        }
        if (hasWatch) {
          _report('notifier_watch_method', source, method.start, 0);
        }
        if (_isMutationMethod(method.name) &&
            !hasEnsure &&
            (hasMutationDependency || hasNullRepoReturn)) {
          _report('notifier_ensure_deps', source, method.start, 0);
        }
      }
    }
  }

  void _scanWarningRules(String path, _CompatSource source, List<_MethodSpan> methods) {
    for (var i = 0; i < source.length; i++) {
      final line = source.masked[i];
      if (RegExp(r'\b(?:EdgeInsets|BorderRadius|Radius|SizedBox)\s*\([^)]*\d').hasMatch(line) ||
          RegExp(r'\b(?:EdgeInsets|BorderRadius|Radius)\.\w+\s*\([^)]*\d').hasMatch(line) ||
          RegExp(r'\bColor\s*\(\s*0x[0-9A-Fa-f]+').hasMatch(line)) {
        _report('style_raw_token', source, i, 0);
      }
      if (RegExp(r'\bListView\s*\([^)]*\bchildren\s*:').hasMatch(line)) {
        _report('perf_listview_children', source, i, line.indexOf('ListView'));
      }
      if (RegExp(
        r'\bstate\s*=\s*state\.copyWith\s*\([^)]*(?:rawJson|response|json)',
      ).hasMatch(line)) {
        _report('state_raw_response', source, i, line.indexOf('state'));
      }
      if (_isDataPath(path) &&
          RegExp(r'\b(?:print|debugPrint|log)\s*\(').hasMatch(line) &&
          _near(source, i, 'rethrow', 6)) {
        _report('data_log_rethrow', source, i, 0);
      }
      if (RegExp(r'\b(?:Crash\.|FirebaseCrashlytics)').hasMatch(line) &&
          RegExp(
            r'\b(?:email|name|phone|token|password|ssn|address|userId)\b',
            caseSensitive: false,
          ).hasMatch(line)) {
        _report('crash_possible_pii', source, i, 0);
      }
      if (RegExp(r'\bCrash\.(?:error|fatal|record|log)\s*\(').hasMatch(line) &&
          !line.contains('unawaited') &&
          !line.contains('await')) {
        _report('crash_unawaited_send', source, i, 0);
      }
    }

    for (final method in methods.where((method) => method.name == 'build')) {
      for (var i = method.start; i <= method.end; i++) {
        final line = source.masked[i];
        if (RegExp(r'\.(?:sort|where|map|toList)\s*\(').hasMatch(line) ||
            RegExp(r'\b(?:DateFormat|RegExp)\s*\(').hasMatch(line)) {
          _report('perf_build_work', source, i, 0);
        }
      }
    }
  }

  void _report(String name, _CompatSource source, int lineIndex, int column) {
    final diagnosticCode = FlutterSkillScannerCompat.codes[name];
    if (diagnosticCode == null) return;
    final safeLine = lineIndex.clamp(0, source.length - 1);
    final safeColumn = column < 0 ? 0 : column;
    final lineLength = source.original[safeLine].length;
    final offset = source.lineOffsets[safeLine] + safeColumn.clamp(0, lineLength);
    final length = lineLength == 0 ? 1 : (lineLength - safeColumn).clamp(1, lineLength);
    rule.reportAtOffset(offset, length, diagnosticCode: diagnosticCode);
  }

  bool _isRedirectWatch(_CompatSource source, int lineIndex) =>
      source.masked[lineIndex].contains('ref.watch(') && _near(source, lineIndex, 'redirect:', 12);

  bool _isRedirectLoadingBounce(_CompatSource source, int lineIndex, String code) {
    if (!_near(source, lineIndex, 'redirect:', 12)) return false;
    if (!RegExp(r'''return\s+['"][^'"]*(?:splash|loading|home|/)''').hasMatch(code)) {
      return false;
    }
    return _near(source, lineIndex, 'isLoading', 8) || _near(source, lineIndex, 'loading', 8);
  }

  bool _isInitStateRead(_CompatSource source, int lineIndex) =>
      source.masked[lineIndex].contains('ref.read(') && _near(source, lineIndex, 'initState', 8);

  bool _hasStringNavigation(String code, String masked) {
    final contextNav = RegExp(
      r'''\bcontext\s*\.\s*(?:go|push|replace|pushReplacement)\s*\(\s*['"]''',
    );
    final routerNav = RegExp(
      r'''\bGoRouter\s*\.\s*of\s*\([^)]*\)\s*\.\s*(?:go|push|replace|pushReplacement)\s*\(\s*['"]''',
    );
    return [...contextNav.allMatches(code), ...routerNav.allMatches(code)].any((match) {
      if (match.start >= masked.length) return false;
      return masked.substring(match.start, match.end).trim().isNotEmpty;
    });
  }

  bool _hasHardcodedUiString(String code, String path) {
    if (path.endsWith('_strings.dart') || path.contains('/l10n/')) return false;
    return RegExp(r'''\b(?:Text|Tooltip|Semantics)\s*\(\s*['"][^'"]+['"]''').hasMatch(code) ||
        RegExp(
          r'''\b(?:title|label|tooltip|hintText|helperText|errorText)\s*:\s*['"][^'"]+['"]''',
        ).hasMatch(code);
  }

  bool _isMutableMixinField(_CompatSource source, int lineIndex) {
    final line = source.masked[lineIndex];
    if (!RegExp(
      r'^\s*(?!final\b)(?!const\b)(?:var|int|double|num|bool|String|List|Map|Set)\b[^;=]*=',
    ).hasMatch(line)) {
      return false;
    }
    return _near(source, lineIndex, 'mixin ', 8);
  }

  bool _isMapDynamicReturn(String line, String path) {
    if (_isDataPath(path)) return false;
    if (line.contains('toJson') || line.contains('fromJson') || line.contains('RequestBody')) {
      return false;
    }
    return RegExp(r'\bMap\s*<\s*String\s*,\s*dynamic\s*>\s+\w+\s*\(').hasMatch(line);
  }

  bool _dispatchesSnackbarFromUi(String line) =>
      line.contains('ScaffoldMessenger.of(') ||
      line.contains('ScaffoldMessenger.maybeOf(') ||
      line.contains('SnackBarUtils.show');

  bool _clampsTextScaling(String line) =>
      line.contains('withClampedTextScaling') ||
      line.contains('maxScaleFactor') ||
      line.contains('textScaleFactor:') ||
      line.contains('TextScaler.linear(1');

  bool _hasConcreteLayerClass(_CompatSource source) {
    for (final line in source.masked) {
      if (RegExp(r'\bclass\s+\w+(?:Repository|Datasource)\b').hasMatch(line)) {
        return true;
      }
    }
    return false;
  }

  bool _hasConcreteLayerDependencyLine(String line) {
    if (RegExp(r'^\s*(?:abstract\s+interface\s+)?class\b').hasMatch(line)) {
      return false;
    }
    if (RegExp(
      r'\b(?:final\s+)?(?!I)[A-Z]\w*(?:Repository|Datasource)\s+_\w+\s*;',
    ).hasMatch(line)) {
      return true;
    }
    if (RegExp(r'[(,]\s*(?!I)[A-Z]\w*(?:Repository|Datasource)\s+\w+').hasMatch(line)) {
      return true;
    }
    return false;
  }

  bool _isPrivateNamespaceConstructor(_CompatSource source, _ClassSpan classSpan) {
    final text = source.masked.sublist(classSpan.start, classSpan.end + 1).join('\n');
    final annotationStart = classSpan.start - 3 < 0 ? 0 : classSpan.start - 3;
    final leadingText = source.masked.sublist(annotationStart, classSpan.start + 1).join('\n');
    if (leadingText.contains('@freezed') || leadingText.contains('@Freezed')) return false;
    if (!RegExp('${classSpan.name}._\\s*\\(\\s*\\)\\s*;').hasMatch(text)) return false;
    return !RegExp(r'\babstract\s+final\s+class\b').hasMatch(source.masked[classSpan.start]);
  }

  bool _hasImmediateGuard(_CompatSource source, int awaitLine, int methodEnd, String target) {
    for (var i = awaitLine + 1; i <= methodEnd && i < source.length; i++) {
      final line = source.masked[i].trim();
      if (line.isEmpty) continue;
      return line.contains('if (!$target.mounted)') && line.contains('return');
    }
    return false;
  }

  int _firstLine(_CompatSource source, String needle) {
    for (var i = 0; i < source.length; i++) {
      if (source.masked[i].contains(needle)) return i;
    }
    return 0;
  }

  bool _near(_CompatSource source, int lineIndex, String needle, int distance) {
    final start = lineIndex - distance < 0 ? 0 : lineIndex - distance;
    final end = lineIndex + distance >= source.length ? source.length - 1 : lineIndex + distance;
    for (var i = start; i <= end; i++) {
      if (source.masked[i].contains(needle)) return true;
    }
    return false;
  }

  List<_ClassSpan> _classes(_CompatSource source) {
    final classes = <_ClassSpan>[];
    for (var i = 0; i < source.length; i++) {
      final line = source.masked[i];
      final match = RegExp(r'\bclass\s+([A-Za-z_][A-Za-z0-9_]*)\b').firstMatch(line);
      if (match == null) continue;

      final name = match.group(1) ?? '';
      final signature = StringBuffer(line);
      var start = i;
      var braceDepth = _braceDelta(line);
      var foundOpenBrace = line.contains('{');

      while (!foundOpenBrace && start + 1 < source.length) {
        start++;
        signature.write(' ${source.masked[start]}');
        foundOpenBrace = source.masked[start].contains('{');
        braceDepth += _braceDelta(source.masked[start]);
      }

      var end = start;
      while (foundOpenBrace && braceDepth > 0 && end + 1 < source.length) {
        end++;
        braceDepth += _braceDelta(source.masked[end]);
      }

      final sig = signature.toString();
      classes.add(
        _ClassSpan(
          name: name,
          start: i,
          end: end,
          isNotifier:
              name.endsWith('Notifier') ||
              sig.contains(r'extends _$') ||
              sig.contains('extends Notifier') ||
              sig.contains('extends AsyncNotifier'),
        ),
      );
      i = end;
    }
    return classes;
  }

  List<_MethodSpan> _methods(_CompatSource source, _ClassSpan classSpan) {
    final methods = <_MethodSpan>[];
    final methodRegex = RegExp(
      r'^\s*(?:@override\s+)?(?:static\s+)?(?:Future(?:<[^>]+>)?|Stream(?:<[^>]+>)?|void|[A-Za-z_][A-Za-z0-9_<>,? ]*)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(',
    );

    for (var i = classSpan.start + 1; i < classSpan.end; i++) {
      final line = source.masked[i];
      if (line.contains('factory ')) continue;
      final match = methodRegex.firstMatch(line);
      if (match == null) continue;
      final name = match.group(1) ?? '';
      if (_isControlKeyword(name)) continue;

      if (line.contains('=>')) {
        methods.add(_MethodSpan(name: name, start: i, end: i));
        continue;
      }

      var start = i;
      var foundOpenBrace = line.contains('{');
      var braceDepth = _braceDelta(line);
      while (!foundOpenBrace && start + 1 < classSpan.end) {
        start++;
        foundOpenBrace = source.masked[start].contains('{');
        braceDepth += _braceDelta(source.masked[start]);
      }
      if (!foundOpenBrace) continue;

      var end = start;
      while (braceDepth > 0 && end + 1 <= classSpan.end) {
        end++;
        braceDepth += _braceDelta(source.masked[end]);
      }

      methods.add(_MethodSpan(name: name, start: i, end: end));
      i = end;
    }
    return methods;
  }

  bool _isControlKeyword(String name) =>
      name == 'if' || name == 'for' || name == 'while' || name == 'switch' || name == 'catch';

  int _braceDelta(String line) => _count(line, '{') - _count(line, '}');

  int _count(String text, String char) {
    var count = 0;
    for (var i = 0; i < text.length; i++) {
      if (text[i] == char) count++;
    }
    return count;
  }

  bool _isMutationMethod(String name) =>
      RegExp(r'^(?:create|update|delete|set|reorder|save|add|remove)[A-Z_]?').hasMatch(name);

  bool _isDataPath(String path) => path.contains('/data/') || path.contains('/repositories/');
  bool _isDatasourcePath(String path) => path.contains('/data/datasources/');
  bool _isRepositoryPath(String path) => path.contains('/repositories/');
  bool _isDomainPath(String path) => path.contains('/domain/');

  bool _isFeatureWidgetWrongPath(String path) =>
      path.contains('/features/') &&
      path.contains('/widgets/') &&
      !path.contains('/presentation/widgets/');

  bool _isAtomicNoProviderPath(String path) =>
      path.contains('/core/widgets/atoms/') ||
      path.contains('/core/widgets/molecules/') ||
      path.contains('/core/widgets/templates/');

  bool _isUiFile(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.startsWith('lib/core/widgets/') ||
        normalized.startsWith('lib/core/dialogs/') ||
        normalized.startsWith('lib/core/sheets/') ||
        normalized.contains('/presentation/widgets/') ||
        normalized.contains('/presentation/screens/') ||
        normalized.contains('/presentation/dialogs/') ||
        normalized.contains('/presentation/sheets/');
  }

  bool _isAppRootFile(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized == 'lib/main.dart' ||
        normalized == 'lib/app.dart' ||
        normalized.endsWith('/app.dart') ||
        normalized.endsWith('/app_root.dart');
  }

  bool _isTestFile(String path) => path.startsWith('test/') || path.endsWith('_test.dart');

  bool _isKeyRegistryFile(String path) {
    final normalized = path.replaceAll('\\', '/').toLowerCase();
    return normalized.endsWith('/app_widget_keys.dart') ||
        normalized.endsWith('/widget_keys.dart') ||
        normalized.endsWith('/e2e_keys.dart') ||
        normalized.endsWith('/app_keys.dart') ||
        normalized.endsWith('/keys.dart');
  }

  String _relativePath(String path) {
    final normalized = path.replaceAll('\\', '/');
    for (final marker in ['/lib/', '/test/']) {
      final index = normalized.lastIndexOf(marker);
      if (index >= 0) return normalized.substring(index + 1);
    }
    return normalized;
  }
}

final class _CompatSource {
  _CompatSource(String text) {
    original.addAll(text.split('\n'));
    lineOffsets.addAll(_lineOffsets(text));
    final scan = _scanText(text);
    code.addAll(scan.code.split('\n'));
    masked.addAll(scan.masked.split('\n'));
  }

  final original = <String>[];
  final code = <String>[];
  final masked = <String>[];
  final lineOffsets = <int>[];

  int get length => original.length;

  List<int> _lineOffsets(String text) {
    final result = <int>[0];
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 10) result.add(i + 1);
    }
    return result;
  }

  _SourceScan _scanText(String text) {
    final codeBuffer = StringBuffer();
    final maskedBuffer = StringBuffer();
    var inLineComment = false;
    var inBlockComment = false;
    var quote = '';
    var inTripleString = false;
    var inRawString = false;
    var escaped = false;

    void writeBoth(String value) {
      codeBuffer.write(value);
      maskedBuffer.write(value);
    }

    void writeSpaces(int count) {
      codeBuffer.write(' ' * count);
      maskedBuffer.write(' ' * count);
    }

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      final next = i + 1 < text.length ? text[i + 1] : '';

      if (char == '\n') {
        writeBoth(char);
        inLineComment = false;
        if (quote.isNotEmpty && !inTripleString) {
          quote = '';
          escaped = false;
        }
        continue;
      }

      if (quote.isNotEmpty) {
        codeBuffer.write(inTripleString ? ' ' : char);
        maskedBuffer.write(' ');
        if (inTripleString) {
          if (_startsTripleQuote(text, i, quote)) {
            writeSpaces(2);
            quote = '';
            inTripleString = false;
            inRawString = false;
            i += 2;
          }
          continue;
        }
        if (escaped) {
          escaped = false;
        } else if (!inRawString && char == r'\') {
          escaped = true;
        } else if (char == quote) {
          quote = '';
          inRawString = false;
        }
        continue;
      }

      if (inLineComment) {
        writeSpaces(1);
        continue;
      }

      if (inBlockComment) {
        if (char == '*' && next == '/') {
          writeSpaces(2);
          inBlockComment = false;
          i++;
          continue;
        }
        writeSpaces(1);
        continue;
      }

      if (char == '/' && next == '/') {
        writeSpaces(2);
        inLineComment = true;
        i++;
        continue;
      }
      if (char == '/' && next == '*') {
        writeSpaces(2);
        inBlockComment = true;
        i++;
        continue;
      }

      final rawPrefix =
          (char == 'r' || char == 'R') && i + 1 < text.length && _isQuote(text[i + 1]);
      if (rawPrefix || _isQuote(char)) {
        final quoteIndex = rawPrefix ? i + 1 : i;
        quote = text[quoteIndex];
        inRawString = rawPrefix;
        inTripleString = _startsTripleQuote(text, quoteIndex, quote);
        final prefixLength = rawPrefix ? 1 : 0;
        final quoteLength = inTripleString ? 3 : 1;
        if (inTripleString) {
          writeSpaces(prefixLength + quoteLength);
        } else {
          codeBuffer.write(text.substring(i, quoteIndex + quoteLength));
          maskedBuffer.write(' ' * (prefixLength + quoteLength));
        }
        i = quoteIndex + quoteLength - 1;
        continue;
      }

      writeBoth(char);
    }

    return _SourceScan(codeBuffer.toString(), maskedBuffer.toString());
  }

  bool _isQuote(String char) => char == '\'' || char == '"';

  bool _startsTripleQuote(String text, int index, String quote) =>
      index + 2 < text.length &&
      text[index] == quote &&
      text[index + 1] == quote &&
      text[index + 2] == quote;
}

final class _SourceScan {
  const _SourceScan(this.code, this.masked);

  final String code;
  final String masked;
}

final class _ClassSpan {
  const _ClassSpan({
    required this.name,
    required this.start,
    required this.end,
    required this.isNotifier,
  });

  static const none = _ClassSpan(name: '', start: -1, end: -1, isNotifier: false);

  final String name;
  final int start;
  final int end;
  final bool isNotifier;

  bool contains(int line) => line >= start && line <= end;
}

final class _MethodSpan {
  const _MethodSpan({required this.name, required this.start, required this.end});

  final String name;
  final int start;
  final int end;
}
