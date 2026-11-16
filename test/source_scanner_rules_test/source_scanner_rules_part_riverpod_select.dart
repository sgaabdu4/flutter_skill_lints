part of '../source_scanner_rules_test.dart';

final class _RiverpodSelectArrowSyntaxTest extends _RiverpodRuleTest {
  static Map<String, Future<void> Function(_RiverpodSelectArrowSyntaxTest)> get _allCases =>
      caseSet<_RiverpodSelectArrowSyntaxTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsArrowSelect': (t) => t._allowsArrowSelect(),
          'test_allowsNonRiverpodSelectApi': (t) => t._allowsNonRiverpodSelectApi(),
          'test_allowsUnrelatedSelectNearRefWatch': (t) => t._allowsUnrelatedSelectNearRefWatch(),
          'test_reportsTypedBlockSelect': (t) => t._reportsTypedBlockSelect(),
          'test_reportsTrailingCommaBlockSelect': (t) => t._reportsTrailingCommaBlockSelect(),
          'test_reportsMultilineBlockSelect': (t) => t._reportsMultilineBlockSelect(),
        },
      );

  @override
  String get ruleName => 'riverpod_select_arrow_syntax';
  @override
  String get needle => '.select((todo)';
  @override
  String get source => r'''
class ProviderArg<T> {
  Object select(Object Function(T value) selector) => Object();
}

class Todo {
  const Todo(this.title);

  final String title;
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

final provider = ProviderArg<Todo>();

class TodoTitle {
  Object build() {
    final ref = WidgetRef();
    return ref.watch(provider.select((todo) {
      return todo.title;
    }));
  }
}
''';

  Future<void> _allowsArrowSelect() async {
    await assertAllows(r'''
class ProviderArg<T> {
  Object select(Object Function(T value) selector) => Object();
}

class Todo {
  const Todo(this.title);

  final String title;
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

final provider = ProviderArg<Todo>();

class TodoTitle {
  Object build() {
    final ref = WidgetRef();
    return ref.watch(provider.select((todo) => todo.title));
  }
}
''');
  }

  Future<void> _allowsNonRiverpodSelectApi() async {
    await assertAllows(r'''
class Query<T> {
  Object select(Object Function(T value) selector) => Object();
}

final query = Query<int>();

final selected = query.select((value) {
  return value.isEven;
});
''');
  }

  Future<void> _allowsUnrelatedSelectNearRefWatch() async {
    await assertAllows(r'''
class Query<T> {
  Object select(Object Function(T value) selector) => Object();
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

final provider = Object();
final query = Query<int>();

class TodoTitle {
  Object build() {
    final ref = WidgetRef();
    ref.watch(provider);
    return query.select((value) {
      return value.isEven;
    });
  }
}
''');
  }

  Future<void> _reportsTypedBlockSelect() async {
    final analyzedSource = _analyzedSource(r'''
class ProviderArg<T> {
  Object select(Object Function(T value) selector) => Object();
}

class Todo {
  const Todo(this.title);

  final String title;
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

final provider = ProviderArg<Todo>();

class TodoTitle {
  Object build() {
    final ref = WidgetRef();
    return ref.watch(provider.select((Todo todo) {
      return todo.title;
    }));
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '.select((Todo todo)', ruleName),
    ]);
  }

  Future<void> _reportsTrailingCommaBlockSelect() async {
    final analyzedSource = _analyzedSource(r'''
class ProviderArg<T> {
  Object select(Object Function(T value) selector) => Object();
}

class Todo {
  const Todo(this.title);

  final String title;
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

final provider = ProviderArg<Todo>();

class TodoTitle {
  Object build() {
    final ref = WidgetRef();
    return ref.watch(provider.select((todo,) {
      return todo.title;
    }));
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '.select((todo,)', ruleName),
    ]);
  }

  Future<void> _reportsMultilineBlockSelect() async {
    final analyzedSource = _analyzedSource(r'''
class ProviderArg<T> {
  Object select(Object Function(T value) selector) => Object();
}

class Todo {
  const Todo(this.title);

  final String title;
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

final provider = ProviderArg<Todo>();

class TodoTitle {
  Object build() {
    final ref = WidgetRef();
    return ref.watch(
      provider.select(
        (todo) {
          return todo.title;
        },
      ),
    );
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.select', ruleName)]);
  }
}

void _defineSourceScannerRulesPartRiverpodSelectTests() {
  analysisRuleSuite<_RiverpodSelectArrowSyntaxTest>(
    'RiverpodSelectArrowSyntaxTest',
    _RiverpodSelectArrowSyntaxTest.new,
    _RiverpodSelectArrowSyntaxTest._allCases,
  );
}
