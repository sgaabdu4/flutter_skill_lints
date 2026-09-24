import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> dataCrashSourceRules = [
  /// Avoid log-and-rethrow in data layers.
  ///
  /// Why: Flags log-and-rethrow patterns in data layers, including a Crash/Sentry/
  /// Crashlytics report followed by `rethrow` in the same catch. One failed operation
  /// has one incident owner.
  scannerRule(
    code: const LintCode(
      'data_log_rethrow',
      'Avoid log-and-rethrow in data layers.',
      correctionMessage: 'Report once in the owning layer: rethrow typed context without reporting, or report and throw a mapped typed error.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags log-and-rethrow patterns in data layers so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.isDataPath) return;
      final reportedLines = <int>{};
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\b(?:print|debugPrint|log)\s*\(').hasMatch(line) &&
            context.near(i, 'rethrow', 6)) {
          reporter.report(context, i, 0);
          reportedLines.add(i);
        }
      }
      final visitor = _CrashReportThenRethrowVisitor();
      context.unit.accept(visitor);
      for (final call in visitor.reports) {
        final line = context.unit.lineInfo.getLocation(call.offset).lineNumber - 1;
        if (reportedLines.add(line)) reporter.report(context, line, 0);
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
