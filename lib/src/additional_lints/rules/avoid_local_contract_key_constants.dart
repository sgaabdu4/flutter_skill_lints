import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when notifiers or repositories hide contract keys in local constants.
///
/// Persisted keys, storage keys, request payload keys, backend action strings,
/// and key registries should live behind a dedicated owner such as a keys,
/// schema, codec, or request class. Moving them to private constants inside the
/// same notifier or repository only hides the contract without giving it a
/// stable owner.
class AvoidLocalContractKeyConstants extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_local_contract_key_constants',
    'Contract keys should live in a dedicated owner, not local class constants.',
    correctionMessage:
        'Move the key/action into a dedicated keys, schema, constants, limits, '
        'codec, request, or datasource contract class.',
  );

  AvoidLocalContractKeyConstants()
    : super(
        name: 'avoid_local_contract_key_constants',
        description:
            'Warns when Notifier or Repository classes define local constants '
            'for persisted keys, payload keys, backend action strings, or key '
            'registries.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (_isExcludedContext(context)) return;

    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidLocalContractKeyConstants rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final className = node.namePart.typeName.lexeme;
    if (_isDedicatedContractOwner(className)) return;
    if (!_isBoundaryClass(node, className)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members.whereType<FieldDeclaration>()) {
      if (!member.isStatic || !member.fields.isConst) continue;

      for (final declaration in member.fields.variables) {
        if (!_isContractConstantName(declaration.name.lexeme)) continue;
        if (!_isContractInitializer(declaration.initializer)) continue;

        rule.reportAtToken(declaration.name);
      }
    }
  }
}

bool _isExcludedContext(RuleContext context) {
  final path = productionLibPath(context);
  if (path == null) return true;
  return isCommonConstantOwnerPath(path) ||
      _isDedicatedConstantOwnerPath(path) ||
      path.contains('/l10n/');
}

bool _isBoundaryClass(ClassDeclaration node, String className) {
  final path = node.root is CompilationUnit
      ? (node.root as CompilationUnit).declaredFragment?.source.fullName.replaceAll('\\', '/') ?? ''
      : '';

  return isNotifierClass(node) ||
      className.endsWith('Repository') ||
      path.contains('/presentation/notifiers/') ||
      path.contains('/repositories/');
}

bool _isDedicatedContractOwner(String className) {
  return _dedicatedOwnerSuffixes.any(className.endsWith);
}

bool _isContractConstantName(String name) {
  final normalized = name.replaceAll(RegExp(r'^_+'), '').toLowerCase();
  return _contractNameSuffixes.any(normalized.endsWith);
}

bool _isContractInitializer(Expression? expression) {
  return expression is SimpleStringLiteral ||
      expression is IntegerLiteral ||
      expression is DoubleLiteral ||
      expression is BooleanLiteral ||
      expression is NullLiteral ||
      expression is SimpleIdentifier ||
      expression is PrefixedIdentifier ||
      expression is PropertyAccess ||
      expression is ListLiteral ||
      expression is SetOrMapLiteral;
}

const _dedicatedOwnerSuffixes = {
  'Keys',
  'Constants',
  'Schema',
  'Schemas',
  'Fields',
  'Limits',
  'Defaults',
  'Durations',
  'Timeouts',
  'Intervals',
  'Thresholds',
  'Breakpoints',
  'Sizes',
  'Dimensions',
  'Contract',
  'Contracts',
  'Request',
  'Requests',
  'Payload',
  'Payloads',
  'Codec',
  'Codecs',
};

bool _isDedicatedConstantOwnerPath(String path) {
  return _dedicatedConstantOwnerPathFragments.any(path.contains);
}

const _dedicatedConstantOwnerPathFragments = {
  '/breakpoints/',
  '/defaults/',
  '/dimensions/',
  '/durations/',
  '/intervals/',
  '/limits/',
  '/sizes/',
  '/thresholds/',
  '_breakpoints.dart',
  '_defaults.dart',
  '_dimensions.dart',
  '_durations.dart',
  '_intervals.dart',
  '_limits.dart',
  '_sizes.dart',
  '_thresholds.dart',
};

const _contractNameSuffixes = {
  'action',
  'bucket',
  'collection',
  'database',
  'document',
  'endpoint',
  'field',
  'fields',
  'key',
  'keys',
  'path',
  'payload',
  'route',
  'schema',
  'table',
  'topic',
  'type',
};
