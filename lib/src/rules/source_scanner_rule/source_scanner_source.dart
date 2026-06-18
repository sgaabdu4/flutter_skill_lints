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
    final codeBuffer = StringBuffer();
    final maskedBuffer = StringBuffer();
    var inLineComment = false;
    var inBlockComment = false;
    var quote = '';
    var inTripleString = false;
    var inRawString = false;
    var escaped = false;

    void writeBoth(String value) {
      codeBuffer.write(value);
      maskedBuffer.write(value);
    }

    void writeSpaces(int count) {
      codeBuffer.write(' ' * count);
      maskedBuffer.write(' ' * count);
    }

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      final next = i + 1 < text.length ? text[i + 1] : '';

      if (char == '\n') {
        writeBoth(char);
        inLineComment = false;
        if (quote.isNotEmpty && !inTripleString) {
          quote = '';
          escaped = false;
        }
        continue;
      }

      if (quote.isNotEmpty) {
        codeBuffer.write(inTripleString ? ' ' : char);
        maskedBuffer.write(' ');
        if (inTripleString) {
          if (_startsTripleQuote(text, i, quote)) {
            writeSpaces(2);
            quote = '';
            inTripleString = false;
            inRawString = false;
            i += 2;
          }
          continue;
        }
        if (escaped) {
          escaped = false;
        } else if (!inRawString && char == r'\') {
          escaped = true;
        } else if (char == quote) {
          quote = '';
          inRawString = false;
        }
        continue;
      }

      if (inLineComment) {
        writeSpaces(1);
        continue;
      }

      if (inBlockComment) {
        if (char == '*' && next == '/') {
          writeSpaces(2);
          inBlockComment = false;
          i++;
          continue;
        }
        writeSpaces(1);
        continue;
      }

      if (char == '/' && next == '/') {
        writeSpaces(2);
        inLineComment = true;
        i++;
        continue;
      }
      if (char == '/' && next == '*') {
        writeSpaces(2);
        inBlockComment = true;
        i++;
        continue;
      }

      final rawPrefix =
          (char == 'r' || char == 'R') && i + 1 < text.length && _isQuote(text[i + 1]);
      if (rawPrefix || _isQuote(char)) {
        final quoteIndex = rawPrefix ? i + 1 : i;
        quote = text[quoteIndex];
        inRawString = rawPrefix;
        inTripleString = _startsTripleQuote(text, quoteIndex, quote);
        final prefixLength = rawPrefix ? 1 : 0;
        final quoteLength = inTripleString ? 3 : 1;
        if (inTripleString) {
          writeSpaces(prefixLength + quoteLength);
        } else {
          codeBuffer.write(text.substring(i, quoteIndex + quoteLength));
          maskedBuffer.write(' ' * (prefixLength + quoteLength));
        }
        i = quoteIndex + quoteLength - 1;
        continue;
      }

      writeBoth(char);
    }

    return _SourceScan(codeBuffer.toString(), maskedBuffer.toString());
  }

  bool _isQuote(String char) => char == '\'' || char == '"';

  bool _startsTripleQuote(String text, int index, String quote) =>
      index + 2 < text.length &&
      text[index] == quote &&
      text[index + 1] == quote &&
      text[index + 2] == quote;
}

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
  var i = 0;
  while (i < text.length) {
    final structuralRemainder = structuralText.substring(i);
    final remainder = text.substring(i);
    final match = call.firstMatch(structuralRemainder);
    if (match == null) {
      buffer.write(remainder);
      break;
    }
    buffer.write(remainder.substring(0, match.end));
    var depth = 1;
    var j = i + match.end;
    while (j < text.length && depth > 0) {
      final structuralChar = structuralText[j];
      final ch = text[j];
      if (structuralChar == '(') {
        depth++;
      } else if (structuralChar == ')') {
        depth--;
      }
      if (depth == 0) {
        buffer.write(ch);
      } else if (ch == '\n') {
        buffer.write('\n');
      } else {
        buffer.write(' ');
      }
      j++;
    }
    i = j;
  }
  return buffer.toString();
}
