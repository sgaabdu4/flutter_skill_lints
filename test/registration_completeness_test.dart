import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('every case file runs from exactly one rule_cases aggregate', () {
    final caseFiles = _testFiles().where((file) => file.path.endsWith('_cases.dart')).toList();
    final aggregates = _testFiles()
        .where((file) => RegExp(r'rule_cases_\d+_test\.dart$').hasMatch(file.path))
        .map((file) => file.readAsStringSync())
        .toList();

    final problems = <String>[];
    for (final caseFile in caseFiles) {
      final name = caseFile.uri.pathSegments.last;
      var runs = 0;
      for (final text in aggregates) {
        final alias = RegExp("import '$name' as (\\w+);").firstMatch(text)?.group(1);
        if (alias != null && text.contains('$alias.main();')) runs++;
      }
      if (runs != 1) problems.add('$name runs $runs times');
    }

    expect(caseFiles, isNotEmpty);
    expect(problems, isEmpty);
  });

  test('every test class takes the cases of its nearest base class with cases', () {
    final libraries = <String, List<_TestClass>>{};
    for (final file in _testFiles()) {
      final text = file.readAsStringSync();
      final root = RegExp("part of '([^']+)';").firstMatch(text)?.group(1);
      final library = root == null
          ? file.path
          : File(file.parent.uri.resolve(root).toFilePath()).absolute.path;
      libraries.putIfAbsent(File(library).absolute.path, () => []).addAll(_classes(text));
    }

    final problems = <String>[];
    for (final classes in libraries.values) {
      final byName = {for (final c in classes) c.name: c};
      for (final c in classes.where((c) => c.parent != null)) {
        final expected = _nearestBaseWithCases(byName, c.base);
        final want = expected == null ? 'const {}' : '$expected._allCases';
        if (c.parent != want) problems.add('${c.name} uses ${c.parent}, expected $want');
      }
    }

    expect(problems, isEmpty);
  });
}

String? _nearestBaseWithCases(Map<String, _TestClass> byName, String base) {
  var current = byName[base];
  while (current != null) {
    if (current.parent != null) return current.name;
    current = byName[current.base];
  }
  return null;
}

Iterable<File> _testFiles() =>
    Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

final _classPattern = RegExp(
  r'class (_\w+) extends (\w+)(?:<[^>]*>)? \{\s*static Map<[^{]*?get _allCases =>\s*'
  r'caseSet<\w+>\(\s*parent: ([^,]+),',
  dotAll: true,
);

final _plainClassPattern = RegExp(r'class (_\w+) extends (\w+)(?:<[^>]*>)? \{');

List<_TestClass> _classes(String text) {
  final withCases = {
    for (final match in _classPattern.allMatches(text))
      match.group(1)!: _TestClass(match.group(1)!, match.group(2)!, match.group(3)!.trim()),
  };
  return [
    for (final match in _plainClassPattern.allMatches(text))
      withCases[match.group(1)!] ?? _TestClass(match.group(1)!, match.group(2)!, null),
  ];
}

final class _TestClass {
  const _TestClass(this.name, this.base, this.parent);

  final String name;
  final String base;
  final String? parent;
}
