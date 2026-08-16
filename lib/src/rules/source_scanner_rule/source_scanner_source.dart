part of '../source_scanner_rule.dart';

final class SourceScannerSource {
  SourceScannerSource(String text) {
    original.addAll(text.split('\n'));
    lineOffsets.addAll(_lineOffsets(text));
    final scan = _scanText(text);
    code.addAll(_blankDebugCalls(scan.code, structure: scan.masked).split('\n'));
    masked.addAll(_blankDebugCalls(scan.masked).split('\n'));
  }

  final original = <String>[];
  final code = <String>[];
  final masked = <String>[];
  final lineOffsets = <int>[];

  int get length => original.length;

  List<int> _lineOffsets(String text) {
    final result = <int>[0];
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 10) result.add(i + 1);
    }
    return result;
  }

  _SourceScan _scanText(String text) {
    final state = _ScanTextState();
    var index = 0;
    while (index < text.length) {
      index = state.consume(text, index);
    }
    return state.result;
  }
}

final class _ScanTextState {
  final StringBuffer codeBuffer = StringBuffer();
  final StringBuffer maskedBuffer = StringBuffer();
  bool inLineComment = false;
  bool inBlockComment = false;
  String quote = '';
  bool inTripleString = false;
  bool inRawString = false;
  bool escaped = false;

  _SourceScan get result => _SourceScan(codeBuffer.toString(), maskedBuffer.toString());

  int consume(String text, int index) {
    final char = text[index];
    final next = index + 1 < text.length ? text[index + 1] : '';

    if (char == '\n') return _consumeNewline(index);
    if (quote.isNotEmpty) return _consumeQuoted(text, index);
    if (inLineComment) return _consumeLineComment(index);
    if (inBlockComment) return _consumeBlockComment(char, next, index);
    if (char == '/' && next == '/') return _startLineComment(index);
    if (char == '/' && next == '*') return _startBlockComment(index);
    if (_isStringStart(text, index)) return _startString(text, index);

    _writeBoth(char);
    return index + 1;
  }

  int _consumeNewline(int index) {
    _writeBoth('\n');
    inLineComment = false;
    if (quote.isNotEmpty && !inTripleString) {
      quote = '';
      escaped = false;
    }
    return index + 1;
  }

  int _consumeQuoted(String text, int index) {
    if (inTripleString) return _consumeTripleString(text, index);
    return _consumeStringCharacter(text[index], index);
  }

  int _consumeTripleString(String text, int index) {
    codeBuffer.write(' ');
    maskedBuffer.write(' ');
    if (!_startsTripleQuote(text, index, quote)) return index + 1;

    _writeSpaces(2);
    quote = '';
    inTripleString = false;
    inRawString = false;
    return index + 3;
  }

  int _consumeStringCharacter(String char, int index) {
    codeBuffer.write(char);
    maskedBuffer.write(' ');
    if (escaped) {
      escaped = false;
    } else if (!inRawString && char == r'\') {
      escaped = true;
    } else if (char == quote) {
      quote = '';
      inRawString = false;
    }
    return index + 1;
  }

  int _consumeLineComment(int index) {
    _writeSpaces(1);
    return index + 1;
  }

  int _consumeBlockComment(String char, String next, int index) {
    if (char == '*' && next == '/') {
      _writeSpaces(2);
      inBlockComment = false;
      return index + 2;
    }
    _writeSpaces(1);
    return index + 1;
  }

  int _startLineComment(int index) {
    _writeSpaces(2);
    inLineComment = true;
    return index + 2;
  }

  int _startBlockComment(int index) {
    _writeSpaces(2);
    inBlockComment = true;
    return index + 2;
  }

  bool _isStringStart(String text, int index) {
    final char = text[index];
    final rawPrefix =
        (char == 'r' || char == 'R') && index + 1 < text.length && _isQuote(text[index + 1]);
    return rawPrefix || _isQuote(char);
  }

  int _startString(String text, int index) {
    final rawPrefix =
        (text[index] == 'r' || text[index] == 'R') &&
        index + 1 < text.length &&
        _isQuote(text[index + 1]);
    final quoteIndex = rawPrefix ? index + 1 : index;
    quote = text[quoteIndex];
    inRawString = rawPrefix;
    inTripleString = _startsTripleQuote(text, quoteIndex, quote);
    final prefixLength = rawPrefix ? 1 : 0;
    final quoteLength = inTripleString ? 3 : 1;
    if (inTripleString) {
      _writeSpaces(prefixLength + quoteLength);
    } else {
      codeBuffer.write(text.substring(index, quoteIndex + quoteLength));
      maskedBuffer.write(' ' * (prefixLength + quoteLength));
    }
    return quoteIndex + quoteLength;
  }

  void _writeBoth(String value) {
    codeBuffer.write(value);
    maskedBuffer.write(value);
  }

  void _writeSpaces(int count) {
    codeBuffer.write(' ' * count);
    maskedBuffer.write(' ' * count);
  }
}

bool _isQuote(String char) => char == '\'' || char == '"';

bool _startsTripleQuote(String text, int index, String quote) =>
    index + 2 < text.length &&
    text[index] == quote &&
    text[index + 1] == quote &&
    text[index + 2] == quote;

final class _SourceScan {
  const _SourceScan(this.code, this.masked);

  final String code;
  final String masked;
}

final class ScannerClassSpan {
  const ScannerClassSpan({
    required this.name,
    required this.start,
    required this.end,
    required this.isNotifier,
  });

  static const none = ScannerClassSpan(name: '', start: -1, end: -1, isNotifier: false);

  final String name;
  final int start;
  final int end;
  final bool isNotifier;

  bool contains(int line) => line >= start && line <= end;
}

final class ScannerMethodSpan {
  const ScannerMethodSpan({required this.name, required this.start, required this.end});

  final String name;
  final int start;
  final int end;
}

final class _ScannerMixinSpan {
  const _ScannerMixinSpan({required this.start, required this.end, required this.signature});

  final int start;
  final int end;
  final String signature;
}

/// Replaces every char inside a `debugPrint(...)` or `print(...)` call body
/// with a space. Diagnostic offsets stay aligned because chars are not deleted.
String _blankDebugCalls(String text, {String? structure}) {
  final structuralText = structure ?? text;
  final buffer = StringBuffer();
  final call = RegExp(r'\b(?:debugPrint|print)\s*\(');
  var index = 0;
  while (index < text.length) {
    final match = call.firstMatch(structuralText.substring(index));
    if (match == null) {
      buffer.write(text.substring(index));
      break;
    }
    final matchEnd = index + match.end;
    buffer.write(text.substring(index, matchEnd));
    index = _blankDebugCallBody(text, structuralText, matchEnd, buffer);
  }
  return buffer.toString();
}

int _blankDebugCallBody(String text, String structure, int index, StringBuffer buffer) {
  var depth = 1;
  while (index < text.length && depth > 0) {
    final structuralChar = structure[index];
    final char = text[index];
    if (structuralChar == '(') depth++;
    if (structuralChar == ')') depth--;
    if (depth == 0) {
      buffer.write(char);
    } else if (char == '\n') {
      buffer.write('\n');
    } else {
      buffer.write(' ');
    }
    index++;
  }
  return index;
}
