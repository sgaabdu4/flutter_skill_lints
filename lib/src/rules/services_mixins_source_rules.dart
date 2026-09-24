import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> servicesMixinsSourceRules = [
  /// Keep singleton instance fields plain and boring.
  ///
  /// Why: Allows only the boring fire-and-forget singleton shape (private constructor + one
  /// static final instance + void/Future<void> public methods) while flagging public
  /// constructors, state/data APIs, mutable resources, debug injection seams, service locators,
  /// and fake/backend swapping inside the singleton itself.
  scannerRule(
    code: const LintCode(
      'service_singleton',
      'Singleton is not plain and boring.',
      correctionMessage: 'Use a private constructor with one static final instance/trivial getter and void/Future<void> public methods only. Move data/stateful services to a provider/repository boundary.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags singleton shapes that are mutable, injectable, or missing a private constructor so the Flutter skill singleton guidance is shown during analysis.',
    scan: (reporter, context) {
      for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
        final singleton = _SingletonShape.of(declaration);
        if (singleton == null) continue;

        final lines = context.source.lineOffsets;
        final firstLine = lines.lastIndexWhere((start) => start <= declaration.offset);
        final lastLine = lines.lastIndexWhere((start) => start <= declaration.end);
        final body = context.source.masked.sublist(firstLine, lastLine + 1).join('\n');
        if (!singleton.hasPublicConstructor &&
            !singleton.hasMutableBacking &&
            !singleton.hasPublicDataApi &&
            !_hasOverbuiltSingletonSeam(body) &&
            !_hasMutableSingletonState(body)) {
          continue;
        }

        reporter.reportOffset(context, singleton.exposureOffset);
      }
    },
  ),

  /// Avoid mixin class for capability mixins.
  ///
  /// Why: Flags mixin class declarations for capability mixins. Use mixin for reusable
  /// behavior.
  scannerRule(
    code: const LintCode(
      'mixin_mixin_class',
      'Avoid mixin class for capability mixins.',
      correctionMessage: 'Use mixin for reusable behavior.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags mixin class declarations for capability mixins so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'^\s*mixin\s+class\s+\w+').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('mixin'));
        }
      }
    },
  ),

  /// Mixin names should end with Mixin.
  ///
  /// Why: Flags capability mixins without the Mixin suffix. Suffix capability mixins with
  /// Mixin.
  scannerRule(
    code: const LintCode(
      'mixin_name_suffix',
      'Mixin names should end with Mixin.',
      correctionMessage: 'Suffix capability mixins with Mixin.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags capability mixins without the Mixin suffix so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final mixinMatch = RegExp(r'^\s*mixin(?:\s+class)?\s+(\w+)').firstMatch(line);
        if (mixinMatch != null && !(mixinMatch.group(1) ?? '').endsWith('Mixin')) {
          reporter.report(context, i, mixinMatch.start);
        }
      }
    },
  ),

  /// Mixins should not carry mutable state.
  ///
  /// Why: Flags mutable fields inside mixins. Keep mixins stateless.
  scannerRule(
    code: const LintCode(
      'mixin_mutable_state',
      'Mixins should not carry mutable state.',
      correctionMessage: 'Keep mixins stateless.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags mutable fields inside mixins so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final declaration in context.unit.declarations) {
        final (members, onStateLifecycle) = switch (declaration) {
          MixinDeclaration(:final body) => (body.members, _isOnStateLifecycle(declaration)),
          ClassDeclaration(:final body, mixinKeyword: _?) => (body.members, false),
          _ => (const <ClassMember>[], false),
        };
        for (final field in members.whereType<FieldDeclaration>()) {
          if (!_isMutableField(field)) continue;
          if (onStateLifecycle &&
              field.fields.variables.every((v) => v.name.lexeme.startsWith('_'))) {
            continue;
          }
          final offset = field.firstTokenAfterCommentAndMetadata.offset;
          reporter.report(
            context,
            context.source.lineOffsets.lastIndexWhere((start) => start <= offset),
            0,
          );
        }
      }
    },
  ),
];

bool _isMutableField(FieldDeclaration field) =>
    field.abstractKeyword == null &&
    field.externalKeyword == null &&
    !field.fields.isFinal &&
    !field.fields.isConst;

bool _isOnStateLifecycle(MixinDeclaration declaration) =>
    declaration.onClause?.superclassConstraints.any(
      (type) => const {'State', 'ConsumerState', 'HookConsumerState'}.contains(type.name.lexeme),
    ) ??
    false;

final _overbuiltSingletonSeam = RegExp(
  r'\b(?:debug(?:Reset|Configure|Use|Set|Override)\w*|resetForTest(?:ing)?|'
  r'set(?:Instance|Backend|Client|Provider)\w*|'
  r'overrideWithValue|Fake[A-Z]\w*|Mock[A-Z]\w*|'
  r'ServiceLocator|serviceLocator|locator|Backend|backend)\b',
);

final _mutableInstanceField = RegExp(
  r'^(?:late\s+)?(?:var|[A-Za-z_]\w*(?:<[^>]+>)?)\s+_[A-Za-z_]\w*\s*(?:=|;)',
);

final _mutableFinalResourceField = RegExp(
  r'^(?:late\s+)?final\s+(?:[A-Za-z_]\w*(?:<[^>]+>)?\s+)?_[A-Za-z_]\w*\s*=\s*'
  r'(?:<[^>]*>[\[{]|\[|\{|StreamController\b|Timer\b|[A-Za-z_]\w*Controller\b|'
  r'[A-Za-z_]\w*Subscription\b|HttpClient\b)',
);

bool _hasOverbuiltSingletonSeam(String body) {
  return _overbuiltSingletonSeam.hasMatch(body);
}

bool _hasMutableSingletonState(String body) {
  for (final line in body.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('static ') || trimmed.startsWith('const ')) continue;
    if (_mutableInstanceField.hasMatch(trimmed)) return true;
    if (_mutableFinalResourceField.hasMatch(trimmed)) return true;
  }
  return false;
}

/// A class that keeps exactly one non-const static instance of itself and exposes it
/// through a public static field or getter typed as the class, or a public factory
/// constructor that returns the stored instance.
final class _SingletonShape {
  const _SingletonShape._({
    required this.exposureOffset,
    required this.hasPublicConstructor,
    required this.hasMutableBacking,
    required this.hasPublicDataApi,
  });

  final int exposureOffset;
  final bool hasPublicConstructor;
  final bool hasMutableBacking;
  final bool hasPublicDataApi;

  static _SingletonShape? of(ClassDeclaration declaration) {
    final classElement = declaration.declaredFragment?.element;
    if (classElement == null) return null;
    bool isSelf(DartType? type) => type is InterfaceType && type.element == classElement;

    final backing = <FieldElement>[];
    for (final field in declaration.body.members.whereType<FieldDeclaration>()) {
      if (!field.isStatic || field.fields.isConst) continue;
      for (final variable in field.fields.variables) {
        final element = variable.declaredFragment?.element;
        if (element is FieldElement && isSelf(element.type)) backing.add(element);
      }
    }
    if (backing.length != 1) return null;
    final stored = backing.single;

    int? exposureOffset;
    var hasPublicDataApi = false;
    for (final member in declaration.body.members) {
      final offset = member.firstTokenAfterCommentAndMetadata.offset;
      switch (member) {
        case FieldDeclaration(:final fields):
          for (final variable in fields.variables) {
            if (variable.name.lexeme.startsWith('_')) continue;
            if (variable.declaredFragment?.element == stored) {
              exposureOffset ??= offset;
            } else {
              hasPublicDataApi = true;
            }
          }
        case MethodDeclaration(:final name) when !name.lexeme.startsWith('_'):
          final element = member.declaredFragment?.element;
          if (member.isStatic && member.isGetter && isSelf(element?.returnType)) {
            exposureOffset ??= offset;
          } else if (member.isGetter || member.isSetter || !_returnsNothing(element?.returnType)) {
            hasPublicDataApi = true;
          }
        case ConstructorDeclaration(factoryKeyword: _?, name: final name)
            when !(name?.lexeme.startsWith('_') ?? false) && _reads(member.body, stored):
          exposureOffset ??= offset;
        default:
          break;
      }
    }
    if (exposureOffset == null) return null;

    return _SingletonShape._(
      exposureOffset: exposureOffset,
      hasPublicConstructor: classElement.constructors.any((constructor) => constructor.isPublic),
      hasMutableBacking: !stored.isFinal,
      hasPublicDataApi: hasPublicDataApi,
    );
  }
}

bool _returnsNothing(DartType? type) {
  if (type is VoidType) return true;
  return type is InterfaceType &&
      type.isDartAsyncFuture &&
      type.typeArguments.length == 1 &&
      type.typeArguments.single is VoidType;
}

bool _reads(FunctionBody body, FieldElement field) {
  final visitor = _FieldReadVisitor(field);
  body.accept(visitor);
  return visitor.found;
}

final class _FieldReadVisitor extends RecursiveAstVisitor<void> {
  _FieldReadVisitor(this.field);

  final FieldElement field;
  bool found = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;
    if (element == field || (element is PropertyAccessorElement && element.variable == field)) {
      found = true;
    }
  }
}
