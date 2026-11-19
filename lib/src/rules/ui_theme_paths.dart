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
