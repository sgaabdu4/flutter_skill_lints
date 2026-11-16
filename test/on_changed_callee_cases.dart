import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/runtime_bug_source_rules.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_OnChangedCalleeTest>('OnChangedCalleeTest', _OnChangedCalleeTest.new, {
    'allowsCalleeThatTypesWrappedAndLiteralReceivers': (t) =>
        t._allowsCalleeThatTypesWrappedAndLiteralReceivers(),
    'allowsCalleeWithTypedClosureParameters': (t) => t._allowsCalleeWithTypedClosureParameters(),
    'allowsCalleeThatBuildsConstObjects': (t) => t._allowsCalleeThatBuildsConstObjects(),
    'allowsCalleeThatUsesExtensionMembers': (t) => t._allowsCalleeThatUsesExtensionMembers(),
  });
}

final class _OnChangedCalleeTest extends AnalysisRuleTest {
  static const _helpers = r'''
class Box {
  const Box();
  const Box.named();
}

extension Shout on String {
  String shout() => 'x';
}

extension Seconds on Iterable<String> {
  String second() => 'x';
}

extension Anything<T> on T {
  T same() => this;
}

void wrapped(String? v, List<String> items) {
  ('a').length;
  v!.length;
  (items..length).first;
}

void literals() {
  'a'.length;
  1.isEven;
  2.5.floor();
  true.toString();
}

void closures(List<String> items) {
  items.map((String e) => e.length);
}

void constObjects() {
  const Box();
  const Box.named();
}

void extensions(String v, List<String> items) {
  v.shout();
  items.second();
  v.same();
}
''';

  @override
  List<DiagnosticCode> get ignoredDiagnosticCodes => [
    ...super.ignoredDiagnosticCodes,
    for (final name in const [
      'unused_element',
      'unused_local_variable',
      'unnecessary_non_null_assertion',
    ])
      ?errorCodeByUniqueName(name),
  ];

  @override
  void setUp() {
    rule = runtimeBugSourceRules.singleWhere(
      (candidate) => candidate.name == 'text_field_on_changed_no_debounce',
    );
    super.setUp();
  }

  Future<void> _expectAllowed(String call) {
    newFile('$testPackageLibPath/helpers.dart', _helpers);
    return assertNoDiagnostics('''
import 'helpers.dart';

class TextField {
  TextField({required void Function(String) onChanged});
}

Object build() => TextField(onChanged: (value) => $call);
''');
  }

  Future<void> _allowsCalleeThatTypesWrappedAndLiteralReceivers() async {
    await _expectAllowed('wrapped(value, [value])');
  }

  Future<void> _allowsCalleeWithTypedClosureParameters() => _expectAllowed('closures([value])');

  Future<void> _allowsCalleeThatBuildsConstObjects() => _expectAllowed('constObjects()');

  Future<void> _allowsCalleeThatUsesExtensionMembers() =>
      _expectAllowed('extensions(value, [value])');
}
