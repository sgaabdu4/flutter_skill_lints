import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/riverpod_type_checkers.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> dataCrashSourceRules = [
  /// Avoid log-and-rethrow in data layers.
  ///
  /// Why: A catch that only reports the error and rethrows adds nothing: the
  /// notifier catches and reports it again. Delete the try/catch, or translate,
  /// recover, roll back, or swallow + log a local-first remote mirror instead.
  /// A Crash/Sentry/Crashlytics report followed by `rethrow` in the same catch
  /// reports the failure twice. One failed operation has one incident owner.
  scannerRule(
    code: const LintCode(
      'data_log_rethrow',
      'Avoid log-and-rethrow in data layers.',
      correctionMessage: 'Delete the try/catch and let the notifier catch and report once, or report and throw a mapped typed domain error.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags data-layer catch clauses that only log or report the caught error before rethrowing, and crash reports followed by a rethrow in the same catch.',
    scan: (reporter, context) {
      if (!context.isDataPath) return;
      final finder = _LogRethrowFinder();
      context.unit.accept(finder);
      final flaggedCatches = <CatchClause?>{};
      for (final statement in finder.statements) {
        flaggedCatches.add(statement.thisOrAncestorOfType<CatchClause>());
        _reportOffset(reporter, context, statement.offset);
      }
      final visitor = _CrashReportThenRethrowVisitor();
      context.unit.accept(visitor);
      for (final call in visitor.reports) {
        if (flaggedCatches.contains(call.thisOrAncestorOfType<CatchClause>())) continue;
        _reportOffset(reporter, context, call.offset);
      }
    },
  ),

  /// Crash reporting may include PII.
  ///
  /// Why: Flags possible PII values sent to crash reporting. Do not send email, name, phone,
  /// token, password, address, or user IDs.
  scannerRule(
    code: const LintCode(
      'crash_possible_pii',
      'Crash reporting may include PII.',
      correctionMessage: 'Do not send email, name, phone, token, password, address, or user IDs.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags possible PII values sent to crash reporting so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\b(?:Crash\.|FirebaseCrashlytics)').hasMatch(line) &&
            RegExp(
              r'\b(?:email|name|phone|token|password|ssn|address|userId)\b',
              caseSensitive: false,
            ).hasMatch(line)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),

  /// Sentry SDK imports and calls belong only in crash_service.dart.
  ///
  /// Why: error-reporting.md makes `crash_service.dart` the only SDK owner; feature
  /// code calls the `Crash` facade.
  scannerRule(
    code: const LintCode(
      'crash_direct_sentry_call',
      'Avoid Sentry SDK imports and calls outside crash_service.dart.',
      correctionMessage:
          'Route error reporting through Crash.init/error/log in crash_service.dart.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags Sentry package imports and resolved Sentry SDK calls outside crash_service.dart.',
    scan: (reporter, context) {
      if (context.isTestFile || _isCrashServiceFile(context)) return;
      final visitor = _SentryUseVisitor();
      context.unit.accept(visitor);
      for (final offset in visitor.offsets) {
        _reportOffset(reporter, context, offset);
      }
    },
  ),

  /// Do not hand-wire FlutterError.onError or PlatformDispatcher.onError.
  ///
  /// Why: error-reporting.md makes startup one owner and lets SDK-managed error
  /// integration replace hand-wired framework and dispatcher handlers. Only the
  /// Crashlytics branch inside the resolved `Crash` facade assigns them, to the SDK
  /// handler.
  scannerRule(
    code: const LintCode(
      'crash_custom_global_error_handler',
      'Avoid hand-wired FlutterError.onError or PlatformDispatcher.onError handlers.',
      correctionMessage: 'Let the crash SDK integration own framework and dispatcher errors; wire Crashlytics handlers only inside the Crash facade.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags assignments to FlutterError.onError or PlatformDispatcher.onError unless the Crash facade assigns a FirebaseCrashlytics handler.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      final visitor = _GlobalErrorHandlerVisitor();
      context.unit.accept(visitor);
      for (final assignment in visitor.assignments) {
        if (_isInsideCrashFacade(assignment) &&
            _referencesPackage(assignment.rightHandSide, 'firebase_crashlytics')) {
          continue;
        }
        _reportOffset(reporter, context, assignment.offset);
      }
    },
  ),

  /// Sentry sendDefaultPii must stay false.
  ///
  /// Why: error-reporting.md requires `sendDefaultPii = false`; the option attaches
  /// user identity and request data by default.
  scannerRule(
    code: const LintCode(
      'crash_sentry_send_default_pii',
      'Sentry sendDefaultPii must stay false.',
      correctionMessage: 'Set sendDefaultPii = false and scrub app-owned context in beforeSend.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags assignments to the Sentry sendDefaultPii option other than the literal false.',
    scan: (reporter, context) {
      final visitor = _SentryOptionAssignmentVisitor({'sendDefaultPii'});
      context.unit.accept(visitor);
      for (final assignment in visitor.assignments) {
        _reportOffset(reporter, context, assignment.offset);
      }
    },
  ),

  /// Sentry screenshots and view hierarchy stay disabled until accepted.
  ///
  /// Why: error-reporting.md keeps screenshots and view hierarchy disabled until each
  /// is accepted. Record an accepted capture surface by disabling this rule in
  /// analysis_options.yaml.
  scannerRule(
    code: const LintCode(
      'crash_sentry_capture_opt_in',
      'Sentry screenshot and view hierarchy capture must stay disabled until accepted.',
      correctionMessage: 'Keep attachScreenshot and attachViewHierarchy false, or record the accepted capture by disabling this rule in analysis_options.yaml.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Sentry attachScreenshot/attachViewHierarchy assignments other than the literal false.',
    scan: (reporter, context) {
      final visitor = _SentryOptionAssignmentVisitor({'attachScreenshot', 'attachViewHierarchy'});
      context.unit.accept(visitor);
      for (final assignment in visitor.assignments) {
        _reportOffset(reporter, context, assignment.offset);
      }
    },
  ),

  /// The Crash facade exposes only init, log and error.
  ///
  /// Why: error-reporting.md keeps `Crash` a tiny provider-neutral facade whose public
  /// API is `init`, `log` and `error`, with no runtime backend setters or extras.
  scannerRule(
    code: const LintCode(
      'crash_facade_public_api',
      'The Crash facade must expose only init, log and error.',
      correctionMessage: 'Make other members private; do not add backend setters, fakes or feature constants to Crash.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags public members of the Crash facade class other than init, log and error.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
        if (declaration.namePart.typeName.lexeme != 'Crash') continue;
        final body = declaration.body;
        if (body is! BlockClassBody) continue;
        for (final member in body.members) {
          final offset = _extraPublicCrashMemberOffset(member);
          if (offset != null) _reportOffset(reporter, context, offset);
        }
      }
    },
  ),

  /// Crash must not report its own send failures through Crash.error.
  ///
  /// Why: error-reporting.md makes a send failure a contained diagnostic that never
  /// recurses into `Crash.error`.
  scannerRule(
    code: const LintCode(
      'crash_error_recursion',
      'Crash must not call Crash.error from inside the facade.',
      correctionMessage:
          'Contain send failures with a local diagnostic instead of calling Crash.error.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags resolved Crash.error calls inside the Crash facade class.',
    scan: (reporter, context) {
      for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
        final crash = declaration.declaredFragment?.element;
        if (crash == null || crash.name != 'Crash') continue;
        final visitor = _CrashErrorCallVisitor(crash);
        declaration.accept(visitor);
        for (final call in visitor.calls) {
          _reportOffset(reporter, context, call.offset);
        }
      }
    },
  ),

  /// The Sentry auth token is a build-only secret.
  ///
  /// Why: error-reporting.md keeps `SENTRY_AUTH_TOKEN` out of source, app config and
  /// the runtime bundle.
  scannerRule(
    code: const LintCode(
      'crash_sentry_auth_token_in_source',
      'Sentry auth tokens must not appear in app source.',
      correctionMessage: 'Keep SENTRY_AUTH_TOKEN in the build environment for symbol upload only.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Sentry auth-token literals (sntrys_/sntryu_) and String.fromEnvironment reads of SENTRY_AUTH_TOKEN.',
    scan: (reporter, context) {
      final visitor = _SentryAuthTokenVisitor();
      context.unit.accept(visitor);
      for (final offset in visitor.offsets) {
        _reportOffset(reporter, context, offset);
      }
    },
  ),

  /// Widgets and notifiers never call HTTP clients.
  ///
  /// Why: networking.md keeps every HTTP call in datasources or infrastructure
  /// services; widgets and notifiers reach data through repositories.
  scannerRule(
    code: const LintCode(
      'network_http_call_in_widget_or_notifier',
      'Widgets and notifiers must not call HTTP clients.',
      correctionMessage:
          'Call a repository; keep HTTP calls in datasources or infrastructure services.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags resolved dio, http and dart:io client calls, and calls on project wrappers that directly hold one, inside Widget, State and Riverpod notifier classes.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      final root = _rootPackage(context);
      for (final declaration in _widgetOrNotifierClasses(context)) {
        final visitor = _HttpCallVisitor(root);
        declaration.accept(visitor);
        for (final call in visitor.calls) {
          _reportOffset(reporter, context, call.offset);
        }
      }
    },
  ),

  /// Datasources take HTTP interfaces, not concrete clients.
  ///
  /// Why: networking.md injects `IHttpService`-style interfaces into datasources;
  /// constructors take interfaces, not concrete clients.
  scannerRule(
    code: const LintCode(
      'datasource_concrete_http_client',
      'Datasources must depend on an HTTP interface, not a concrete client.',
      correctionMessage: 'Inject IHttpService or a project equivalent interface instead of Dio, http.Client, HttpClient or a concrete HTTP wrapper.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Datasource/DataSource fields and constructor parameters typed as an HTTP client or a concrete project class that reaches one.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      final root = _rootPackage(context);
      for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
        final element = declaration.declaredFragment?.element;
        if (element == null || !_isDatasource(element)) continue;
        for (final offset in _concreteHttpDependencyOffsets(declaration, root)) {
          _reportOffset(reporter, context, offset);
        }
      }
    },
  ),

  /// Failed network operations throw typed errors, never null or empty fallbacks.
  ///
  /// Why: networking.md makes failures throw typed errors or `AppException`; a
  /// silent `null` or empty collection hides the failure from the owning layer.
  scannerRule(
    code: const LintCode(
      'network_failure_null_fallback',
      'Failed network operations must not fall back to null or an empty collection.',
      correctionMessage: 'Throw a typed error or AppException; return an explicit absent result only for a classified expected absence.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags catch clauses around resolved HTTP calls that catch generic or raw HTTP failures and unconditionally return null or an empty collection literal.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      final visitor = _NetworkFallbackVisitor(_rootPackage(context));
      context.unit.accept(visitor);
      for (final fallback in visitor.fallbacks) {
        _reportOffset(reporter, context, fallback.offset);
      }
    },
  ),

  /// Widget code holds no auth tokens, auth headers or client base URLs.
  ///
  /// Why: networking.md keeps auth tokens, base URLs and secrets out of widget
  /// code; infrastructure services own them.
  scannerRule(
    code: const LintCode(
      'network_secret_in_widget',
      'Widget code must not hold auth tokens, auth headers or client base URLs.',
      correctionMessage:
          'Move tokens, Authorization headers and base URLs into the HTTP service or app config.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Bearer/Basic credential strings, Authorization map entries and dio baseUrl arguments inside Widget and State classes.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
        final element = declaration.declaredFragment?.element;
        if (element == null || !_widgetChecker.isSuperOf(element)) continue;
        final visitor = _WidgetSecretVisitor();
        declaration.accept(visitor);
        for (final offset in visitor.offsets) {
          _reportOffset(reporter, context, offset);
        }
      }
    },
  ),

  /// Widgets and notifiers render typed results, not raw HTTP failures.
  ///
  /// Why: networking.md classifies response status once at the infrastructure
  /// boundary and forbids catching raw HTTP failures in widgets or notifiers.
  scannerRule(
    code: const LintCode(
      'network_raw_http_failure_in_widget_or_notifier',
      'Widgets and notifiers must not handle raw HTTP failures or response status codes.',
      correctionMessage: 'Classify status and raw failures in the datasource or HTTP service, then handle typed results or AppException here.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags raw dio/http/dart:io failure catches and type tests, and HTTP response statusCode reads, inside Widget, State and Riverpod notifier classes.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (final declaration in _widgetOrNotifierClasses(context)) {
        final visitor = _RawHttpFailureVisitor();
        declaration.accept(visitor);
        for (final offset in visitor.offsets) {
          _reportOffset(reporter, context, offset);
        }
      }
    },
  ),
];

void _reportOffset(ScannerRuleReporter reporter, SourceScannerContext context, int offset) {
  final location = context.unit.lineInfo.getLocation(offset);
  reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
}

bool _isCrashServiceFile(SourceScannerContext context) =>
    context.path.replaceAll('\\', '/').endsWith('/crash_service.dart');

String? _packageOf(Element? element) {
  final uri = element?.library?.uri;
  if (uri == null || uri.scheme != 'package' || uri.pathSegments.isEmpty) return null;
  return uri.pathSegments.first;
}

bool _isSentryPackage(String? package) =>
    package != null && (package == 'sentry' || package.startsWith('sentry_'));

bool _isCrashFacadeError(Element? element) =>
    element is MethodElement &&
    element.isStatic &&
    element.name == 'error' &&
    element.enclosingElement?.name == 'Crash';

bool _isCrashReportCall(MethodInvocation node) {
  final element = node.methodName.element;
  if (_isCrashFacadeError(element)) return true;
  final package = _packageOf(element);
  if (_isSentryPackage(package)) return element?.name == 'captureException';
  return package == 'firebase_crashlytics' &&
      (element?.name == 'recordError' || element?.name == 'recordFlutterError');
}

/// Whether [node] sits inside the `Crash` facade class that declares a static
/// `init`, resolved through the enclosing class element rather than the file path.
bool _isInsideCrashFacade(AstNode node) {
  final crash = node.thisOrAncestorOfType<ClassDeclaration>()?.declaredFragment?.element;
  return crash != null &&
      crash.name == 'Crash' &&
      crash.methods.any((method) => method.isStatic && method.name == 'init');
}

const _httpClientChecker = TypeChecker.any([
  TypeChecker.fromName('Dio', packageName: 'dio'),
  TypeChecker.fromName('Client', packageName: 'http'),
  TypeChecker.fromUrl('dart:io#HttpClient'),
]);

const _widgetChecker = TypeChecker.any([
  TypeChecker.fromName('Widget', packageName: 'flutter'),
  TypeChecker.fromName('State', packageName: 'flutter'),
]);

const _widgetOrNotifierChecker = TypeChecker.any([
  _widgetChecker,
  TypeChecker.fromName('AnyNotifier', packageName: 'riverpod'),
  notifierChecker,
]);

String? _rootPackage(SourceScannerContext context) =>
    _packageOf(context.unit.declaredFragment?.element);

Iterable<ClassDeclaration> _widgetOrNotifierClasses(SourceScannerContext context) =>
    context.unit.declarations.whereType<ClassDeclaration>().where((declaration) {
      final element = declaration.declaredFragment?.element;
      return element != null && _widgetOrNotifierChecker.isSuperOf(element);
    });

/// Whether [element] declares an HTTP client field or constructor parameter.
bool _holdsHttpClient(InterfaceElement element) =>
    element.fields.any(
      (field) => !field.isStatic && _httpClientChecker.isAssignableFromType(field.type),
    ) ||
    element.constructors.any(
      (constructor) => constructor.formalParameters.any(
        (parameter) => _httpClientChecker.isAssignableFromType(parameter.type),
      ),
    );

/// Classes in [element]'s library that implement it, such as HttpService for
/// IHttpService.
Iterable<InterfaceElement> _libraryImplementors(InterfaceElement element) =>
    element.library.classes.where(
      (candidate) =>
          candidate != element &&
          candidate.allSupertypes.any((supertype) => supertype.element == element),
    );

/// One hop: a root-package class, or an interface implemented in its library,
/// that directly holds an HTTP client.
bool _wrapsHttpClient(InterfaceElement element, String? root) =>
    root != null &&
    _packageOf(element) == root &&
    (_holdsHttpClient(element) || _libraryImplementors(element).any(_holdsHttpClient));

/// Whether [element] reaches an HTTP client through root-package fields,
/// constructor parameters or same-library implementors, within four hops.
bool _reachesHttpClient(
  InterfaceElement element,
  String? root, [
  int depth = 0,
  Set<InterfaceElement>? visited,
]) {
  if (_httpClientChecker.isSuperOf(element)) return true;
  if (depth >= 4 || root == null || _packageOf(element) != root) return false;
  if (!(visited ??= {}).add(element)) return false;
  final next = <InterfaceElement>[
    for (final field in element.fields)
      if (!field.isStatic) ?_interfaceOf(field.type),
    for (final constructor in element.constructors)
      for (final parameter in constructor.formalParameters) ?_interfaceOf(parameter.type),
    ..._libraryImplementors(element),
  ];
  return next.any((candidate) => _reachesHttpClient(candidate, root, depth + 1, visited));
}

InterfaceElement? _interfaceOf(DartType type) => type is InterfaceType ? type.element : null;

bool _isDatasourceName(String? name) =>
    name != null && (name.endsWith('Datasource') || name.endsWith('DataSource'));

bool _isDatasource(InterfaceElement element) =>
    _isDatasourceName(element.name) ||
    element.allSupertypes.any((supertype) => _isDatasourceName(supertype.element.name));

/// A dependency type that is an HTTP client, or a concrete project class that
/// reaches one.
bool _isConcreteHttpDependency(DartType? type, String? root) {
  if (type == null) return false;
  if (_httpClientChecker.isAssignableFromType(type)) return true;
  final element = _interfaceOf(type);
  return element is ClassElement && !element.isAbstract && _reachesHttpClient(element, root);
}

List<int> _concreteHttpDependencyOffsets(ClassDeclaration declaration, String? root) {
  final body = declaration.body;
  if (body is! BlockClassBody) return const [];
  return [
    for (final member in body.members)
      ...switch (member) {
        FieldDeclaration(isStatic: false) => _concreteHttpFieldOffsets(member, root),
        ConstructorDeclaration() => _concreteHttpParameterOffsets(member, root),
        _ => const <int>[],
      },
  ];
}

Iterable<int> _concreteHttpFieldOffsets(FieldDeclaration field, String? root) => field
    .fields
    .variables
    .where((variable) => _isConcreteHttpDependency(variable.declaredFragment?.element.type, root))
    .map((variable) => field.fields.type?.offset ?? variable.offset);

/// Field formal parameters are skipped because their field is already checked.
Iterable<int> _concreteHttpParameterOffsets(ConstructorDeclaration constructor, String? root) =>
    constructor.parameters.parameters
        .where(
          (parameter) =>
              parameter is! FieldFormalParameter &&
              _isConcreteHttpDependency(parameter.declaredFragment?.element.type, root),
        )
        .map((parameter) => parameter.offset);

const _rawHttpFailureChecker = TypeChecker.any([
  TypeChecker.fromName('DioException', packageName: 'dio'),
  TypeChecker.fromName('ClientException', packageName: 'http'),
  TypeChecker.fromUrl('dart:io#SocketException'),
  TypeChecker.fromUrl('dart:io#HttpException'),
]);

const _httpResponseChecker = TypeChecker.any([
  TypeChecker.fromName('Response', packageName: 'dio'),
  TypeChecker.fromName('BaseResponse', packageName: 'http'),
  TypeChecker.fromUrl('dart:io#HttpClientResponse'),
]);

/// A call to package:http, or to a method whose class reaches an HTTP client.
bool _isNetworkCall(MethodInvocation node, String? root) {
  final element = node.methodName.element;
  if (element is TopLevelFunctionElement) return _packageOf(element) == 'http';
  final owner = element?.enclosingElement;
  return owner is InterfaceElement && _reachesHttpClient(owner, root);
}

/// An untyped catch, `on Object/Exception/Error`, or a raw HTTP failure type.
bool _catchesGenericOrRawHttpFailure(CatchClause clause) {
  final type = clause.exceptionType?.type;
  if (type == null || type is DynamicType) return true;
  if (type is InterfaceType &&
      type.element.library.uri.toString() == 'dart:core' &&
      const {'Object', 'Exception', 'Error'}.contains(type.element.name)) {
    return true;
  }
  return _rawHttpFailureChecker.isAssignableFromType(type);
}

bool _isEmptyFallback(Expression? expression) => switch (expression?.unParenthesized) {
  NullLiteral() => true,
  ListLiteral(:final elements) => elements.isEmpty,
  SetOrMapLiteral(:final elements) => elements.isEmpty,
  _ => false,
};

bool _isHttpCall(MethodInvocation node, String? root) {
  final element = node.methodName.element;
  if (element is TopLevelFunctionElement) return _packageOf(element) == 'http';
  final owner = element?.enclosingElement;
  if (owner is! InterfaceElement) return false;
  return _httpClientChecker.isSuperOf(owner) || _wrapsHttpClient(owner, root);
}

bool _isFalseLiteral(Expression expression) {
  final value = expression.unParenthesized;
  return value is BooleanLiteral && !value.value;
}

bool _referencesPackage(AstNode node, String package) {
  final visitor = _PackageReferenceVisitor(package);
  node.accept(visitor);
  return visitor.found;
}

int? _extraPublicCrashMemberOffset(ClassMember member) {
  switch (member) {
    case MethodDeclaration(:final name):
      final lexeme = name.lexeme;
      if (lexeme.startsWith('_') || const {'init', 'log', 'error'}.contains(lexeme)) return null;
      return name.offset;
    case FieldDeclaration(:final fields):
      for (final variable in fields.variables) {
        if (!variable.name.lexeme.startsWith('_')) return variable.name.offset;
      }
      return null;
    default:
      return null;
  }
}

final class _CrashReportThenRethrowVisitor extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> reports = [];

  @override
  void visitCatchClause(CatchClause node) {
    final rethrows = _RethrowVisitor(node.exceptionParameter?.declaredFragment?.element);
    node.body.accept(rethrows);
    if (rethrows.found) {
      final calls = _CrashReportCallVisitor();
      node.body.accept(calls);
      reports.addAll(calls.calls);
    }
    super.visitCatchClause(node);
  }
}

final class _RethrowVisitor extends RecursiveAstVisitor<void> {
  _RethrowVisitor(this.caught);

  final Element? caught;
  bool found = false;

  @override
  void visitRethrowExpression(RethrowExpression node) {
    found = true;
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    final thrown = node.expression.unParenthesized;
    if (caught != null && thrown is SimpleIdentifier && thrown.element == caught) found = true;
    super.visitThrowExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

final class _CrashReportCallVisitor extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> calls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isCrashReportCall(node)) calls.add(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitCatchClause(CatchClause node) {}
}

final class _SentryUseVisitor extends RecursiveAstVisitor<void> {
  final List<int> offsets = [];

  @override
  void visitImportDirective(ImportDirective node) {
    if (_isSentryUri(node.uri.stringValue)) offsets.add(node.offset);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    if (_isSentryUri(node.uri.stringValue)) offsets.add(node.offset);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isSentryPackage(_packageOf(node.methodName.element))) offsets.add(node.offset);
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_isSentryPackage(_packageOf(node.constructorName.element))) offsets.add(node.offset);
    super.visitInstanceCreationExpression(node);
  }

  bool _isSentryUri(String? uri) {
    if (uri == null || !uri.startsWith('package:')) return false;
    final slash = uri.indexOf('/');
    return slash > 0 && _isSentryPackage(uri.substring('package:'.length, slash));
  }
}

final class _GlobalErrorHandlerVisitor extends RecursiveAstVisitor<void> {
  final List<AssignmentExpression> assignments = [];

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final setter = node.writeElement;
    if (setter is PropertyAccessorElement && setter.variable.name == 'onError') {
      final owner = setter.enclosingElement;
      final library = owner.library?.uri.toString() ?? '';
      if ((owner.name == 'FlutterError' && library.startsWith('package:flutter/')) ||
          (owner.name == 'PlatformDispatcher' && library == 'dart:ui')) {
        assignments.add(node);
      }
    }
    super.visitAssignmentExpression(node);
  }
}

final class _SentryOptionAssignmentVisitor extends RecursiveAstVisitor<void> {
  _SentryOptionAssignmentVisitor(this.names);

  final Set<String> names;
  final List<AssignmentExpression> assignments = [];

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final setter = node.writeElement;
    if (setter is PropertyAccessorElement &&
        names.contains(setter.variable.name) &&
        _isSentryPackage(_packageOf(setter)) &&
        !_isFalseLiteral(node.rightHandSide)) {
      assignments.add(node);
    }
    super.visitAssignmentExpression(node);
  }
}

final class _CrashErrorCallVisitor extends RecursiveAstVisitor<void> {
  _CrashErrorCallVisitor(this.crash);

  final Element crash;
  final List<MethodInvocation> calls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final element = node.methodName.element;
    if (_isCrashFacadeError(element) && element?.enclosingElement == crash) calls.add(node);
    super.visitMethodInvocation(node);
  }
}

final class _SentryAuthTokenVisitor extends RecursiveAstVisitor<void> {
  final List<int> offsets = [];

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (node.value.startsWith('sntrys_') || node.value.startsWith('sntryu_')) {
      offsets.add(node.offset);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructor = node.constructorName.element;
    final name = node.argumentList.arguments.firstOrNull;
    if (constructor != null &&
        constructor.name == 'fromEnvironment' &&
        constructor.library.uri.toString() == 'dart:core' &&
        name is SimpleStringLiteral &&
        name.value == 'SENTRY_AUTH_TOKEN') {
      offsets.add(node.offset);
    }
    super.visitInstanceCreationExpression(node);
  }
}

final class _PackageReferenceVisitor extends RecursiveAstVisitor<void> {
  _PackageReferenceVisitor(this.package);

  final String package;
  bool found = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (_packageOf(node.element) == package) found = true;
  }
}

final class _HttpCallVisitor extends RecursiveAstVisitor<void> {
  _HttpCallVisitor(this.root);

  final String? root;
  final List<MethodInvocation> calls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isHttpCall(node, root)) calls.add(node);
    super.visitMethodInvocation(node);
  }
}

final class _NetworkFallbackVisitor extends RecursiveAstVisitor<void> {
  _NetworkFallbackVisitor(this.root);

  final String? root;
  final List<ReturnStatement> fallbacks = [];

  @override
  void visitTryStatement(TryStatement node) {
    final calls = _NetworkCallVisitor(root);
    node.body.accept(calls);
    if (calls.found) {
      for (final clause in node.catchClauses) {
        if (!_catchesGenericOrRawHttpFailure(clause)) continue;
        // Only unconditional returns: a return guarded by a status check is a
        // classified absence, not a fallback.
        for (final statement in clause.body.statements) {
          if (statement is ReturnStatement && _isEmptyFallback(statement.expression)) {
            fallbacks.add(statement);
          }
        }
      }
    }
    super.visitTryStatement(node);
  }
}

final class _NetworkCallVisitor extends RecursiveAstVisitor<void> {
  _NetworkCallVisitor(this.root);

  final String? root;
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isNetworkCall(node, root)) {
      found = true;
      return;
    }
    super.visitMethodInvocation(node);
  }
}

final class _WidgetSecretVisitor extends RecursiveAstVisitor<void> {
  final List<int> offsets = [];

  static bool _isCredential(String value) =>
      value.startsWith('Bearer ') || value.startsWith('Basic ');

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (_isCredential(node.value)) offsets.add(node.offset);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    final first = node.elements.firstOrNull;
    if (first is InterpolationString && _isCredential(first.value)) offsets.add(node.offset);
    super.visitStringInterpolation(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    final key = node.key.unParenthesized;
    if (key is SimpleStringLiteral && key.value.toLowerCase() == 'authorization') {
      offsets.add(node.offset);
    }
    super.visitMapLiteralEntry(node);
  }

  @override
  void visitNamedArgument(NamedArgument node) {
    final parameter = node.correspondingParameter;
    if (parameter != null && parameter.name == 'baseUrl' && _packageOf(parameter) == 'dio') {
      offsets.add(node.offset);
    }
    super.visitNamedArgument(node);
  }
}

final class _RawHttpFailureVisitor extends RecursiveAstVisitor<void> {
  final List<int> offsets = [];

  @override
  void visitCatchClause(CatchClause node) {
    final type = node.exceptionType?.type;
    if (type != null && _rawHttpFailureChecker.isAssignableFromType(type)) offsets.add(node.offset);
    super.visitCatchClause(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    final type = node.type.type;
    if (type != null && _rawHttpFailureChecker.isAssignableFromType(type)) offsets.add(node.offset);
    super.visitIsExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;
    final owner = element?.enclosingElement;
    if (element is GetterElement &&
        element.name == 'statusCode' &&
        owner is InterfaceElement &&
        _httpResponseChecker.isSuperOf(owner)) {
      final parent = node.parent;
      offsets.add(
        parent is PrefixedIdentifier || parent is PropertyAccess ? parent!.offset : node.offset,
      );
    }
  }
}

/// Catch clauses whose body is only reporting calls followed by `rethrow`.
final class _LogRethrowFinder extends RecursiveAstVisitor<void> {
  final statements = <Statement>[];

  @override
  void visitCatchClause(CatchClause node) {
    final body = node.body.statements;
    if (body.length > 1 &&
        _isRethrow(body.last) &&
        body.take(body.length - 1).every((statement) => _isReportingCall(statement, node))) {
      statements.add(body.first);
    }
    super.visitCatchClause(node);
  }
}

bool _isRethrow(Statement statement) =>
    statement is ExpressionStatement && statement.expression is RethrowExpression;

bool _isReportingCall(Statement statement, CatchClause clause) {
  if (statement is! ExpressionStatement) return false;
  final expression = statement.expression;
  final call = expression is AwaitExpression ? expression.expression : expression;
  final callee = switch (call) {
    MethodInvocation(:final methodName) => methodName.element,
    // Function-typed variables such as Flutter's debugPrint resolve here.
    FunctionExpressionInvocation(:final function) =>
      function is Identifier ? function.element : null,
    _ => null,
  };
  if (call is! InvocationExpression) return false;
  return _isLogFunction(callee) || _receivesCaughtError(call, clause);
}

bool _isLogFunction(Element? element) {
  if (element == null || element.enclosingElement is! LibraryElement) return false;
  final library = element.library?.uri.toString() ?? '';
  return switch (element.name) {
    'print' => library == 'dart:core',
    'log' => library == 'dart:developer',
    'debugPrint' => library.startsWith('package:flutter/'),
    _ => false,
  };
}

/// Passing the caught error or stack trace on makes the call a report.
bool _receivesCaughtError(InvocationExpression call, CatchClause clause) {
  final caught = {
    clause.exceptionParameter?.declaredFragment?.element,
    clause.stackTraceParameter?.declaredFragment?.element,
  }..remove(null);
  if (caught.isEmpty) return false;
  final finder = _ElementReferenceFinder(caught);
  call.argumentList.accept(finder);
  return finder.found;
}

final class _ElementReferenceFinder extends RecursiveAstVisitor<void> {
  _ElementReferenceFinder(this.elements);

  final Set<Element?> elements;
  bool found = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (elements.contains(node.element)) found = true;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
