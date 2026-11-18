import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';

const _gatesFileName = 'hard-eng.gates.json';
const _defaultLibraryFolder = 'lib/core/widgets/';

const _themeWords = {
  'theme',
  'token',
  'color',
  'colour',
  'palette',
  'themes',
  'tokens',
  'colors',
  'colours',
  'palettes',
};
final _nameWords = RegExp(r'[A-Z]+(?![a-z])|[A-Z]?[a-z0-9]+');

/// Hard Eng's `is_theme_path`: both tools answer the Flutter skill's theme path cases the same way.
bool isThemePath(String name) {
  final parts = name.split('/');
  final fileName = parts.last;
  if (fileName.startsWith('tailwind.config.')) return true;
  if (parts.take(parts.length - 1).any((part) => _themeWords.contains(part.toLowerCase()))) {
    return true;
  }
  final dot = fileName.lastIndexOf('.');
  final stem = dot > 0 && dot < fileName.length - 1 ? fileName.substring(0, dot) : fileName;
  return stem.split('+').any((part) {
    final words = _nameWords.allMatches(part);
    return words.isNotEmpty && _themeWords.contains(words.last.group(0)!.toLowerCase());
  });
}

/// A file's place in the project: its path from the folder of the nearest `hard-eng.gates.json`, and the library globs that file lists.
final class UiProjectPaths {
  const UiProjectPaths({required this.path, required this.packagePath, required this.library});

  final String path;
  final String packagePath;
  final List<RegExp>? library;

  bool get isInLibrary {
    final globs = library;
    if (globs == null) return packagePath.startsWith(_defaultLibraryFolder);
    return globs.any((glob) => glob.hasMatch(path));
  }
}

UiProjectPaths resolveUiProjectPaths(File file, String packagePath) {
  Folder folder = file.parent;
  while (true) {
    final gates = folder.getFile(_gatesFileName);
    if (gates.exists) {
      final relative = file.provider.pathContext
          .relative(file.path, from: folder.path)
          .replaceAll('\\', '/');
      return UiProjectPaths(
        path: relative,
        packagePath: packagePath,
        library: _libraryGlobs(gates),
      );
    }
    if (folder.isRoot) break;
    folder = folder.parent;
  }
  return UiProjectPaths(path: packagePath, packagePath: packagePath, library: null);
}

List<RegExp>? _libraryGlobs(File gates) {
  try {
    return _parseLibrary(gates.readAsStringSync());
  } on FileSystemException {
    return null;
  }
}

List<RegExp>? _parseLibrary(String text) {
  try {
    final decoded = jsonDecode(text);
    final shipping = decoded is Map ? decoded['shipping'] : null;
    final entries = shipping is Map ? shipping['ui_library'] : null;
    if (entries is! List || entries.isEmpty) return null;
    if (entries.any((entry) => entry is! String || entry.trim().isEmpty)) return null;
    return [for (final entry in entries.cast<String>()) _fnmatch(entry)];
  } on FormatException {
    return null;
  }
}

/// Python `fnmatch` rules, which Hard Eng uses on these entries: `*` crosses `/`, and `[...]` and `[!...]` are sets.
RegExp _fnmatch(String pattern) {
  final out = StringBuffer('^');
  var i = 0;
  while (i < pattern.length) {
    final char = pattern[i++];
    if (char == '*') {
      out.write('.*');
    } else if (char == '?') {
      out.write('.');
    } else if (char == '[') {
      final end = _setEnd(pattern, i);
      if (end == null) {
        out.write(r'\[');
      } else {
        out.write(_charSet(pattern.substring(i, end)));
        i = end + 1;
      }
    } else {
      out.write(RegExp.escape(char));
    }
  }
  return RegExp('$out\$', dotAll: true);
}

int? _setEnd(String pattern, int start) {
  var end = start;
  if (end < pattern.length && pattern[end] == '!') end++;
  if (end < pattern.length && pattern[end] == ']') end++;
  final close = pattern.indexOf(']', end);
  return close < 0 ? null : close;
}

String _charSet(String body) {
  final negate = body.startsWith('!');
  final members = (negate ? body.substring(1) : body)
      .replaceAll(r'\', r'\\')
      .replaceAll('[', r'\[')
      .replaceAll(']', r'\]');
  if (negate) return '[^$members]';
  return members.startsWith('^') ? '[\\$members]' : '[$members]';
}
