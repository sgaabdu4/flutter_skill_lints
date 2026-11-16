import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/notifier_source_rules.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_NotifierProviderReadCaptureTest>(
    'NotifierProviderReadCaptureTest',
    _NotifierProviderReadCaptureTest.new,
    {
      'allowsCapturedOperationOfRiverpodNotifier': (t) =>
          t._allowsCapturedOperationOfRiverpodNotifier(),
      'allowsParenthesizedNotifierProvider': (t) => t._allowsParenthesizedNotifierProvider(),
      'reportsOperationOfLookalikeNotifierGetter': (t) =>
          t._reportsOperationOfLookalikeNotifierGetter(),
    },
  );
}

final class _NotifierProviderReadCaptureTest extends AnalysisRuleTest {
  static const _ruleName = 'notifier_ensure_deps';

  @override
  void setUp() {
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
abstract class ProviderListenable<T extends Object> {}

class Provider<T extends Object> extends ProviderListenable<T> {
  Provider(this.value);
  final T value;
}

class NotifierProvider<T extends Object> extends ProviderListenable<T> {
  ProviderListenable<T> get notifier => throw UnimplementedError();
}

class Ref {
  T read<T extends Object>(ProviderListenable<T> provider) => throw UnimplementedError();
  bool get mounted => true;
}

class Notifier<T> {
  Ref get ref => Ref();
  T? state;
}
''');
    rule = notifierSourceRules.singleWhere((candidate) => candidate.name == _ruleName);
    super.setUp();
  }

  static String _source(String provider) =>
      '''
import 'package:riverpod/riverpod.dart';

class ItemsRepository {
  Future<void> save() async {}
}

class ItemsController {
  Future<void> save() async {}
}

class LookalikeProvider<T extends Object> extends ProviderListenable<T> {
  ProviderListenable<T> get notifier => throw 'none';
}

final repositoryProvider = Provider<ItemsRepository>(ItemsRepository());
final itemsNotifierProvider = NotifierProvider<ItemsController>();
final lookalikeProvider = LookalikeProvider<ItemsController>();

class ItemsNotifier extends Notifier<Object> {
  ItemsRepository get _repository => ref.read(repositoryProvider);

  Future<void> saveItem() async {
    _repository.hashCode;
    final save = ref.read($provider).save;
    state = Object();
    await save();
  }
}
''';

  Future<void> _allowsCapturedOperationOfRiverpodNotifier() =>
      assertNoDiagnostics(_source('itemsNotifierProvider.notifier'));

  Future<void> _allowsParenthesizedNotifierProvider() =>
      assertNoDiagnostics(_source('(itemsNotifierProvider).notifier'));

  Future<void> _reportsOperationOfLookalikeNotifierGetter() async {
    final source = _source('lookalikeProvider.notifier');
    final lineStart = source.lastIndexOf('\n', source.indexOf('Future<void> saveItem')) + 1;
    final lineEnd = source.indexOf('\n', lineStart);
    await assertDiagnostics(source, [lint(lineStart, lineEnd - lineStart, name: _ruleName)]);
  }
}
