import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/file_system/file_system.dart';

bool isPubspecAnchorUnit(Folder root, RuleContext context) {
  final currentPath = context.definingUnit.file.path;
  final pubspecText = readFileText(root.getFile('pubspec.yaml')) ?? '';
  final packageName = RegExp(
    r'^name:\s*([A-Za-z0-9_]+)\s*$',
    multiLine: true,
  ).firstMatch(pubspecText)?.group(1);

  if (packageName != null) {
    return currentPath == root.getFile('lib/$packageName.dart').path;
  }

  return currentPath == root.getFile('lib/main.dart').path;
}

String? packageNameFromPubspec(Folder root) {
  final text = readFileText(root.getFile('pubspec.yaml')) ?? '';
  return RegExp(r'^name:\s*([A-Za-z0-9_]+)\s*$', multiLine: true).firstMatch(text)?.group(1);
}

String unquoteYamlScalar(String value) {
  if (value.length < 2) return value;
  final first = value[0];
  final last = value[value.length - 1];
  if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
    return value.substring(1, value.length - 1);
  }
  return value;
}

const generatedDartFileSuffixes = [
  '.config.dart',
  '.freezed.dart',
  '.g.dart',
  '.gen.dart',
  '.gr.dart',
];

String? readFileText(File file) {
  if (!file.exists) return null;
  try {
    return file.readAsStringSync();
  } on FileSystemException {
    return null;
  }
}

Iterable<({String line, int indent})> yamlSectionLines(String text, String section) sync* {
  var inSection = false;
  var sectionIndent = 0;

  for (final line in text.split('\n')) {
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
    final indent = line.length - line.trimLeft().length;
    final sectionMatch = RegExp('^\\s*${RegExp.escape(section)}\\s*:(.*)\$').firstMatch(line);
    if (sectionMatch != null) {
      sectionIndent = indent;
      inSection = (sectionMatch.group(1) ?? '').trim().isEmpty;
      continue;
    }
    if (!inSection) continue;
    if (indent <= sectionIndent) {
      inSection = false;
      continue;
    }
    yield (line: line, indent: indent - sectionIndent);
  }
}
