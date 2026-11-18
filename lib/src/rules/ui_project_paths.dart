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
  final cache = _caches[file.provider] ??= _GatesCache();
  final gates = cache.gatesFileFor(file.parent);
  if (gates == null) {
    return UiProjectPaths(path: packagePath, packagePath: packagePath, library: null);
  }
  final relative = file.provider.pathContext
      .relative(file.path, from: gates.parent.path)
      .replaceAll('\\', '/');
  return UiProjectPaths(path: relative, packagePath: packagePath, library: cache.libraryOf(gates));
}

final _caches = Expando<_GatesCache>('flutter_skill_lints_gates_cache');
const _walkTtl = Duration(seconds: 10);

/// Per analysis process: the gates file each folder resolves to (a folder with none included, rechecked after [_walkTtl] so a new file is found), and each gates file parsed once for its modification stamp and size.
final class _GatesCache {
  final _folders = <String, ({String? gates, Duration at})>{};
  final _parsed = <String, ({int stamp, int length, List<RegExp>? library})>{};
  final _clock = Stopwatch()..start();

  File? gatesFileFor(Folder start) {
    final cached = _folders[start.path];
    if (cached != null && _clock.elapsed - cached.at < _walkTtl) {
      final path = cached.gates;
      if (path == null) return null;
      final gates = start.provider.getFile(path);
      if (gates.exists) return gates;
    }
    return _walk(start);
  }

  File? _walk(Folder start) {
    final visited = <String>[];
    File? found;
    Folder folder = start;
    while (true) {
      visited.add(folder.path);
      final gates = folder.getFile(_gatesFileName);
      if (gates.exists) {
        found = gates;
        break;
      }
      if (folder.isRoot) break;
      folder = folder.parent;
    }
    final at = _clock.elapsed;
    for (final path in visited) {
      _folders[path] = (gates: found?.path, at: at);
    }
    return found;
  }

  List<RegExp>? libraryOf(File gates) {
    try {
      final stamp = gates.modificationStamp;
      final length = gates.lengthSync;
      final cached = _parsed[gates.path];
      if (cached != null && cached.stamp == stamp && cached.length == length) {
        return cached.library;
      }
      final library = _parseLibrary(gates.readAsStringSync());
      _parsed[gates.path] = (stamp: stamp, length: length, library: library);
      return library;
    } on FileSystemException {
      _parsed.remove(gates.path);
      return null;
    }
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
