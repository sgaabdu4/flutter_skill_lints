import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
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
      correctionMessage: 'Keep the facade tiny, direct, and fire-and-forget. Public methods must return only void/Future<void>; move returned data/state to a provider/repository boundary.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags static helper/facade classes that hide clock/random work or grow wider than the plain boring service-facade pattern.',
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
  /// Why: Flags dart:math Random construction inside any function, method or closure body.
  /// Hoist Random to a module-level final and reuse it.
  scannerRule(
    code: const LintCode(
      'service_random_per_call',
      'Do not allocate Random per call.',
      correctionMessage: 'Hoist Random to a module-level final and reuse it.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags dart:math Random construction inside function, method and closure bodies so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final visitor = _PerCallRandomVisitor();
      context.unit.accept(visitor);
      for (final offset in visitor.offsets) {
        reporter.reportOffset(context, offset);
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
      correctionMessage: 'Require the dependency in the constructor/provider/function and wire the concrete implementation at the composition root.',
      severity: DiagnosticSeverity.ERROR,
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
      correctionMessage: 'Make dependency/function seams required and pass the production implementation from the provider/composition root.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags optional or defaulted dependency/function constructor parameters in production code.',
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
      correctionMessage: 'Move the dependency constructor to its own provider/composition root and pass the provider value into the service.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags named arguments such as `plugin: ConcretePlugin()` inside production service wiring.',
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
  /// unexpectedly. Notifier members, including `build()`, read stable
  /// infrastructure the same way and watch only reactive state. Use ref.read
  /// for composition-root wiring; reserve ref.watch for the provider that
  /// intentionally owns reactivity, such as rebuilding a client from live
  /// config or credential state.
  scannerRule(
    code: const LintCode(
      'service_provider_watch_dependency',
      'Use ref.read for stable infrastructure dependencies.',
      correctionMessage: 'In service/repository/datasource/client provider factories and notifier members, use ref.read for stable dependency wiring.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags ref.watch of stable infrastructure providers inside stable infrastructure provider factories, and ref.watch of resolved stable infrastructure values inside Riverpod notifier members. Watching resolved reactive state or config values is allowed.',
    scan: (reporter, context) {
      if (context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        for (
          var column = line.indexOf('ref.watch(');
          column >= 0;
          column = line.indexOf('ref.watch(', column + 1)
        ) {
          final watch = _stableInfrastructureFactoryWatch(context, i, column);
          if (watch == null || _watchesReactiveValue(watch)) continue;
          reporter.report(context, i, column);
        }
      }
    },
  ),

  /// Destructure config values read from providers.
  ///
  /// Why: The config -> client -> services chain reads config through an
  /// object pattern, `final BackendConfig(:endpoint, :apiKey) =
  /// ref.watch(backendConfigProvider);`, so the fields a client needs are
  /// named where the provider is read. A config local that is only read
  /// through its properties should be destructured instead.
  scannerRule(
    code: const LintCode(
      'riverpod_config_destructuring',
      'Destructure config values read from providers.',
      correctionMessage: 'Use an object pattern such as `final BackendConfig(:endpoint, :apiKey) = ref.watch(backendConfigProvider);` instead of reading properties from a config local. For one field, read it inline: `ref.watch(backendConfigProvider).endpoint`.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags a local initialized from ref.watch/ref.read of a provider whose resolved value is a `*Config` class when the local is only used through property reads.',
    scan: (reporter, context) {
      if (context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        for (final match in _refWatchOrRead.allMatches(context.source.masked[i])) {
          if (_isPropertyOnlyConfigLocal(context, i, match.start)) {
            reporter.report(context, i, match.start);
          }
        }
      }
    },
  ),

  /// Do not hide nullable values behind empty string/collection fallbacks.
  ///
  /// Why: `value ?? ''`, `value ?? const []`, chained fallbacks, and
  /// `labelBuilder?.call(item) ?? item.toString()` erase the domain meaning of
  /// null. Use required inputs, explicit nullable branches, pattern matching, or
  /// typed value objects instead. Plain bool/num fallbacks such as
  /// `ModalRoute.of(this)?.isCurrent ?? false` (context-ui.md) stay allowed.
  scannerRule(
    code: const LintCode(
      'implicit_null_fallback',
      'Do not hide null handling behind sentinel fallbacks.',
      correctionMessage: 'Use a required value, explicit nullable branch, pattern match, or typed domain value instead of empty string/collection, toString, callback, or chained ?? fallbacks.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Flags empty collection/string, callback, toString, and chained null-coalescing fallbacks in production code.',
    scan: (reporter, context) {
      if (context.isTestFile) return;

      for (var i = 0; i < context.source.length; i++) {
        final column = _implicitNullFallbackColumn(
          context.source.masked[i],
          context.source.code[i],
        );
        if (column != null) reporter.report(context, i, column);
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
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags unawaited calls from test files so the Flutter skill violation is shown during analysis.',
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
final _refWatchOrRead = RegExp(r'\bref\.(?:watch|read)\(');
final _stableInfrastructureName = RegExp(
  r'(?:Service|Repository|Datasource|DataSource|Client|Plugin|Queue|Manager|Storage|'
  r'Activities|EventBus)\b',
);
final _emptyCollectionNullFallback = RegExp(
  r'''\?\?\s*(?:const\s+(?:<[^>]+>\s*)?\[\]|(?:<[^>]+>\s*)?\[\]|'''
  r'''const\s+(?:<[^>]+>\s*)?\{\}|(?:<[^>]+>\s*)?\{\})''',
);
// Matched against unmasked code: the masked line blanks string literals.
final _emptyStringNullFallback = RegExp(r'''^\?\?\s*r?(?:''|"")(?!['"])''');
final _nullFallbackOperator = RegExp(r'\?\?(?!=)');
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

int? _implicitNullFallbackColumn(String masked, String code) {
  if (!masked.contains('??') || masked.contains('??=')) return null;
  final match =
      _callbackNullFallback.firstMatch(masked) ??
      _toStringNullFallback.firstMatch(masked) ??
      _chainedNullFallback.firstMatch(masked) ??
      _emptyCollectionNullFallback.firstMatch(masked);
  if (match != null) return match.start;
  for (final fallback in _nullFallbackOperator.allMatches(masked)) {
    if (_emptyStringNullFallback.hasMatch(code.substring(fallback.start))) return fallback.start;
  }
  return null;
}

/// Returns the `ref.watch` invocation at [column] when it sits inside a
/// `@riverpod` factory whose resolved return type is stable infrastructure,
/// or when a Riverpod notifier member watches a resolved stable
/// infrastructure value.
MethodInvocation? _stableInfrastructureFactoryWatch(
  SourceScannerContext context,
  int lineIndex,
  int column,
) {
  final offset = context.source.lineOffsets[lineIndex] + column;
  final covering = context.unit.nodeCovering(offset: offset);
  final watch = covering?.thisOrAncestorOfType<MethodInvocation>();
  if (watch == null || watch.methodName.name != 'watch') return null;
  if (_isRiverpodNotifierMember(watch)) {
    final value = watch.staticType;
    return value != null && _isStableInfrastructureType(value) && !_isPersistStorage(watch)
        ? watch
        : null;
  }

  final start = lineIndex - 12 < 0 ? 0 : lineIndex - 12;
  final window = context.source.masked.sublist(start, lineIndex + 1).join(' ');
  if (!RegExp(r'@(?:R|r)iverpod\b').hasMatch(window)) return null;
  final declaration = watch.thisOrAncestorOfType<FunctionDeclaration>();
  final function = declaration?.declaredFragment?.element;
  if (function is! TopLevelFunctionElement) return null;
  return _isStableInfrastructureType(function.returnType) ? watch : null;
}

/// Whether [watch] sits in a class whose resolved supertypes include
/// Riverpod's `AnyNotifier`, the base of `Notifier`, `AsyncNotifier`,
/// `StreamNotifier` and the generated `_$X` classes.
bool _isRiverpodNotifierMember(MethodInvocation watch) {
  final element = watch.thisOrAncestorOfType<ClassDeclaration>()?.declaredFragment?.element;
  if (element == null) return false;
  return element.allSupertypes.any(
    (supertype) => supertype.element.name == 'AnyNotifier' && _isRiverpodLibrary(supertype.element),
  );
}

/// Whether [watch] is the storage argument of Riverpod's notifier
/// `persist(...)`, which the skill watches inside `build()`.
bool _isPersistStorage(MethodInvocation watch) {
  final arguments = watch.parent;
  final persist = arguments?.parent;
  if (arguments is! ArgumentList || persist is! MethodInvocation) return false;
  final element = persist.methodName.element;
  return element is MethodElement &&
      element.name == 'persist' &&
      _isRiverpodLibrary(element) &&
      arguments.arguments.first == watch;
}

bool _isRiverpodLibrary(Element element) =>
    element.library?.uri.toString().startsWith('package:riverpod/') ?? false;

/// A watched provider whose resolved value is not stable infrastructure is
/// reactive state or config (Notifier/AsyncNotifier state or a plain value
/// provider), so the factory intentionally rebuilds when it changes.
/// Unresolved or `Object`/`dynamic` values stay reported.
bool _watchesReactiveValue(MethodInvocation watch) {
  final value = watch.staticType;
  if (value is! InterfaceType || value.isDartCoreObject) return false;
  return !_isStableInfrastructureType(value);
}

bool _isStableInfrastructureType(DartType type) {
  var valueType = type;
  while (valueType is InterfaceType && _isAsyncWrapper(valueType)) {
    valueType = valueType.typeArguments.single;
  }
  if (valueType is! InterfaceType) return false;
  if (_stableInfrastructureName.hasMatch(valueType.element.name ?? '')) return true;
  return valueType.allSupertypes.any((supertype) {
    final element = supertype.element;
    return element.name == 'Service' &&
        element.library.identifier == 'package:appwrite/src/service.dart';
  });
}

/// Whether the `ref.watch`/`ref.read` at [column] initializes a local whose
/// resolved type is a `*Config` class and whose every use is a property read.
bool _isPropertyOnlyConfigLocal(SourceScannerContext context, int lineIndex, int column) {
  final offset = context.source.lineOffsets[lineIndex] + column;
  final read = context.unit.nodeCovering(offset: offset)?.thisOrAncestorOfType<MethodInvocation>();
  if (read == null) return false;
  final value = read.parent is AwaitExpression ? read.parent : read;
  final declaration = value?.parent;
  if (declaration is! VariableDeclaration || declaration.initializer != value) return false;
  final local = declaration.declaredFragment?.element;
  if (local is! LocalVariableElement) return false;
  final type = local.type;
  if (type is! InterfaceType || !(type.element.name ?? '').endsWith('Config')) return false;

  final uses = _LocalUses(local);
  declaration.thisOrAncestorOfType<FunctionBody>()?.accept(uses);
  return uses.propertyReads > 0 && uses.otherUses == 0;
}

/// Counts property reads of [local] (`config.endpoint`) and every other use.
final class _LocalUses extends RecursiveAstVisitor<void> {
  _LocalUses(this.local);

  final LocalVariableElement local;
  int propertyReads = 0;
  int otherUses = 0;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element != local) return;
    final property = switch (node.parent) {
      PrefixedIdentifier(:final prefix, :final identifier) when prefix == node => identifier,
      PropertyAccess(:final target, :final propertyName) when target == node => propertyName,
      _ => null,
    };
    if (property?.element is GetterElement) {
      propertyReads++;
    } else {
      otherUses++;
    }
  }
}

bool _isAsyncWrapper(InterfaceType type) {
  if (type.typeArguments.length != 1) return false;
  final name = type.element.name;
  final library = type.element.library.uri.toString();
  return (library == 'dart:async' && (name == 'Future' || name == 'Stream')) ||
      (library.startsWith('package:riverpod/') && name == 'AsyncValue');
}

final class _PerCallRandomVisitor extends RecursiveAstVisitor<void> {
  final offsets = <int>[];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type is InterfaceType &&
        type.element.name == 'Random' &&
        type.element.library.uri.toString() == 'dart:math' &&
        node.thisOrAncestorOfType<FunctionBody>() != null) {
      offsets.add(node.constructorName.type.name.offset);
    }
    super.visitInstanceCreationExpression(node);
  }
}
