import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Avoid legacy Riverpod provider and ref APIs.
///
/// Why: Bans legacy Riverpod provider constructors, `StateNotifier`, `legacy.dart` imports and
/// legacy generated Ref types. Use Riverpod codegen providers and the unified Ref type.
final class AvoidLegacyRiverpodApis extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_legacy_riverpod_apis',
    'Avoid legacy Riverpod provider and ref APIs.',
    correctionMessage: 'Use Riverpod codegen providers and the unified Ref type.',
    severity: DiagnosticSeverity.ERROR,
  );

  static const Set<String> legacyProviders = {
    'Provider',
    'StateProvider',
    'StateNotifierProvider',
    'ChangeNotifierProvider',
    'NotifierProvider',
    'AsyncNotifierProvider',
    'FutureProvider',
    'StreamProvider',
  };

  static const Set<String> legacyImports = {
    'package:riverpod/legacy.dart',
    'package:flutter_riverpod/legacy.dart',
    'package:hooks_riverpod/legacy.dart',
  };

  AvoidLegacyRiverpodApis()
    : super(
        name: 'avoid_legacy_riverpod_apis',
        description:
            'Bans legacy Riverpod provider constructors, StateNotifier, legacy.dart imports and '
            'legacy generated Ref types.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    final visitor = _Visitor(this);
    registry.addImportDirective(this, visitor);
    registry.addNamedType(this, visitor);
    registry.addSimpleIdentifier(this, visitor);
  }
}

const _riverpodRef = TypeChecker.fromName('Ref', packageName: 'riverpod');
const _stateNotifier = TypeChecker.fromName('StateNotifier', packageName: 'state_notifier');

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidLegacyRiverpodApis rule;

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.libraryImport?.importedLibrary?.uri.toString();
    if (AvoidLegacyRiverpodApis.legacyImports.contains(uri)) rule.reportAtNode(node.uri);
  }

  @override
  void visitNamedType(NamedType node) {
    final element = node.element;
    if (_isLegacyRef(element) || _isLegacyProvider(element) || _isStateNotifier(element)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (classMemberNameIsDeclaration(node)) return;
    final parent = node.parent;
    if (parent is NamedType) return;
    final element = node.element;
    final owner = element is ConstructorElement ? element.enclosingElement : element;
    if (!_isLegacyProvider(owner)) return;
    if (parent is MethodInvocation && parent.methodName == node) {
      rule.reportAtNode(node);
      return;
    }
    if (parent is ConstructorName && parent.type.name.lexeme == node.name) {
      rule.reportAtNode(node);
    }
  }

  bool _isLegacyProvider(Element? element) {
    return element is InterfaceElement &&
        AvoidLegacyRiverpodApis.legacyProviders.contains(element.name) &&
        _isRiverpodLibrary(element.library);
  }

  bool _isStateNotifier(Element? element) =>
      element is InterfaceElement && _stateNotifier.isSuperOf(element);

  /// A Ref alias (`typedef GreetingRef = Ref`) or a legacy Riverpod Ref subtype.
  bool _isLegacyRef(Element? element) {
    if (element is TypeAliasElement) {
      final aliased = element.aliasedType;
      return aliased is InterfaceType && _riverpodRef.isAssignableFromType(aliased);
    }
    if (element is! InterfaceElement || !_isRiverpodLibrary(element.library)) return false;
    if (element.name == 'Ref' || element.name == 'WidgetRef') return false;
    return _riverpodRef.isSuperOf(element);
  }

  bool _isRiverpodLibrary(LibraryElement library) {
    final uri = library.uri.toString();
    return uri.startsWith('package:riverpod/') ||
        uri.startsWith('package:flutter_riverpod/') ||
        uri.startsWith('package:hooks_riverpod/');
  }
}
