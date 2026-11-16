part of '../additional_lints_false_positive_test.dart';

final class _AvoidCommentedOutCodeFalsePositiveTest extends _AdditionalLintRuleTest {
  static Map<String, Future<void> Function(_AvoidCommentedOutCodeFalsePositiveTest)>
  get _allCases => caseSet<_AvoidCommentedOutCodeFalsePositiveTest>(
    parent: const {},
    own: {
      'test_allowsParenthesizedHyphenatedDescription': (t) =>
          t._allowsParenthesizedHyphenatedDescription(),
      'test_allowsParenthesizedDescriptionThatWouldParseAsCall': (t) =>
          t._allowsParenthesizedDescriptionThatWouldParseAsCall(),
      'test_allowsUnspacedDescriptionThatDoesNotParse': (t) =>
          t._allowsUnspacedDescriptionThatDoesNotParse(),
      'test_doesNotGroupTrailingDescriptionsWithLaterCode': (t) =>
          t._doesNotGroupTrailingDescriptionsWithLaterCode(),
      'test_reportsCommentedOutCallStatement': (t) => t._reportsCommentedOutCallStatement(),
      'test_reportsCommentedOutCallWithoutSemicolon': (t) =>
          t._reportsCommentedOutCallWithoutSemicolon(),
      'test_reportsCommentedOutDeclaration': (t) => t._reportsCommentedOutDeclaration(),
      'test_reportsCommentedOutMultilineCall': (t) => t._reportsCommentedOutMultilineCall(),
      'test_allowsProseStartingWithTypeKeyword': (t) => t._allowsProseStartingWithTypeKeyword(),
      'test_allowsProseWithAssignmentLikeEquals': (t) => t._allowsProseWithAssignmentLikeEquals(),
      'test_reportsCommentedOutAssignmentWithoutSemicolon': (t) =>
          t._reportsCommentedOutAssignmentWithoutSemicolon(),
      'test_reportsCommentedOutMultilineDeclaration': (t) =>
          t._reportsCommentedOutMultilineDeclaration(),
      'test_reportsCommentedOutConstructorCallAfterProse': (t) =>
          t._reportsCommentedOutConstructorCallAfterProse(),
      'test_reportsCommentedOutBlock': (t) => t._reportsCommentedOutBlock(),
    },
  );

  @override
  void setUp() {
    rule = AvoidCommentedOutCode();
    super.setUp();
  }

  Future<void> _allowsParenthesizedHyphenatedDescription() async {
    await assertNoDiagnostics(r'''
abstract final class CommentProbe {
  static const fbs = '60-100'; // Glucose (GOD-POD Method)
}
''');
  }

  Future<void> _allowsParenthesizedDescriptionThatWouldParseAsCall() async {
    await assertNoDiagnostics(r'''
abstract final class CommentProbe {
  static const ldl = '0-130'; // Cholesterol (total)
}
''');
  }

  Future<void> _allowsUnspacedDescriptionThatDoesNotParse() async {
    await assertNoDiagnostics(r'''
abstract final class CommentProbe {
  static const fbs = '60-100'; // Glucose(GOD-POD Method)
}
''');
  }

  Future<void> _doesNotGroupTrailingDescriptionsWithLaterCode() async {
    const source = r'''
abstract final class CommentProbe {
  static const fbs = '60-100'; // Glucose (GOD-POD Method)
  static const ldl = '0-130'; // Cholesterol (total)
}

void commentControls() {
  // foo(bar);
  // final x = 1;
}
''';
    final start = source.indexOf('// foo');
    final end = source.indexOf('// final x = 1;') + '// final x = 1;'.length;
    await assertDiagnostics(source, [lint(start, end - start)]);
  }

  Future<void> _reportsCommentedOutCallStatement() async {
    const source = r'''
void run() {
  // foo(bar);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('// foo'), '// foo(bar);'.length)]);
  }

  Future<void> _reportsCommentedOutCallWithoutSemicolon() async {
    const source = r'''
void run() {
  // foo(bar)
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('// foo'), '// foo(bar)'.length)]);
  }

  Future<void> _reportsCommentedOutDeclaration() async {
    const source = r'''
void run() {
  // final x = 1;
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('// final'), '// final x = 1;'.length)]);
  }

  Future<void> _reportsCommentedOutMultilineCall() async {
    const source = r'''
void run() {
  // save(
  //   item,
  // );
}
''';
    final start = source.indexOf('// save(');
    final end = source.indexOf('// );') + '// );'.length;
    await assertDiagnostics(source, [lint(start, end - start)]);
  }

  Future<void> _allowsProseStartingWithTypeKeyword() async {
    await assertNoDiagnostics(r'''
void run() {
  // Widget — use .select() on the computed getter
  print(1);
}
''');
  }

  Future<void> _allowsProseWithAssignmentLikeEquals() async {
    await assertNoDiagnostics(r'''
void run() {
  // ✅ DO — fixed sequence: persist → targeted sync → navigate.
  //    Reorder = UI flicker (stale parent) OR lost writes on dispose.
  print(1);
}
''');
  }

  Future<void> _reportsCommentedOutAssignmentWithoutSemicolon() async {
    const source = r'''
void run() {
  // count = 1
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('// count'), '// count = 1'.length)]);
  }

  Future<void> _reportsCommentedOutMultilineDeclaration() async {
    const source = r'''
void run() {
  // final items = watch(
  //   provider,
  // );
}
''';
    final start = source.indexOf('// final');
    final end = source.indexOf('// );') + '// );'.length;
    await assertDiagnostics(source, [lint(start, end - start)]);
  }

  Future<void> _reportsCommentedOutConstructorCallAfterProse() async {
    const source = r'''
void run() {
  // inside UserModel.toEntity() or UserImportService — outside /domain/:
  //   User(email: Email(json['email'] as String))
}
''';
    final start = source.indexOf('// inside');
    final end = source.indexOf('String))') + 'String))'.length;
    await assertDiagnostics(source, [lint(start, end - start)]);
  }

  Future<void> _reportsCommentedOutBlock() async {
    const source = r'''
void run() {
  // if (ready) {
  //   doThing();
  // }
}
''';
    final start = source.indexOf('// if');
    final end = source.lastIndexOf('// }') + '// }'.length;
    await assertDiagnostics(source, [lint(start, end - start)]);
  }
}
