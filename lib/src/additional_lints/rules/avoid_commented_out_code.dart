import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when commented-out code is found.
///
/// Commented-out code is a sign of technical debt. Use version control
/// instead of keeping old code in comments.
class AvoidCommentedOutCode extends CompilationUnitRule {
  static const LintCode code = LintCode(
    'avoid_commented_out_code',
    'This comment looks like commented-out code.',
    correctionMessage:
        'Remove commented-out code. Use version control to '
        'track old code instead.',
  );

  AvoidCommentedOutCode()
    : super(
        name: 'avoid_commented_out_code',
        description: 'Warns when commented-out code is found.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidCommentedOutCode rule;

  _Visitor(this.rule);

  static final _annotationPattern = RegExp(r'^@[a-zA-Z]+');
  static final _assignmentPattern = RegExp(r'^[a-zA-Z_]\w*(\.\w+)*\s*[+\-*/]?=\s');
  static final _returnPattern = RegExp(r'^return\s');
  static final _cascadePattern = RegExp(r'^\.\.[a-zA-Z]');
  // Formatted Dart never puts whitespace between a callee and its `(`;
  // prose such as `Glucose (fasting)` does.
  static final _functionCallPattern = RegExp(r'^[a-zA-Z_]\w*(\.\w+)*(<[^>]*>)?\(');
  static final _whitespacePattern = RegExp(r'\s+');

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final lineInfo = node.lineInfo;
    final trailing = <Token>{};
    final allComments = _collectAllComments(node, lineInfo, trailing);
    final groups = _groupConsecutiveComments(allComments, lineInfo, trailing);

    for (final group in groups) {
      final stripped = group.map((t) => _stripCommentPrefix(t.lexeme)).join('\n').trim();

      if (stripped.isEmpty) continue;

      if (_looksLikeCode(stripped)) {
        final first = group.first;
        final last = group.last;
        final offset = first.offset;
        final length = last.end - first.offset;
        rule.reportAtOffset(offset, length);
      }
    }
  }

  /// Maximum number of single-line comments to collect before bailing out.
  /// Prevents stalling the analysis server on auto-generated files with
  /// thousands of comment lines.
  static const _maxComments = 500;

  /// Collects all single-line comment tokens (`//`) from the token stream,
  /// excluding doc comments (`///`) and ignore directives. Comments that
  /// follow code on the same line are added to [trailing].
  List<Token> _collectAllComments(CompilationUnit node, LineInfo lineInfo, Set<Token> trailing) {
    final comments = <Token>[];
    Token? token = node.beginToken;
    while (token != null && !token.isEof) {
      _addSingleLineComments(token, comments, lineInfo, trailing);
      if (comments.length >= _maxComments) return comments;
      token = token.next;
    }
    if (token != null) _addSingleLineComments(token, comments, lineInfo, trailing);
    return comments;
  }

  void _addSingleLineComments(
    Token owner,
    List<Token> comments,
    LineInfo lineInfo,
    Set<Token> trailing,
  ) {
    final code = owner.previous;
    final codeLine = code == null || code.type == TokenType.EOF
        ? null
        : lineInfo.getLocation(code.end).lineNumber;
    Token? comment = owner.precedingComments;
    while (comment != null && comments.length < _maxComments) {
      if (_isSingleLineComment(comment)) {
        comments.add(comment);
        if (lineInfo.getLocation(comment.offset).lineNumber == codeLine) trailing.add(comment);
      }
      comment = comment.next;
    }
  }

  /// Returns true if the token is a single-line `//` comment (not `///`).
  bool _isSingleLineComment(Token token) {
    if (token.type != TokenType.SINGLE_LINE_COMMENT) return false;
    final lexeme = token.lexeme;
    // Exclude doc comments (///) and ignore directives.
    if (lexeme.startsWith('///')) return false;
    if (lexeme.contains('ignore:') || lexeme.contains('ignore_for_file:')) {
      return false;
    }
    return true;
  }

  /// Groups whole-line comments on consecutive lines. A comment that follows
  /// code on its line stands alone.
  List<List<Token>> _groupConsecutiveComments(
    List<Token> comments,
    LineInfo lineInfo,
    Set<Token> trailing,
  ) {
    if (comments.isEmpty) return [];

    final groups = <List<Token>>[];
    var currentGroup = <Token>[comments.first];

    for (var i = 1; i < comments.length; i++) {
      final prev = comments[i - 1];
      final curr = comments[i];
      final nextLine =
          lineInfo.getLocation(curr.offset).lineNumber ==
          lineInfo.getLocation(prev.offset).lineNumber + 1;

      if (nextLine && !trailing.contains(prev) && !trailing.contains(curr)) {
        currentGroup.add(curr);
      } else {
        groups.add(currentGroup);
        currentGroup = [curr];
      }
    }
    groups.add(currentGroup);
    return groups;
  }

  /// Strips the `//` prefix and optional leading space from a comment.
  String _stripCommentPrefix(String lexeme) {
    if (lexeme.startsWith('// ')) return lexeme.substring(3);
    if (lexeme.startsWith('//')) return lexeme.substring(2);
    return lexeme;
  }

  /// Heuristic check: does the stripped comment text look like Dart code?
  bool _looksLikeCode(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return false;

    var codeLineCount = 0;
    for (final line in lines) {
      if (_lineIsLikelyCode(line.trim())) {
        codeLineCount++;
      }
    }

    // If more than half the non-empty lines look like code, flag it.
    return codeLineCount > 0 && codeLineCount >= (lines.length + 1) ~/ 2;
  }

  /// Checks if a single line of text looks like Dart code.
  bool _lineIsLikelyCode(String line) {
    // Empty lines are neutral.
    if (line.isEmpty) return false;

    // Ignore typical prose and note comments.
    if (_isProse(line)) return false;

    // Lines ending with ; or { or } or , are very likely code.
    if (line.endsWith(';') ||
        line.endsWith('{') ||
        line.endsWith('}') ||
        line.endsWith('},') ||
        line.endsWith(');') ||
        line.endsWith('),')) {
      return true;
    }

    // Lines starting with common Dart keywords followed by code patterns.
    if (_startsWithCodeKeyword(line) && _opensOrParsesAsStatement(line)) return true;

    // Lines that are just a closing brace.
    if (line == '}' || line == '};' || line == '},') return true;

    // Lines that look like function/method calls: word( or word.word(
    if (_looksLikeFunctionCall(line)) return true;

    // Lines that look like annotations: @override, @required, etc.
    if (_annotationPattern.hasMatch(line)) return true;

    // Lines that look like assignments: word = ...
    if (_assignmentPattern.hasMatch(line) && _opensOrParsesAsStatement(line)) return true;

    // Lines that look like return statements
    if (_returnPattern.hasMatch(line)) return true;

    // Lines that are just a single statement with a dot chain
    if (_cascadePattern.hasMatch(line)) return true;

    return false;
  }

  /// Returns true if the line looks like natural language / prose.
  bool _isProse(String line) {
    final lower = line.toLowerCase();
    if (lower.startsWith('todo') ||
        lower.startsWith('fixme') ||
        lower.startsWith('hack') ||
        lower.startsWith('note:') ||
        lower.startsWith('note ') ||
        lower.startsWith('see ') ||
        lower.startsWith('ref:') ||
        lower.startsWith('bug:') ||
        lower.startsWith('warning:')) {
      return true;
    }

    // Lines that are just prose (no code-like characters).
    // Prose tends to have spaces and no special code characters.
    if (!line.contains(';') &&
        !line.contains('{') &&
        !line.contains('}') &&
        !line.contains('(') &&
        !line.contains(')') &&
        !line.contains('=') &&
        !line.startsWith('@') &&
        !line.startsWith('import ') &&
        !line.startsWith('export ')) {
      // If it's mostly words with spaces and no code markers, it's prose.
      final words = line.split(_whitespacePattern);
      if (words.length >= 3) return true;
    }

    return false;
  }

  /// Checks if the line starts with a common Dart code keyword.
  bool _startsWithCodeKeyword(String line) {
    const keywords = [
      'final ',
      'var ',
      'const ',
      'class ',
      'abstract ',
      'enum ',
      'void ',
      'int ',
      'double ',
      'String ',
      'bool ',
      'List<',
      'Map<',
      'Set<',
      'Future<',
      'Stream<',
      'if (',
      'if(',
      'else {',
      'else{',
      'for (',
      'for(',
      'while (',
      'while(',
      'switch (',
      'switch(',
      'try {',
      'try{',
      'catch (',
      'catch(',
      'throw ',
      'import ',
      'export ',
      'part ',
      'late ',
      'static ',
      'override',
      'Widget ',
      'State<',
      'BuildContext ',
    ];

    for (final keyword in keywords) {
      if (line.startsWith(keyword)) return true;
    }
    return false;
  }

  /// Checks if a line looks like a function or method call.
  bool _looksLikeFunctionCall(String line) {
    return _functionCallPattern.hasMatch(line) && _opensOrParsesAsStatement(line);
  }

  /// Confirms a keyword, assignment or call candidate is really code.
  ///
  /// A line that opens more parentheses than it closes starts a multi-line
  /// statement. A complete line must parse as a Dart statement, so descriptive
  /// text such as `Glucose(GOD-POD Method)` or `Reorder = UI flicker (stale
  /// parent)` is not treated as code.
  static bool _opensOrParsesAsStatement(String line) {
    if (_countOf(line, '(') > _countOf(line, ')')) return true;
    return _parsesAsStatement(line);
  }

  static int _countOf(String text, String char) => char.allMatches(text).length;

  static bool _parsesAsStatement(String line) {
    final statement = line.endsWith(';') ? line : '$line;';
    final result = parseString(
      content: 'void _commentProbe() {\n$statement\n}\n',
      throwIfDiagnostics: false,
    );
    return result.errors.isEmpty;
  }
}
