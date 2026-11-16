import 'package:flutter_skill_lints/src/additional_lints/fixes/add_suffix_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_notifier_suffix.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<AddSuffixFixTest>('AddSuffixFixTest', AddSuffixFixTest.new, {
    'appendsSuffixToPlainName': (t) => t.appendsSuffixToPlainName(),
    'replacesMisspelledSuffix': (t) => t.replacesMisspelledSuffix(),
    'replacesSuffixWithExtraLetter': (t) => t.replacesSuffixWithExtraLetter(),
    'replacesSuffixWithMissingLetter': (t) => t.replacesSuffixWithMissingLetter(),
    'keepsNamesThatOnlyResembleTheSuffixLoosely': (t) =>
        t.keepsNamesThatOnlyResembleTheSuffixLoosely(),
  });
}

final class AddSuffixFixTest extends FixRuleTest {
  @override
  void setUp() {
    rule = UseNotifierSuffix();
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
abstract class Notifier<T> {
  T build();
}
''');
    super.setUp();
  }

  static String _source(String name) =>
      '''
import 'package:riverpod/riverpod.dart';

class $name extends Notifier<int> {
  @override
  int build() => 0;
}
''';

  Future<void> _expectRename(String from, String to) => expectFix(
    _source(from),
    (context) => AddSuffixFix.notifierFix(context: context),
    expected: _source(to),
  );

  Future<void> appendsSuffixToPlainName() => _expectRename('Counter', 'CounterNotifier');

  Future<void> replacesMisspelledSuffix() => _expectRename('CounterNotifer', 'CounterNotifier');

  Future<void> replacesSuffixWithExtraLetter() =>
      _expectRename('CounterNotifierr', 'CounterNotifier');

  Future<void> replacesSuffixWithMissingLetter() =>
      _expectRename('CounterNotfier', 'CounterNotifier');

  Future<void> keepsNamesThatOnlyResembleTheSuffixLoosely() =>
      _expectRename('NotesStore', 'NotesStoreNotifier');
}
