bool isValidFirebaseName(String name) {
  if (name.isEmpty || name.length > 40) return false;
  final normalized = name.toLowerCase();
  if (normalized.startsWith('firebase_') ||
      normalized.startsWith('google_') ||
      normalized.startsWith('ga_')) {
    return false;
  }
  return RegExp(r'^[A-Za-z][A-Za-z0-9_]*$').hasMatch(name);
}
