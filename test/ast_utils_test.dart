import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
import 'package:test/test.dart';

CompilationUnit _parse(String source) => parseString(content: source).unit;

void main() {
  group('constructorsWithLogic', () {
    test('yields constructors with initializers or statements only', () {
      final unit = _parse('''
class A {
  A(this.x);
  A.plain();
  A.withBody() { init(); }
  A.withInitializer() : x = 1;
  A.withSuper() : super();
  A.emptyBody() {}
  A.arrow() : this(1);
  final int x = 0;
  void init() {}
}
''');
      final body = (unit.declarations.single as ClassDeclaration).body as BlockClassBody;

      final names = constructorsWithLogic(body).map((c) => c.name?.lexeme ?? '').toList();

      expect(names, ['withBody', 'withInitializer', 'arrow']);
    });
  });

  group('firstTargetAccess', () {
    String? firstAccess(String statement, {Set<String> targets = const {'context', 'ref'}}) {
      final unit = _parse('void f() {\n  $statement\n}\n');
      final body = (unit.declarations.single as FunctionDeclaration).functionExpression.body;
      return firstTargetAccess(body, targets, includeBlocks: true)?.toSource();
    }

    test('finds a context read through this', () {
      expect(firstAccess('this.context.mounted;'), 'this.context.mounted');
    });

    test('finds a member of this named like a target', () {
      expect(firstAccess('final c = this.context;'), 'this.context');
    });

    test('finds a null-aware property read on a target', () {
      expect(firstAccess('ref?.value;'), 'ref?.value');
    });

    test('skips the ref mounted check itself', () {
      expect(firstAccess('ref?.mounted;'), isNull);
    });

    test('ignores properties of other receivers', () {
      expect(firstAccess('other?.value;'), isNull);
      expect(firstAccess('this.value;'), isNull);
    });
  });
}
