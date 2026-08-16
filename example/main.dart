import 'package:flutter_skill_lints/flutter_skill_lints.dart';

void main() {
  if (plugin.name.isEmpty) {
    throw StateError('The plugin must have a name.');
  }
}
