import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' show CommentToken;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Require the three-hook crash-reporting pattern around `runApp(...)`.
///
/// Why: Flutter 3.3+ guidance (docs.flutter.dev/testing/errors) splits async errors across
/// three handlers. `runZonedGuarded` is legacy and misses platform-channel errors. Any
/// top-level function whose body calls `runApp(...)` must wire all three:
/// `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and
/// `Isolate.current.addErrorListener`. This covers both `main()` and bootstrap wrappers
/// (e.g. `runRepem`, `bootstrap`, `mainCommon`, flavor-specific entrypoints).
///
/// Escape hatch: if hooks are configured in a helper called from the body (e.g.
/// `setupCrashReporting()`), add the comment
/// `// flutter_skill_lints:configure_error_hooks_elsewhere`
/// inside the body to opt out.
final class RequireMainErrorHooks extends AnalysisRule {
  static const _optOutMarker = 'flutter_skill_lints:configure_error_hooks_elsewhere';

  static const LintCode code = LintCode(
    'require_main_error_hooks',
    'Function that calls runApp must wire FlutterError.onError, '
        'PlatformDispatcher.instance.onError, and Isolate.current.addErrorListener.',
    correctionMessage:
        'Add the missing hook(s), or extract setup into a helper and mark this function '
        'body with `// $_optOutMarker`.',
  );

  RequireMainErrorHooks()
    : super(
        name: 'require_main_error_hooks',
        description:
            'Requires the three-hook crash wiring (FlutterError.onError + '
            'PlatformDispatcher.instance.onError + Isolate.current.addErrorListener) in '
            'any top-level function that calls runApp.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addFunctionDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final RequireMainErrorHooks rule;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is! CompilationUnit) return;

    final body = node.functionExpression.body;
    if (body is! BlockFunctionBody) return;

    final scanner = _MainBodyScanner();
    body.visitChildren(scanner);

    if (!scanner.callsRunApp) return;

    if (_bodyContainsOptOutMarker(body)) return;

    final missing = <String>[
      if (!scanner.setsFlutterErrorOnError) 'FlutterError.onError',
      if (!scanner.setsPlatformDispatcherOnError) 'PlatformDispatcher.instance.onError',
      if (!scanner.callsIsolateAddErrorListener) 'Isolate.current.addErrorListener',
    ];
    if (missing.isEmpty) return;

    rule.reportAtToken(node.name);
  }

  bool _bodyContainsOptOutMarker(BlockFunctionBody body) {
    var token = body.beginToken;
    final end = body.endToken;
    while (true) {
      var comment = token.precedingComments;
      while (comment != null) {
        if (comment.lexeme.contains(RequireMainErrorHooks._optOutMarker)) {
          return true;
        }
        final next = comment.next;
        comment = next is CommentToken ? next : null;
      }
      if (token == end) break;
      token = token.next!;
    }
    return false;
  }
}

final class _MainBodyScanner extends RecursiveAstVisitor<void> {
  bool callsRunApp = false;
  bool setsFlutterErrorOnError = false;
  bool setsPlatformDispatcherOnError = false;
  bool callsIsolateAddErrorListener = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null && node.methodName.name == 'runApp') {
      callsRunApp = true;
    }
    if (node.methodName.name == 'addErrorListener') {
      final target = node.target;
      if (_isIsolateCurrent(target)) {
        callsIsolateAddErrorListener = true;
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final lhs = node.leftHandSide;
    if (lhs is PrefixedIdentifier) {
      if (lhs.prefix.name == 'FlutterError' && lhs.identifier.name == 'onError') {
        setsFlutterErrorOnError = true;
      }
    } else if (lhs is PropertyAccess) {
      if (lhs.propertyName.name == 'onError' && _isPlatformDispatcherInstance(lhs.target)) {
        setsPlatformDispatcherOnError = true;
      }
    }
    super.visitAssignmentExpression(node);
  }

  bool _isIsolateCurrent(Expression? expression) {
    if (expression is PrefixedIdentifier) {
      return expression.prefix.name == 'Isolate' && expression.identifier.name == 'current';
    }
    if (expression is PropertyAccess) {
      final target = expression.target;
      return expression.propertyName.name == 'current' &&
          target is SimpleIdentifier &&
          target.name == 'Isolate';
    }
    return false;
  }

  bool _isPlatformDispatcherInstance(Expression? expression) {
    if (expression is PrefixedIdentifier) {
      return expression.prefix.name == 'PlatformDispatcher' &&
          expression.identifier.name == 'instance';
    }
    return false;
  }
}
