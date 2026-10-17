import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:quokkadoku/puzzle.dart';

void main() {
  test('generated puzzles are unique and valid', () {
    for (final n in [7, 8, 10]) {
      final p = Puzzle.generate(n, Random(1));
      expect(Puzzle.countSolutions(n, p.region), 1);
      expect(p.solution.toSet().length, n);
      for (var r = 1; r < n; r++) {
        expect((p.solution[r] - p.solution[r - 1]).abs() > 1, true);
      }
    }
  });
}
