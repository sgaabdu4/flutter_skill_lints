import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_skill_lints/src/additional_lints/edge_insets_replacement.dart';
import 'package:test/test.dart';

void main() {
  group('edgeInsetsReplacement', () {
    test('uses a symmetric constructor for matching opposite sides', () {
      expect(_replacement('EdgeInsets.fromLTRB(0, 8, 0, 8)'), 'EdgeInsets.symmetric(vertical: 8)');
    });

    test('uses only for non-zero sides without a simpler shape', () {
      expect(_replacement('EdgeInsets.fromLTRB(1, 2, 0, 0)'), 'EdgeInsets.only(left: 1, top: 2)');
    });

    test('fills omitted only values before checking symmetry', () {
      expect(
        _replacement('EdgeInsets.only(left: 8, right: 8)'),
        'EdgeInsets.symmetric(horizontal: 8)',
      );
    });

    test('uses all and zero for equivalent constructors', () {
      expect(_replacement('EdgeInsets.symmetric(horizontal: 8, vertical: 8)'), 'EdgeInsets.all(8)');
      expect(_replacement('EdgeInsets.all(0.0)'), 'EdgeInsets.zero');
    });

    test('does not rewrite a constructor without a safe simplification', () {
      expect(_replacement('EdgeInsets.fromLTRB(left, top, right, bottom)'), isNull);
      expect(_replacement('EdgeInsets.symmetric(horizontal: 8, vertical: 4)'), isNull);
    });
  });
}

String? _replacement(String source) {
  final visitor = _ArgumentListVisitor();
  parseString(content: 'void main() { $source; }').unit.accept(visitor);
  final argumentList = visitor.argumentList;
  expect(argumentList, isNotNull);

  final constructor = source.substring(source.indexOf('.') + 1, source.indexOf('('));
  return edgeInsetsReplacement(constructor, argumentList!);
}

class _ArgumentListVisitor extends RecursiveAstVisitor<void> {
  ArgumentList? argumentList;

  @override
  void visitArgumentList(ArgumentList node) {
    argumentList ??= node;
    super.visitArgumentList(node);
  }
}
