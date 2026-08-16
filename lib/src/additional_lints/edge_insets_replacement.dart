import 'package:analyzer/dart/ast/ast.dart';

String? edgeInsetsReplacement(String? constructorName, ArgumentList argumentList) {
  return switch (constructorName) {
    'fromLTRB' => _fromLTRB(argumentList),
    'only' => _only(argumentList),
    'symmetric' => _symmetric(argumentList),
    'all' => _all(argumentList),
    _ => null,
  };
}

String? _fromLTRB(ArgumentList argumentList) {
  final args = argumentList.arguments;
  if (args.length != 4) return null;

  final l = args[0].toSource();
  final t = args[1].toSource();
  final r = args[2].toSource();
  final b = args[3].toSource();

  return _fourSideReplacement(left: l, top: t, right: r, bottom: b, useOnly: true);
}

String? _only(ArgumentList argumentList) {
  final values = _namedValues(argumentList, const {'left', 'top', 'right', 'bottom'});
  final l = values['left'] ?? '0';
  final t = values['top'] ?? '0';
  final r = values['right'] ?? '0';
  final b = values['bottom'] ?? '0';

  return _fourSideReplacement(left: l, top: t, right: r, bottom: b, useOnly: false);
}

String? _fourSideReplacement({
  required String left,
  required String top,
  required String right,
  required String bottom,
  required bool useOnly,
}) {
  if (_isZero(left) && _isZero(top) && _isZero(right) && _isZero(bottom)) {
    return 'EdgeInsets.zero';
  }

  if (left == top && top == right && right == bottom) {
    return 'EdgeInsets.all($left)';
  }

  if (left == right && top == bottom) {
    return _symmetricReplacement(left, top);
  }

  if (useOnly) {
    final values = <String, String>{'left': left, 'top': top, 'right': right, 'bottom': bottom};
    final nonZeroValues = values.entries.where((entry) => !_isZero(entry.value));
    if (nonZeroValues.length < 4) {
      return 'EdgeInsets.only(${nonZeroValues.map((entry) => '${entry.key}: ${entry.value}').join(', ')})';
    }
  }

  return null;
}

String? _symmetric(ArgumentList argumentList) {
  final values = _namedValues(argumentList, const {'horizontal', 'vertical'});
  final horizontal = values['horizontal'] ?? '0';
  final vertical = values['vertical'] ?? '0';

  if (_isZero(horizontal) && _isZero(vertical)) {
    return 'EdgeInsets.zero';
  }

  if (horizontal == vertical) {
    return 'EdgeInsets.all($horizontal)';
  }

  return null;
}

String? _all(ArgumentList argumentList) {
  final args = argumentList.arguments;
  if (args.isEmpty) return null;

  return _isZero(args.first.toSource()) ? 'EdgeInsets.zero' : null;
}

String? _symmetricReplacement(String horizontal, String vertical) {
  final hasHorizontal = !_isZero(horizontal);
  final hasVertical = !_isZero(vertical);
  if (hasHorizontal && hasVertical) {
    return 'EdgeInsets.symmetric(horizontal: $horizontal, vertical: $vertical)';
  }
  if (hasHorizontal) {
    return 'EdgeInsets.symmetric(horizontal: $horizontal)';
  }
  if (hasVertical) {
    return 'EdgeInsets.symmetric(vertical: $vertical)';
  }
  return null;
}

Map<String, String> _namedValues(ArgumentList argumentList, Set<String> names) {
  final values = <String, String>{};
  for (final argument in argumentList.arguments.whereType<NamedArgument>()) {
    if (names.contains(argument.name.lexeme)) {
      values[argument.name.lexeme] = argument.argumentExpression.toSource();
    }
  }
  return values;
}

bool _isZero(String source) => source == '0' || source == '0.0';
