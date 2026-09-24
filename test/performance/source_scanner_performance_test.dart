import 'dart:io';

import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';
import 'package:test/test.dart';

const _defaultBudgetMicroseconds = 2_000_000;
const _lineCount = 10_000;

void main() {
  test('debug call masking preserves nested calls, following code, and offsets', () {
    const source =
        'debugPrint(format(print(value))); keep();\n'
        'print(\n value\n); tail();\n'
        'final message = "print(value)";\n'
        'myprint(value);';
    final scanned = SourceScannerSource(source);
    final expected = [
      'debugPrint(${" " * 'format(print(value))'.length}); keep();',
      'print(',
      ' ${" " * 'value'.length}',
      '); tail();',
      'final message = "print(value)";',
      'myprint(value);',
    ];
    expect(scanned.code, expected);
    expect(scanned.masked.last, 'myprint(value);');
    expect(scanned.masked.join('\n'), hasLength(source.length));
    expect(scanned.lineOffsets, [0, 42, 49, 56, 67, 99]);
  });

  test('masks $_lineCount mixed source lines within the scanner budget', () {
    final source = List.generate(_lineCount, (index) {
      return switch (index % 4) {
        0 => 'final value$index = "literal // $index";',
        1 => '// comment $index with braces { } and a quoted "value"',
        2 => 'debugPrint("value $index");',
        _ => 'if (value$index.isNotEmpty) save(value$index);',
      };
    }).join('\n');
    final budgetMicroseconds =
        int.tryParse(Platform.environment['SOURCE_SCANNER_BUDGET_MICROSECONDS'] ?? '') ??
        _defaultBudgetMicroseconds;

    final stopwatch = Stopwatch()..start();
    final scanned = SourceScannerSource(source);
    stopwatch.stop();

    expect(scanned.length, _lineCount);
    expect(scanned.original, hasLength(_lineCount));
    expect(scanned.masked, hasLength(_lineCount));
    expect(
      stopwatch.elapsedMicroseconds,
      lessThan(budgetMicroseconds),
      reason:
          'SourceScannerSource must process $_lineCount representative lines '
          'within $budgetMicroseconds microseconds.',
    );
  });
}
