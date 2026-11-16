import 'package:flutter_skill_lints/src/additional_lints/text_distance.dart';
import 'package:test/test.dart';

void main() {
  group('computeEditDistance', () {
    test('is zero for equal strings', () {
      expect(computeEditDistance('notifier', 'notifier'), 0);
    });

    test('is the length of the other string when one is empty', () {
      expect(computeEditDistance('', 'abc'), 3);
      expect(computeEditDistance('abc', ''), 3);
    });

    test('counts one edit for a substitution, an insertion and a deletion', () {
      expect(computeEditDistance('notifier', 'notifiar'), 1);
      expect(computeEditDistance('notifer', 'notifier'), 1);
      expect(computeEditDistance('notifierr', 'notifier'), 1);
    });

    test('finds the cheapest mix of edits', () {
      expect(computeEditDistance('kitten', 'sitting'), 3);
      expect(computeEditDistance('rnotifer', 'notifier'), 2);
    });
  });
}
