import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> servicesExtendedSourceRules = [
  /// Keep static service facades tiny and direct.
  ///
  /// Why: Pure helper namespaces should not hide clock/random work. SDK facades are allowed
  /// only when they stay Crash-style boring: tiny fire-and-forget public API, direct SDK calls,
  /// no returned data/state, and no backend/fake/debug injection seams.
  scannerRule(
    code: const LintCode(
      'service_static_side_effect',
      'Static service facade is not tiny and direct.',
      correctionMessage:
          'Keep the facade tiny, direct, and fire-and-forget. Public methods must return only void/Future<void>; move returned data/state to a provider/repository boundary.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags static helper/facade classes that hide clock/random work or grow wider than the plain boring service-facade pattern.',
    scan: (reporter, context) {
      for (final classSpan in context.classes) {
        final body = context.source.masked.sublist(classSpan.start, classSpan.end + 1).join('\n');
        if (!RegExp(r'^\s*abstract\s+final\s+class\b', multiLine: true).hasMatch(body)) {
          continue;
        }

        if (_clockOrRandomWork.hasMatch(body)) {
          reporter.report(context, classSpan.start, 0);
          continue;
        }

        if (!_sdkOrIoWork.hasMatch(body)) continue;
        if (!_hasOverbuiltStaticFacadeSeam(body) &&
            !_hasPublicStaticDataApi(body) &&
            _publicStaticMethodCount(body) <= 4) {
          continue;
        }

        reporter.report(context, classSpan.start, 0);
      }
    },
  ),

  /// Do not allocate Random per call.
  ///
  /// Why: Flags Random construction inside methods. Hoist Random to a module-level final and
  /// reuse it.
  scannerRule(
    code: const LintCode(
      'service_random_per_call',
      'Do not allocate Random per call.',
      correctionMessage: 'Hoist Random to a module-level final and reuse it.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags Random construction inside methods so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final method in context.methods) {
        for (var i = method.start; i <= method.end; i++) {
          final line = context.source.masked[i];
          if (RegExp(r'\b(?:math\.)?Random\s*\(').hasMatch(line)) {
            reporter.report(context, i, line.indexOf('Random'));
          }
        }
      }
    },
  ),

  /// Do not hide dependency construction behind null-coalescing fallbacks.
  ///
  /// Why: `dependency ?? ConcreteDependency()` makes production wiring implicit and bypasses
  /// the provider/repository/datasource boundary. Require the dependency and wire the concrete
  /// implementation at the composition root instead.
  scannerRule(
    code: const LintCode(
      'hidden_dependency_fallback',
      'Do not instantiate dependency fallbacks behind ??.',
      correctionMessage:
          'Require the dependency in the constructor/provider/function and wire the concrete implementation at the composition root.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags dependency fallback constructors such as `client ?? Client()` in production code.',
    scan: (reporter, context) {
      if (context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final match =
            _hiddenDependencyFallback.firstMatch(line) ??
            _hiddenFunctionDependencyFallback.firstMatch(line);
        if (match == null) continue;
        reporter.report(context, i, match.start);
      }
    },
  ),

  /// Do not make dependency/function seams optional or defaulted.
  ///
  /// Why: Optional callback dependencies such as `clock`, `delay`,
  /// `generator`, `authenticator`, or `createExecution` recreate production
  /// fallbacks inside constructors. Require the dependency and wire the
  /// production implementation at the provider/composition root.
  scannerRule(
    code: const LintCode(
      'hidden_dependency_default_param',
      'Do not use optional/defaulted dependency seams.',
      correctionMessage:
          'Make dependency/function seams required and pass the production implementation from the provider/composition root.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags optional or defaulted dependency/function constructor parameters in production code.',
    scan: (reporter, context) {
      if (context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final match = _hiddenDependencyDefaultParam.firstMatch(line);
        if (match == null) continue;
        reporter.report(context, i, match.start);
      }
    },
  ),

  /// Do not inline concrete dependency constructors inside service wiring.
  ///
  /// Why: `Service(plugin: ConcretePlugin())` hides a dependency inside another
  /// constructor call. Give the dependency one provider/composition-root owner,
  /// then pass `ref.read(dependencyProvider)` into the service.
  scannerRule(
    code: const LintCode(
      'service_inline_concrete_dependency',
      'Do not inline concrete dependency constructors inside service wiring.',
      correctionMessage:
          'Move the dependency constructor to its own provider/composition root and pass the provider value into the service.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags named arguments such as `plugin: ConcretePlugin()` inside production service wiring.',
    scan: (reporter, context) {
      if (context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final match = _inlineConcreteDependency.firstMatch(line);
        if (match == null) continue;
        reporter.report(context, i, match.start);
      }
    },
  ),

  /// Do not watch stable provider dependencies inside service/repository wiring.
  ///
  /// Why: Service, repository, datasource, client, plugin, queue, and manager
  /// factories wire stable infrastructure dependencies. Watching those deps
  /// makes the factory reactive for no product reason and can recreate services
  /// unexpectedly. Use ref.read for composition-root wiring; reserve ref.watch
  /// for computed state that must update when inputs update.
  scannerRule(
    code: const LintCode(
      'service_provider_watch_dependency',
      'Use ref.read for stable infrastructure dependencies.',
      correctionMessage:
          'In service/repository/datasource/client provider factories, use ref.read for stable dependency wiring.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags ref.watch inside stable infrastructure provider factories so services are not recreated reactively for wiring-only dependencies.',
    scan: (reporter, context) {
      if (context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final column = line.indexOf('ref.watch(');
        if (column < 0) continue;
        if (!_insideStableInfrastructureProviderFactory(context, i)) continue;
        reporter.report(context, i, column);
      }
    },
  ),

  /// Do not hide nullable values behind primitive/string fallback defaults.
  ///
  /// Why: `value ?? false`, `value ?? 0`, `value ?? ''`, chained fallbacks, and
  /// `labelBuilder?.call(item) ?? item.toString()` erase the domain meaning of
  /// null. Use required inputs, explicit nullable branches, pattern matching, or
  /// typed value objects instead.
  scannerRule(
    code: const LintCode(
      'implicit_null_fallback',
      'Do not hide null handling behind sentinel fallbacks.',
      correctionMessage:
          'Use a required value, explicit nullable branch, pattern match, or typed domain value instead of primitive/string/toString/chained ?? fallbacks.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags primitive, empty collection/string, callback, toString, and chained null-coalescing fallbacks in production code.',
    scan: (reporter, context) {
      if (context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final match = _implicitNullFallbackMatch(line);
        if (match == null) continue;
        reporter.report(context, i, match.start);
      }
    },
  ),

  /// Avoid fire-and-forget calls in tests.
  ///
  /// Why: Flags unawaited calls from test files. Await the Future directly in tests and
  /// assert on the fake service.
  scannerRule(
    code: const LintCode(
      'fire_forget_in_tests',
      'Avoid fire-and-forget calls in tests.',
      correctionMessage: 'Await the Future directly in tests and assert on the fake service.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags unawaited calls from test files so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bunawaited\s*\(').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('unawaited'));
        }
      }
    },
  ),
];

final _clockOrRandomWork = RegExp(r'\b(?:DateTime\.now|Random\s*\()');
final _sdkOrIoWork = RegExp(r'\b(?:Firebase\w*|Hive\w*|SharedPreferences|HttpClient)\b');
final _hiddenDependencyFallback = RegExp(
  r'\?\?\s*(?:const\s+)?(?:[A-Z]\w*(?:Service|Repository|Datasource|DataSource|Client|'
  r'Plugin|Queue|Manager|Storage|Activities|EventBus)|FlutterLocalNotificationsPlugin|'
  r'DefaultCacheManager|RemoteMutationQueue|LiveActivities)\s*\(',
);
final _hiddenFunctionDependencyFallback = RegExp(
  r'\b[A-Za-z_]\w*(?:Factory|Delay|Clock|Generator|Builder|Resolver|Authenticator)'
  r'\s*\?\?\s*(?:[A-Za-z_]\w*|\(\s*\([^)]*\)\s*=>)',
);
final _hiddenDependencyDefaultParam = RegExp(
  r'\b(?:[A-Za-z_]\w*(?:Factory|Delay|Clock|Generator|Builder|Resolver|Authenticator)|'
  r'CreateFunctionExecution|OAuthAuthenticator|OAuthNonceGenerator|DeleteAccountPollDelay)'
  r'\?\s+[A-Za-z_]\w*\s*[,)}=]',
);
final _inlineConcreteDependency = RegExp(
  r'\b[A-Za-z_]\w*\s*:\s*(?:const\s+)?(?:[A-Z]\w*(?:Service|Repository|Datasource|DataSource|'
  r'Client|Plugin|Queue|Manager|Storage|Activities|EventBus)|FlutterLocalNotificationsPlugin|'
  r'DefaultCacheManager|RemoteMutationQueue|LiveActivities)\s*\(',
);
final _stableInfrastructureProviderSignature = RegExp(
  r'\b(?:Future\s*<[^>]+>|Stream\s*<[^>]+>|[A-ZI][A-Za-z0-9_<>,? ]*)\s+'
  r'([a-zA-Z_]\w*)\s*\(\s*Ref\s+ref\b',
);
final _stableInfrastructureName = RegExp(
  r'(?:Service|Repository|Datasource|DataSource|Client|Plugin|Queue|Manager|Storage|'
  r'Activities|EventBus)\b',
);
final _primitiveNullFallback = RegExp(
  r'''\?\?\s*(?:false\b|true\b|0(?:\.0)?\b|''|""|'''
  r'''const\s+(?:<[^>]+>\s*)?\[\]|(?:<[^>]+>\s*)?\[\]|'''
  r'''const\s+(?:<[^>]+>\s*)?\{\}|(?:<[^>]+>\s*)?\{\})''',
);
final _callbackNullFallback = RegExp(r'\?\.\s*call\s*\([^)]*\)\s*\?\?');
final _toStringNullFallback = RegExp(r'\?\?\s*[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*\.toString\s*\(');
final _chainedNullFallback = RegExp(r'\?\?(?![=])(?:[^?\n]|\?(?!\?))*\?\?(?![=])');
final _publicStaticMethod = RegExp(
  r'\bstatic\s+(?:Future<[^>]+>|[A-Za-z_]\w*(?:<[^>]+>)?|void)\s+(?!_)[A-Za-z_]\w*\s*\(',
);
final _overbuiltStaticFacadeSeam = RegExp(
  r'\b(?:debug(?:Reset|Configure|Use|Set|Override)\w*|resetForTest(?:ing)?|'
  r'set(?:Instance|Backend|Client|Provider)\w*|'
  r'overrideWithValue|Fake[A-Z]\w*|Mock[A-Z]\w*|'
  r'abstract\s+interface\s+class|Backend|backend|ProviderScope|ServiceLocator|serviceLocator)\b',
);

final _publicStaticDataMethod = RegExp(
  r'\bstatic\s+(?!(?:void|Future\s*<\s*void\s*>)\s+)'
  r'(?:Future(?:\s*<[^>]+>)?|[A-Za-z_]\w*(?:<[^>]+>)?)\s+'
  r'(?!get\b|set\b|_)\w+\s*\(',
);

final _publicStaticGetter = RegExp(r'\bstatic\s+[A-Za-z_]\w*(?:<[^>]+>)?\s+get\s+(?!_)\w+\b');

final _publicStaticField = RegExp(
  r'\bstatic\s+(?:final|var|late\s+final|late|const)\s+'
  r'(?:[A-Za-z_]\w*(?:<[^>]+>)?\s+)?(?!_)\w+\b',
);

int _publicStaticMethodCount(String body) {
  return _publicStaticMethod.allMatches(body).length;
}

bool _hasOverbuiltStaticFacadeSeam(String body) {
  return _overbuiltStaticFacadeSeam.hasMatch(body);
}

bool _hasPublicStaticDataApi(String body) {
  for (final line in body.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('//') || trimmed.startsWith('@')) continue;
    if (_publicStaticDataMethod.hasMatch(trimmed)) return true;
    if (_publicStaticGetter.hasMatch(trimmed)) return true;
    if (_publicStaticField.hasMatch(trimmed)) return true;
  }
  return false;
}

RegExpMatch? _implicitNullFallbackMatch(String line) {
  if (!line.contains('??') || line.contains('??=')) return null;
  return _callbackNullFallback.firstMatch(line) ??
      _toStringNullFallback.firstMatch(line) ??
      _chainedNullFallback.firstMatch(line) ??
      _primitiveNullFallback.firstMatch(line);
}

bool _insideStableInfrastructureProviderFactory(SourceScannerContext context, int lineIndex) {
  final start = lineIndex - 12 < 0 ? 0 : lineIndex - 12;
  final window = context.source.masked.sublist(start, lineIndex + 1).join(' ');
  if (!RegExp(r'@(?:R|r)iverpod\b').hasMatch(window)) return false;

  final match = _stableInfrastructureProviderSignature.firstMatch(window);
  if (match == null) return false;

  final signature = match.group(0) ?? '';
  final functionName = match.group(1) ?? '';
  return _stableInfrastructureName.hasMatch(signature) ||
      _stableInfrastructureName.hasMatch(functionName);
}
