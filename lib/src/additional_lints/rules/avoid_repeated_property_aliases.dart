import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Reports groups of pass-through locals copied from the same object's fields.
///
/// Use the source object directly, class destructuring, or a named record
/// typedef/projection instead of scattering `final x = source.x` aliases.
final class AvoidRepeatedPropertyAliases extends BlockCheckRule {
  static const LintCode code = LintCode(
    'avoid_repeated_property_aliases',
    'Avoid copying multiple fields from the same object into local aliases.',
    correctionMessage:
        'Use the source object directly, or introduce a named record typedef/projection.',
    severity: DiagnosticSeverity.ERROR,
  );

  static const int minAliases = 3;

  AvoidRepeatedPropertyAliases()
    : super(
        name: 'avoid_repeated_property_aliases',
        description: 'Reports three or more local aliases copied from one object.',
        code: code,
      );

  @override
  bool shouldRegister(RuleContext context) => !isGeneratedRuleContext(context);

  @override
  void checkBlock(Block node) {
    final aliasesByReceiver = <String, _ReceiverAliases>{};

    for (final statement in node.statements) {
      if (statement is! VariableDeclarationStatement) continue;
      for (final variable in statement.variables.variables) {
        final alias = _PropertyAlias.fromVariable(variable);
        if (alias == null) continue;
        if (_isLocalizationReceiver(alias.receiverName, alias.receiverElement)) continue;

        aliasesByReceiver
            .putIfAbsent(alias.receiverName, () => _ReceiverAliases(alias.receiverName))
            .add(alias);
      }
    }

    for (final aliases in aliasesByReceiver.values) {
      if (aliases.distinctProperties.length < AvoidRepeatedPropertyAliases.minAliases) continue;
      reportAtToken(aliases.firstAlias);
    }
  }

  bool _isLocalizationReceiver(String receiverName, Element? receiverElement) {
    if (receiverName == 'l10n') return true;
    final typeName = switch (receiverElement) {
      FormalParameterElement(:final type) => type.getDisplayString(),
      LocalVariableElement(:final type) => type.getDisplayString(),
      _ => null,
    };
    return typeName == 'AppLocalizations' || (typeName?.endsWith('Localizations') ?? false);
  }
}

final class _ReceiverAliases {
  _ReceiverAliases(this.receiverName);

  final String receiverName;
  final List<_PropertyAlias> _aliases = [];
  final Set<String> distinctProperties = {};

  Token get firstAlias => _aliases.first.name;

  void add(_PropertyAlias alias) {
    _aliases.add(alias);
    distinctProperties.add(alias.propertyName);
  }
}

final class _PropertyAlias {
  const _PropertyAlias({
    required this.name,
    required this.receiverName,
    required this.propertyName,
    required this.receiverElement,
  });

  final Token name;
  final String receiverName;
  final String propertyName;
  final Element? receiverElement;

  static _PropertyAlias? fromVariable(VariableDeclaration variable) {
    final initializer = variable.initializer?.unParenthesized;
    final access = switch (initializer) {
      PrefixedIdentifier(:final prefix, :final identifier) => (
        receiver: prefix,
        property: identifier,
      ),
      PropertyAccess(target: final SimpleIdentifier receiver, :final propertyName) => (
        receiver: receiver,
        property: propertyName,
      ),
      _ => null,
    };
    if (access == null) return null;
    return _PropertyAlias(
      name: variable.name,
      receiverName: access.receiver.name,
      propertyName: access.property.name,
      receiverElement: access.receiver.element,
    );
  }
}
